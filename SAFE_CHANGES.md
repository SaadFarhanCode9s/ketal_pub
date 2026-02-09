# Ketal iOS - Safe Implementation Areas

## Summary of Dependable Changes

Based on the scope of work analysis, this document identifies which areas of the codebase can be safely modified without breaking functionality or violating project constraints.

---

## ✅ GREEN LIGHT - Safe to Modify

### 1. **Authentication Service Layer**
**Location:** `ketal/Sources/Services/Authentication/`

**Safe Changes:**
- Add new methods for OTP authentication
- Implement email-based login flow
- Add token exchange with MAS
- Extend `AuthenticationService` protocol with new methods
- Add OTP validation logic

**Why Safe:**
- Currently implements OIDC flow
- Adding OTP is an alternative, not a replacement of core logic
- No impact on core Matrix protocol
- Encapsulated service with clear boundaries

**Example:**
```swift
// Current
func login(username: String, password: String)

// New - additive, doesn't break existing
func initiatePasswordlessOTP(email: String)
func verifyOTP(code: String)
```

---

### 2. **Login/Authentication Screens**
**Location:** `ketal/Sources/Screens/Authentication/`

**Safe Changes:**
- Replace `LoginScreen.swift` with OTP-based UI
- Update `LoginScreenViewModel.swift` for OTP flow
- Modify screen coordinator for new states
- Update state machines in `AuthenticationFlowCoordinator`

**Why Safe:**
- Screens are presentation layer
- Logic isolated from core services
- Can test separately
- No impact on user session management or E2EE

---

### 3. **User/Account Setup Flows**
**Location:** `ketal/Sources/Screens/Authentication/`

**Safe Changes:**
- Create new `UsernameSetupScreen` (new feature)
- Add post-login username selection
- Integrate with existing user session

**Why Safe:**
- New feature, doesn't modify existing flows
- Happens after authentication
- Uses standard Synapse APIs
- Non-breaking addition

---

### 4. **Room Screen UI - Audio Call Button**
**Location:** `ketal/Sources/Screens/RoomScreen/`

**Safe Changes:**
- Add audio call button next to video call
- Add new icons/assets
- Modify call initiation logic to pass call type
- Update view model to handle both audio/video

**Why Safe:**
- UI-only change at presentation layer
- Uses existing Element Call infrastructure
- Just configures call differently
- No impact on call quality or protocol

**Example:**
```swift
// Current
Button("Video Call") { startVideoCall() }

// New - additive
Button("Audio Call") { startAudioCall(type: .audio) }
Button("Video Call") { startAudioCall(type: .video) }
```

---

### 5. **Element Call Service Configuration**
**Location:** `ketal/Sources/Services/ElementCall/ElementCallService.swift`

**Safe Changes:**
- Add `CallType` enum (audio vs video)
- Pass call configuration to Element Call
- Configure camera on/off based on type
- Set audio mode (earpiece vs speaker)

**Why Safe:**
- Same underlying Element Call infrastructure
- Only changes initial configuration
- No changes to call protocol or security
- Element Call already supports these configs

---

### 6. **Homeserver Discovery (`.well-known`)**
**Location:** `ketal/Sources/Services/Client/` (new service)

**Safe Changes:**
- Create `WellKnownService` for `.well-known` discovery
- Update `AppSettings` to use discovered URLs
- Remove hardcoded homeserver URLs
- Initialize client with discovered URLs

**Why Safe:**
- Well-known is Matrix standard
- Upstream supports it already
- No changes to protocol or security
- Purely configuration-level change

---

### 7. **AppSettings Configuration**
**Location:** `ketal/Sources/Application/AppSettings.swift`

**Safe Changes:**
- Add OTP authentication settings
- Add domain configuration (instead of hardcoded URLs)
- Add audio call defaults
- Remove hardcoded homeserver/auth URLs

**Why Safe:**
- Configuration file, not core logic
- Doesn't change behavior when same settings used
- Can revert to hardcoded if needed
- No protocol changes

---

### 8. **State Machine Enhancements**
**Location:** `ketal/Sources/FlowCoordinators/`

**Safe Changes:**
- Add new states for OTP flow (e.g., `otpEntry`, `otpVerification`)
- Add states for username setup
- Add transitions for new flows

**Why Safe:**
- Extending existing state machines
- Non-breaking additions
- Can coexist with existing states
- Clear state isolation

