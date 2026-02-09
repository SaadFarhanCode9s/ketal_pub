# Ketal iOS - Scope of Work Analysis & Context

## Executive Summary

This is **Milestone 1** of a project to create **ketal** - a rebranded, custom ElementX iOS fork with a self-hosted Synapse authentication and calling infrastructure. The app will use passwordless email OTP (One-Time Password) authentication instead of traditional password login.

---

## Project Goals

### Primary Objectives
1. **Branding** - Rebrand ElementX to "ketal" (✅ COMPLETED in Linux environment)
2. **Authentication** - Implement email OTP login flow (server-side + iOS client)
3. **Calling** - Add Audio Call button alongside existing Video Call button
4. **Infrastructure** - Deploy Synapse + Keycloak + MAS on a VPS with custom domain

### Success Criteria
- Fully functional ketal iOS app with custom branding
- Email OTP-based passwordless authentication
- Audio and Video calling both working
- Server stack deployable and reproducible
- iOS client remains close to upstream ElementX

---

## iOS Client Scope of Work

### ✅ Already Completed (Phase 1)
- **Full app rebranding from ElementX to ketal**
  - Project name: `ketal`
  - Bundle ID: `io.ketal.app`
  - App display name: `ketal`
  - Directory renamed: `ElementX/` → `ketal/`
  - All configuration files updated
  - 154+ test files updated
  - Ready for xcodegen and build

### ⏳ Still To Do (Phase 2)

#### 1. **Login Flow - Email OTP Authentication**
**Location:** Will modify login/authentication screens in `ketal/Sources/Screens/Authentication/`

**Requirements:**
- Replace traditional username/password login with email-based OTP flow
- Use **web-based auth flow** in WebView bottom sheet modal (not native forms)
- Flow should be:
  1. User enters email
  2. System sends OTP via email (Keycloak → Resend SMTP)
  3. User enters OTP received in email
  4. Account created automatically (or signed in if exists)
  5. User sets username on first login (using Synapse/MAS APIs)

**Key Points:**
- Follows Matrix Authentication Service (MAS) passwordless OTP specification
- WebView-based authentication (similar to existing OIDC flows)
- Single unified login/signup flow (not separate)
- Username selection on first login using existing Synapse/MAS APIs

**Files to Modify:**
- `ketal/Sources/Screens/Authentication/` - Auth screen coordinators
- `ketal/Sources/Services/Authentication/` - Auth service logic
- `ketal/Sources/Application/AppSettings.swift` - Auth configuration

**No Changes To:**
- Cryptography/E2EE (end-to-end encryption)
- Core Matrix protocol behavior
- Key management procedures
- Security procedures

---

#### 2. **Calling Feature - Add Audio Call Button**
**Location:** `ketal/Sources/Screens/RoomScreen/` and Element Call integration

**Requirements:**
- Add **Audio Call button** next to existing **Video Call button**
- Same underlying call flow as Video Call (uses same Element Call service)
- **Only difference:** Initial settings/configuration
  
**Audio Call Configuration:**
```
- Camera: OFF by default
- Microphone: ON by default
- Audio mode: Handset/Earpiece mode (not speakerphone)
```

**Video Call Configuration (Existing):**
```
- Camera: ON by default
- Microphone: ON by default
- Audio mode: Speaker mode
```

**Implementation Approach:**
- Leverage existing `EmbeddedElementCall` package (already integrated)
- Add new call type or configuration parameter
- Create separate button with audio icon next to video icon
- Pass appropriate configuration flags to ElementCall service

**Files to Modify:**
- `ketal/Sources/Screens/RoomScreen/RoomScreen.swift` - Add audio call button UI
- `ketal/Sources/Services/ElementCall/` - Handle audio call configuration
- Possibly: `ketal/Sources/Services/Room/RoomProxy.swift` - If needed for call initiation

---

#### 3. **Homeserver Discovery - .well-known Configuration**
**Requirement:** Homeserver URL must NOT be hardcoded; use `.well-known` discovery

**Current Implementation:**
- Check `ketal/Sources/Application/AppSettings.swift` for homeserver configuration
- Likely has hardcoded homeserver URL

**Change Needed:**
- Implement `.well-known/matrix/client` and `.well-known/matrix/server` discovery
- Client fetches homeserver URL from discovered domain
- This allows multiple deployments without code changes

**Files to Modify:**
- `ketal/Sources/Application/AppSettings.swift`
- Possibly: `ketal/Sources/Services/Authentication/AuthenticationService.swift`

---

#### 4. **First-Time Username Selection**
**Requirement:** On first login, prompt user to choose username

**Implementation:**
- After OTP verification and account creation
- Use Synapse/MAS existing APIs for username validation
- Check username availability via API
- Allow user to set display name
- Follow UI from provided Figma design

