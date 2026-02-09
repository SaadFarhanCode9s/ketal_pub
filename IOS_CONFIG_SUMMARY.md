# iOS App Configuration Summary

## Configuration Comparison

### Current iOS App Settings (AppSettings.swift)

| Setting | iOS App Value | vars.yml Value | Status |
|---------|---------------|----------------|--------|
| **Account Provider** | `ketals.online` | `ketals.online` | ✅ Match |
| **Redirect URI** | `ketal://oidc` | `ketal://oidc` | ✅ Match |
| **Client ID** | *Discovered via well-known* | `C3D9BWGMDZ1J79ZNVRP846JZ7J` | ✅ Correct |
| **Static Registrations** | `[:]` (empty) | N/A | ✅ Correct |
| **OIDC Discovery** | ✅ Enabled | ✅ Configured | ✅ Match |

### Analysis

**✅ NO CHANGES REQUIRED** - The iOS app configuration is already correctly aligned with the server configuration.

#### Why No Changes Are Needed:

1. **Dynamic Discovery**: The iOS app uses `.well-known/matrix/client` discovery to automatically retrieve the client ID, issuer, and other OIDC parameters. This is the recommended approach.

2. **Empty Static Registrations**: The `oidcStaticRegistrations` is intentionally empty (`[:]`), which means the app will use the client ID from the well-known file at runtime. This is perfect for your setup.

3. **Redirect URI Matches**: The iOS app's redirect URI (`ketal://oidc`) exactly matches what's configured in vars.yml.

4. **Homeserver Matches**: The default account provider (`ketals.online`) matches your base domain.

### Authentication Flow

Here's how the iOS app will authenticate:

1. **User enters homeserver**: `ketals.online`
2. **App fetches well-known**: `https://ketals.online/.well-known/matrix/client`
3. **App reads OIDC config from well-known**:
   - `issuer`: `https://matrix.ketals.online/auth/`
   - `client_id`: `C3D9BWGMDZ1J79ZNVRP846JZ7J`
4. **App constructs OIDC configuration** with client_id from well-known
5. **App redirects to Keycloak**: User logs in at `https://matrix.ketals.online/auth/realms/ketal`
6. **Keycloak redirects back**: `ketal://oidc` with authorization code
7. **App exchanges code for tokens**: Via MAS
8. **User is authenticated**: Session created

### Key URLs Configured  

| Purpose | URL |
|---------|-----|
| **Homeserver Base** | `https://matrix.ketals.online` |
| **OIDC Issuer** | `https://matrix.ketals.online/auth/` |
| **Account Management** | `https://matrix.ketals.online/auth/account` |
| **Keycloak Realm** | `https://matrix.ketals.online/auth/realms/ketal` |
| **Well-Known Discovery** | `https://ketals.online/.well-known/matrix/client` |

### Verification Checklist

Before testing with the iOS app, verify:

- ✅ Well-known file is accessible and contains client_id
- ✅ MAS is running: `systemctl status matrix-authentication-service`
- ✅ Synapse is running: `systemctl status matrix-synapse`
- ✅ Keycloak is configured (follow KEYCLOAK_SETUP_PLAN.md)
- ✅ Client `C3D9BWGMDZ1J79ZNVRP846JZ7J` exists in Keycloak
- ✅ Redirect URI `ketal://oidc` is whitelisted in Keycloak client

### Testing the Flow

1. Open the ketal iOS app
2. Enter homeserver: `ketals.online`
3. Tap Continue
4. Should redirect to Keycloak login
5. Enter credentials
6. Should redirect back to app
7. Should be logged in

### Troubleshooting

**If login fails:**
- Check MAS logs: `journalctl -fu matrix-authentication-service`
- Check Synapse logs: `journalctl -fu matrix-synapse`
- Check Keycloak logs: `journalctl -fu keycloak`
- Verify well-known file: `curl https://ketals.online/.well-known/matrix/client`
- Verify OIDC discovery: `curl https://matrix.ketals.online/auth/realms/ketal/.well-known/openid-configuration`

---

## Summary

✅ **The iOS app is already correctly configured to work with your server setup.**

No code changes are required in the iOS app. The configuration uses industry-standard OIDC discovery mechanisms to dynamically retrieve the client ID and other parameters from the server's well-known file.

**Next step**: Follow `KEYCLOAK_SETUP_PLAN.md` to configure Keycloak, then test the authentication flow.