---

### 9. **Test Files and Test Infrastructure**
**Location:** `UnitTests/Sources/`, `UITests/Sources/`

**Safe Changes:**
- Update all `@testable import ElementX` → `@testable import ketal` ✅ DONE
- Add new test files for OTP feature
- Add new test files for audio call feature
- Create mocks for new services

**Why Safe:**
- Tests don't affect production code
- Can isolate new features
- Test infrastructure remains same
- No impact on app runtime

---

### 10. **Documentation and Configuration Files**
**Location:** Root and `.github/`

**Safe Changes:**
- Update README files
- Update build instructions
- Update YAML configuration files
- Add implementation guides
- Create merge strategies

**Why Safe:**
- Doesn't affect code runtime
- Helps future maintenance
- Makes deployment reproducible
- Aids in upstream syncing

---

## ⚠️ YELLOW LIGHT - Modify with Caution

### 1. **Matrix Rust SDK Integration (ClientProxy)**
**Location:** `ketal/Sources/Services/Client/ClientProxy.swift`

**Acceptable Changes:**
- Initialize with discovered homeserver URL (instead of hardcoded)
- Pass configuration flags for audio/video

**Avoid:**
- Any changes to E2EE procedures
- Changes to key exchange
- Modifications to room state handling
- Changes to event processing

**Why Caution:**
- Wrapper around core Matrix protocol
- Protocol changes can break compatibility
- E2EE must remain intact
- Upstream compatibility critical

---

### 2. **User Session Service**
**Location:** `ketal/Sources/Services/Session/`

**Acceptable Changes:**
- Store additional OTP-related settings
- Add username to user profile
- Add first-login flag

**Avoid:**
- Removing any existing session properties
- Changing token storage
- Modifying access token handling
- Changes to session restoration

**Why Caution:**
- Manages user authentication state
- Critical for app security
- Session persistence affects startup
- Token storage must be secure

---

### 3. **Room Proxy Service**
**Location:** `ketal/Sources/Services/Room/RoomProxy.swift`

**Acceptable Changes:**
- Call initiation parameters (passing call type)
- Add call metadata (audio vs video)

**Avoid:**
- Changes to message sending
- Changes to room state
- Changes to event handling
- Encryption-related modifications

**Why Caution:**
- Core messaging functionality depends on it
- Room state changes can break compatibility
- Events are protocol-defined

---

## ❌ RED LIGHT - Do Not Modify

### 1. **Cryptography and E2EE**
**Scope:** No changes allowed
- Key generation algorithms
- Key exchange procedures
- Encryption/decryption logic
- Signature verification
- Device verification flows

**Impact:** Breaking changes that violate Matrix protocol

---

### 2. **Core Room Operations**
**Scope:** No changes allowed
- Room state events
- Membership events
- Room creation/deletion
- Room permissions/roles
- Events database schema

**Impact:** Data corruption, protocol incompatibility

---

### 3. **Timeline/Event Processing**
**Scope:** No changes allowed
- Event ordering
- Event filtering
- Event decryption
- Timestamp handling
- Event persistence

**Impact:** Message loss, conversation breakage

---