**Files to Modify:**
- `ketal/Sources/Screens/Authentication/` - Add username selection screen post-login
- May need new screen: `FirstTimeSetupScreen` or similar

---

### iOS Client Architecture Reference

**Key Services to Understand:**

1. **Authentication Service** (`ketal/Sources/Services/Authentication/`)
   - Handles login/signup flows
   - Manages OIDC/auth tokens
   - Interacts with MAS

2. **User Session Service** (`ketal/Sources/Services/Session/`)
   - Manages authenticated user state
   - Stores session tokens
   - Coordinates with Synapse client

3. **Element Call Service** (`ketal/Sources/Services/ElementCall/`)
   - Already exists for video calls
   - Will extend for audio calls

4. **Client Proxy** (`ketal/Sources/Services/Client/`)
   - FFI wrapper around Matrix Rust SDK
   - Handles all Matrix protocol operations

5. **App Settings** (`ketal/Sources/Application/AppSettings.swift`)
   - Runtime configuration
   - Server URLs and auth endpoints
   - Feature flags

---

## Server Stack Scope of Work

### Components to Deploy

#### 1. **Keycloak (Authentication Provider)**
- Docker Compose deployment
- Configured for Email OTP passwordless flow
- SMTP integration with Resend (email delivery)
- Custom login flow UI (per Figma design)
- Acts as OpenID Connect (OIDC) provider for MAS

#### 2. **Matrix Authentication Service (MAS)**
- Bridges between Keycloak (OIDC) and Synapse
- Passwordless OTP configuration
- Username validation against Synapse

#### 3. **Synapse Homeserver**
- Deployed via Synapse Ansible playbook
- Real-time audio/video calling dependencies
- Admin APIs (protected from direct client access)
- User registration via MAS

#### 4. **Supporting Services**
- **synapse-admin** - Admin UI for server management
- **element-admin** - Matrix admin utilities
- **SMTP Service** - Resend.io for email delivery
- **SSL/TLS Certificates** - Properly provisioned (not self-signed in production)

### Infrastructure Requirements

**Domains Needed:**
```
myapp.com                    # Main app domain
matrix.myapp.com            # Synapse homeserver
auth.myapp.com              # Keycloak
```

**VPS Requirements:**
- Single VPS (all services on one machine)
- Sufficient CPU/RAM for:
  - Keycloak (Java-based)
  - Synapse (Python-based)
  - PostgreSQL database
  - Supporting services
- Estimated: 4GB RAM, 2 CPU cores minimum

**Third-Party Accounts Needed:**
- Domain registrar account
- VPS provider (DigitalOcean, Linode, Hetzner, etc.)
- Resend.io account (or similar SMTP provider)
- Apple Developer Account (for TestFlight)

---

## Security Requirements (CRITICAL)

### Must Follow Best Practices:
1. **Certificate Provisioning**
   - Use Let's Encrypt (via Certbot in Docker)
   - Auto-renewal before expiration
   - Proper certificate chain

2. **Admin API Protection**
   - Synapse admin APIs NOT exposed to client
   - Only internal/VPS network access
   - Authentication required for all admin endpoints

3. **User Verification**
   - New users created ONLY after email OTP verification
   - No unverified accounts
   - OTP expires after reasonable time (e.g., 10 minutes)

4. **E2EE Preservation**
   - No changes to Matrix E2EE procedures
   - No changes to key management
   - No changes to cryptographic procedures
   - Full end-to-end encryption support

5. **Data Protection**
   - HTTPS only (no HTTP)
   - Secure password hashing for internal accounts
   - Database backups and security
   - Firewall rules limiting access

---

## Integration Points

### iOS ↔ Server Communication

```
iOS App (ketal)
    ↓ HTTPS
    ↓ .well-known discovery
    ↓
Keycloak (auth.myapp.com)
    ↓ OIDC/OTP flow
    ↓
MAS (Matrix Auth Service)
    ↓ Bridges to
    ↓
Synapse (matrix.myapp.com)
    ↓
Room messages, E2EE, Calling
```

### Authentication Flow

```
1. User opens ketal app
2. App discovers homeserver via .well-known
3. User enters email
4. Keycloak sends OTP via Resend
5. User enters OTP
6. MAS verifies OTP with Keycloak
7. MAS creates Synapse user or logs in
8. User gets access token
9. User prompted to choose username
10. User can now message and call
```

### Calling Flow

```
Audio/Video Call Button
    ↓
ElementCallService detects call type
    ↓
Element Call infrastructure (WebRTC)
    ↓
Audio Call: mic on, camera off, earpiece mode
Video Call: mic on, camera on, speaker mode
    ↓
Both use same underlying P2P/SFU infrastructure
```

---

## What Should NOT Be Changed

### ✋ Off-Limits Areas

1. **Matrix Protocol Core**
   - No E2EE changes
   - No key exchange modifications
   - No room state changes
   - No event structure changes