### 4. **Synapse/Matrix Protocol APIs**
**Scope:** Read-only with specific approved changes
- User registration API (use existing, don't modify)
- Room API (don't modify behavior)
- Event API (don't modify)
- Crypto APIs (don't touch)

**Approved Changes:**
- Calling with email OTP (add new auth type)
- Username discovery (use existing endpoints)
- .well-known discovery (standard Matrix)

**Do Not:**
- Change endpoint paths
- Modify request/response structures
- Bypass security checks
- Create new protocol modifications

---

### 5. **Existing User-Facing Features**
**Scope:** Do not break
- Message sending and receiving
- Room navigation
- Settings screens (mostly)
- Media upload/download
- User search
- Room search

**Note:** Branding changes to these screens are OK (colors, icons), but functionality must remain identical.

---

### 6. **Build and Deployment System**
**Scope:** Don't break existing system
- Target configuration (modified for ketal naming ✅ DONE)
- Build phases
- Code signing
- Dependency management
- Version management

**Safe:** Configuration changes for ketal branding  
**Unsafe:** Changing build system structure

---

### 7. **Third-Party Dependencies**
**Scope:** Upgrade with care, don't remove
- Matrix Rust SDK version
- Compound (design system)
- Element Call integration
- WysiwygComposer
- Other approved packages

**Process:**
- Check upstream for compatible versions
- Test thoroughly after updates
- Keep versions compatible with upstream

---

## 🔍 Area-by-Area Safety Matrix

| Component | Current State | Safe to Modify? | Why? |
|-----------|--------------|-----------------|------|
| **Branding** | ✅ DONE | ✅ YES | Naming, bundle ID, icons |
| **OTP Authentication** | TODO | ✅ YES | New service, encapsulated |
| **Audio Call** | TODO | ✅ YES | Config only, existing infrastructure |
| **Homeserver Discovery** | TODO | ✅ YES | Standard Matrix, replaces hardcoded |
| **Username Setup** | TODO | ✅ YES | New screen, post-auth |
| **UI/Screens** | TODO | ✅ YES | Presentation layer |
| **E2EE/Crypto** | EXISTING | ❌ NO | Protocol-critical |
| **Room Operations** | EXISTING | ❌ NO | Core functionality |
| **Timeline** | EXISTING | ⚠️ CAUTION | Don't break existing |
| **Session Management** | EXISTING | ⚠️ CAUTION | Token handling critical |

---

## Implementation Philosophy

### When Making Changes:

**✅ DO:**
1. Keep features encapsulated
2. Use dependency injection
3. Create abstractions for new services
4. Write tests for new logic
5. Document architectural decisions
6. Keep core logic unchanged
7. Maintain upstream compatibility

**❌ DON'T:**
1. Modify core Matrix SDK behavior
2. Change existing screen behavior (only presentation)
3. Break existing tests
4. Modify encryption procedures
5. Change event processing
6. Hard-code configuration
7. Remove existing features

---

## Safe Patterns for Common Changes

### Pattern 1: Add New Authentication Method
```swift
// ✅ SAFE - New method, doesn't break existing
protocol AuthenticationServiceProtocol {
    // Existing
    func login(username: String, password: String) async
    
    // New - additive
    func initiatePasswordlessOTP(email: String) async
    func verifyOTP(code: String) async
}
```

### Pattern 2: Configure Existing Feature
```swift
// ✅ SAFE - Using existing infrastructure
enum CallType {
    case audio  // camera off, earpiece
    case video  // camera on, speaker
}

elementCallService.startCall(type: .audio)  // Configure existing
```

### Pattern 3: Add New Screen
```swift
// ✅ SAFE - New screen, isolated flow
new UsernameSetupScreen()  // Post-auth setup
new OTPEntryScreen()        // OTP entry
```

### Pattern 4: Replace Configuration
```swift
// ✅ SAFE - Use standard Matrix discovery
// Before: let homeserver = URL(string: "https://matrix.myapp.com")
// After:
let homeserver = try await wellKnownService.discoverHomeserver(domain: "myapp.com")
```

---

## When in Doubt

Ask these questions:

1. **Does this change the Matrix protocol?**
   - If YES → ❌ Don't do it
   
2. **Does this affect E2EE or security?**
   - If YES → ❌ Don't do it

3. **Does this break an existing feature?**
   - If YES → ❌ Don't do it

4. **Is this a new feature or configuration?**
   - If YES → ✅ Probably safe

5. **Can this be isolated/encapsulated?**
   - If YES → ✅ Probably safe

6. **Is this configuration-driven?**
   - If YES → ✅ Probably safe

7. **Does upstream ElementX have similar capability?**
   - If YES → ✅ Likely compatible

---

## Summary

**Safe to Implement:**
- ✅ Email OTP authentication
- ✅ Audio call button
- ✅ Username setup screen
- ✅ Homeserver discovery (.well-known)
- ✅ UI/UX changes
- ✅ New configuration services
- ✅ New screens and flows

**Critical to Preserve:**
- ❌ End-to-end encryption
- ❌ Core Matrix protocol
- ❌ Room state management
- ❌ Timeline/event processing
- ❌ Existing user features

**Currently Completed:**
- ✅ App rebranding (ElementX → ketal)
- ✅ Bundle ID changes
- ✅ Project configuration
- ✅ All test file updates

**Ready for Implementation:**
- 🟡 Server stack design (TBD)
- 🟡 iOS feature development
- 🟡 Integration testing

---

**Document Status**: Complete safety analysis  
**Date**: 2026-01-22  
**Approval**: Ready for development team