2. **Cryptography**
   - No changes to encryption procedures
   - No changes to key management
   - No changes to signature algorithms

3. **Upstream Compatibility**
   - Remain mergeable with upstream ElementX
   - Configuration changes, not logic changes where possible
   - Keep architectural patterns intact

4. **Element Web**
   - Server must work with unmodified Element Web client
   - No server-level breaking changes
   - Compatible homeserver API

---

## Deliverables Checklist

### Phase 1 (Already Complete ✅)
- [x] Rebranded iOS app (ketal)
- [x] All configuration updated
- [x] Ready for build on macOS

### Phase 2 (TODO - iOS Features)
- [ ] Email OTP login flow (WebView + MAS integration)
- [ ] Audio call button implementation
- [ ] Username selection on first login
- [ ] .well-known homeserver discovery
- [ ] Internal TestFlight build signed and uploaded

### Phase 3 (TODO - Server Deployment)
- [ ] Keycloak Docker Compose stack
- [ ] Synapse Ansible playbook configuration
- [ ] MAS integration with Keycloak
- [ ] Custom domain setup (myapp.com, auth.*, matrix.*)
- [ ] SSL certificates properly provisioned
- [ ] Email OTP working end-to-end

### Phase 4 (TODO - Documentation)
- [ ] Private GitHub repo: iOS source code
- [ ] Private GitHub repo: Server code/scripts
- [ ] README for iOS: Build & run instructions
- [ ] README for Server: Deploy instructions
- [ ] "Happy path" test documentation

---

## Implementation Priority

### Must Do First:
1. **Email OTP Authentication** - Core feature, blocks everything else
2. **Keycloak + MAS Setup** - Required for auth flow
3. **Synapse Deployment** - Required for messaging/calling
4. **.well-known Discovery** - Required for flexible deployment

### Then Add:
5. **Audio Call Button** - Enhancement to existing feature
6. **Username Selection** - UX refinement
7. **TestFlight Build** - Release artifact

---

## Timeline Considerations

- **Keycloak + Resend Email Setup**: 2-3 days
- **Synapse + MAS Integration**: 3-5 days  
- **iOS OTP Login Flow**: 2-3 days
- **iOS Audio Call Button**: 1-2 days
- **Testing & Bug Fixes**: 2-3 days
- **Documentation & Delivery**: 1-2 days

**Estimated Total**: 2-3 weeks for full milestone

---

## Success Metrics

An implementation is successful when:

1. ✅ User can sign up via email OTP in iOS app
2. ✅ User can set username after first login
3. ✅ User can send/receive encrypted messages
4. ✅ User can initiate video call
5. ✅ User can initiate audio call (camera off, earpiece mode)
6. ✅ Both call types work end-to-end
7. ✅ Server is deployed on custom domain
8. ✅ All code is documented and reproducible
9. ✅ iOS app remains mergeable with upstream ElementX
10. ✅ No E2EE or security procedures compromised

---

## Current Status (as of Jan 22, 2026)

**Phase 1: ✅ COMPLETE**
- Rebranding done on Linux machine
- All configuration updated
- Code synced to macOS VM via `sync-to-mac.sh`
- Next: Build on macOS and verify no build errors

**Phase 2: 🔄 IN PROGRESS (Next)**
- Will require iOS development work
- Authentication flow implementation
- Calling feature enhancement

**Phase 3: 📋 PENDING**
- Server infrastructure setup required
- Requires VPS and domain access

**Phase 4: 📋 PENDING**
- Final documentation and delivery

---

## Key Files Reference

### iOS App
- **Config**: `project.yml`, `app.yml`, `ketal/SupportingFiles/target.yml`
- **Auth**: `ketal/Sources/Services/Authentication/`
- **Settings**: `ketal/Sources/Application/AppSettings.swift`
- **Calling**: `ketal/Sources/Services/ElementCall/`
- **Screens**: `ketal/Sources/Screens/`

### Server
- **Keycloak**: Docker Compose config (to be created)
- **Synapse**: Ansible playbook (provided)
- **MAS**: Configuration files (to be created)
- **Infrastructure**: Docker network, PostgreSQL, Redis (as needed)

---

## Questions to Clarify

If continuing development, clarify:

1. **Email Provider**: Use Resend.io or different SMTP provider?
2. **Domain**: What domain name to use for deployment?
3. **VPS Provider**: DigitalOcean, Linode, Hetzner, or other?
4. **Username Format**: Any requirements for allowed usernames?
5. **OTP Duration**: How long should OTP codes be valid?
6. **Call Configuration**: Any additional audio settings needed?
7. **UI Design**: Reference Figma design provided?
8. **Testing Users**: How many concurrent users to support?

---

**Document Status**: Complete analysis of scope and context  
**Date**: 2026-01-22  
**For**: ketal iOS - Milestone 1 Delivery
