# Ketal iOS - Complete Context & Analysis Summary

**Date:** 2026-01-22  
**Status:** ✅ PHASE 1 COMPLETE | 📋 PHASE 2 PLANNED  
**Project:** ketal iOS - Rebranded ElementX with Email OTP Auth & Audio Calls

---

## 📋 What is Ketal?

**Ketal** is a custom-branded fork of ElementX iOS (a Matrix client) with:

1. **Rebranding** - App renamed from "Element X" to "ketal"
2. **Authentication** - Passwordless email OTP login (instead of username/password)
3. **Calling Features** - Audio call button alongside existing video calls
4. **Infrastructure** - Self-hosted Synapse server + Keycloak auth on a custom domain

**Timeline:** Milestone 1 delivery (prototype with all features working)

---

## ✅ PHASE 1 - COMPLETED (Jan 22, 2026)

### What Was Done

**Full Application Rebranding:**
- ✅ Directory renamed: `ElementX/` → `ketal/`
- ✅ Project name: `ketal`
- ✅ Bundle ID: `io.ketal.app` (was: `io.element.elementx`)
- ✅ App group: `group.io.ketal` (was: `group.io.element`)
- ✅ App display name: `ketal` (was: `Element X`)
- ✅ Xcode scheme: `ketal` (was: `ElementX`)

**Configuration Files Updated:**
- ✅ `project.yml` - 3 changes
- ✅ `app.yml` - 3 changes
- ✅ `localazy.json` - 6 path updates
- ✅ `fastlane/Fastfile` - 3 target references
- ✅ `.githooks/pre-commit` - 2 path references
- ✅ 7 target.yml files across NSE, ShareExtension, tests
- ✅ 7 xctestplan files with container paths
- ✅ `.github/copilot-instructions.md` - Updated with ketal references
- ✅ `docs/FORKING.md` - Updated with new bundle IDs

**Swift Code Updates:**
- ✅ 154+ test files: `@testable import ElementX` → `@testable import ketal`
- ✅ All test plan files updated with new container paths
- ✅ 1,239 files in ketal/ directory structure verified

**Documentation Created:**
- ✅ `.rebranding-strategy.md` - 500+ lines on upstream merge strategy
- ✅ `KETAL_QUICKSTART.md` - Quick start guide for macOS build
- ✅ `SCOPE_ANALYSIS.md` - Comprehensive scope breakdown (this document)
- ✅ `IMPLEMENTATION_ROADMAP.md` - Technical specs for Phase 2
- ✅ `SAFE_CHANGES.md` - Areas safe/unsafe to modify
- ✅ `commit-rebranding.sh` - Automated git commit helper

**Status:** Ready for macOS VM build

---

## 📊 Current Situation (What Exists Now)

### iOS App Structure

```
ketal/ (formerly ElementX/)
├── Sources/
│   ├── Application/          # AppDelegate, AppSettings, Configuration
│   ├── Services/             # Network, Auth, Room, etc.
│   ├── FlowCoordinators/     # Navigation state machines
│   ├── Screens/              # UI screens (Home, Room, Auth, etc.)
│   ├── Other/                # Utilities, extensions
│   └── Generated/            # Code-gen output (Strings, Assets)
├── Resources/                # Images, colors, localizations
└── SupportingFiles/          # Info.plist, entitlements, etc.
```

### Current Features (Already Working)

✅ **Authentication:**
- OIDC-based login (against configured auth server)
- User sessions and tokens
- Account restoration on app relaunch

✅ **Messaging:**
- Send/receive messages
- Room creation and management
- Message reactions
- Threads
- Full end-to-end encryption (E2EE)

✅ **Calling:**
- Video calls via Element Call
- Real-time audio/video communication
- Call notifications and management

✅ **User Features:**
- User profiles and avatars
- Room member list
- Room details and settings
- Push notifications
- Rich message formatting

### Technology Stack

- **Language:** Swift 6.1+
- **UI Framework:** SwiftUI with Combine
- **Backend SDK:** Matrix Rust SDK (via FFI)
- **Architecture:** MVVM + Coordinator Pattern
- **Testing:** XCTest, snapshot tests, UI tests
- **Build System:** XcodeGen (YAML → .xcodeproj)

---

## 📋 PHASE 2 - PLANNED (What Needs Implementation)

### Feature 1: Email OTP Authentication

**What it does:**
- User enters email instead of username/password
- App sends OTP (one-time password) to email
- User enters OTP code from email
- User authenticated and logged in

**Current flow (OIDC):**
```
App → OIDC Server → Login form → Username/Password
```

**New flow (OTP):**
```
App → Keycloak + MAS → Login form → Email → OTP code → Email → Verified
```

**Files to modify:**
- `ketal/Sources/Services/Authentication/` - OTP logic
- `ketal/Sources/Screens/Authentication/` - Email + OTP UI
- `ketal/Sources/Application/AppSettings.swift` - OTP config

**Estimated effort:** 3-4 days

---

### Feature 2: Audio Call Button

**What it does:**
- Adds audio call button alongside video call button
- Audio call: camera OFF, microphone ON, earpiece mode
- Video call: camera ON, microphone ON, speaker mode
- Same underlying technology, different initial config

**Current:** Only video call button  
**New:** Audio call + Video call buttons

**Files to modify:**
- `ketal/Sources/Screens/RoomScreen/` - Add button UI
- `ketal/Sources/Services/ElementCall/` - Handle call type config
- Asset library - Add audio call icon

**Estimated effort:** 1-2 days

---

### Feature 3: First-Login Username Selection

**What it does:**
- When user logs in for first time, prompt to choose username
- Check username availability via API
- User sets username before accessing app

**Current:** Automatic username assignment  
**New:** User chooses username on first login

**Files to modify:**
- `ketal/Sources/Screens/Authentication/` - New username screen
- `ketal/Sources/FlowCoordinators/AuthenticationFlowCoordinator.swift` - Add state
- `ketal/Sources/Services/` - Username API integration

**Estimated effort:** 1-2 days

---

### Feature 4: Homeserver Discovery (.well-known)

**What it does:**
- Instead of hardcoding homeserver URL, app fetches it from `.well-known`
- Standard Matrix feature for dynamic homeserver configuration
- Allows deployment on any domain without code changes

**Current:** Hardcoded URLs in AppSettings  
**New:** Dynamically discover via `.well-known/matrix/client`

**Files to modify:**
- `ketal/Sources/Application/AppSettings.swift` - Remove hardcoded URLs
- `ketal/Sources/Services/Client/` - New WellKnownService
- `ketal/Sources/Services/Authentication/` - Call discovery before auth

**Estimated effort:** 1 day

---

## 🖥️ Server Stack (Also Needed)

### Components to Deploy

**1. Keycloak** - Authentication provider
- Docker-based deployment
- Email OTP configuration
- Custom login UI

**2. Matrix Authentication Service (MAS)** - Auth bridge
- Connects Keycloak to Synapse
- Passwordless OTP support
- User registration management

**3. Synapse Homeserver** - Matrix protocol server
- User accounts and storage
- Room state management
- Message persistence
- Calling infrastructure

**4. Supporting Services**
- PostgreSQL database
- Resend.io (email delivery)
- synapse-admin (server management)
- SSL/TLS certificates

### Deployment Target

- Single VPS (cloud server)
- Custom domain: `myapp.com`
- Subdomains:
  - `matrix.myapp.com` - Synapse homeserver
  - `auth.myapp.com` - Keycloak
  - `myapp.com` - App domain for .well-known

**Estimated effort:** 3-5 days setup + 2-3 days integration

---

## 🎯 What Can Be Changed Safely

### ✅ YES - Safe to Modify

1. **Authentication Services** - Add OTP logic (new service, doesn't break existing)
2. **Login Screens** - Replace with OTP UI
3. **Username Setup** - New screen post-login
4. **Room Screens** - Add audio call button (UI only)
5. **Element Call Service** - Configure for audio/video
6. **Configuration** - Remove hardcoded URLs, use discovery
7. **Tests** - Update/add tests for new features
8. **Documentation** - Update guides and instructions

**Principle:** New features and UI changes are safe; configuration is safe; existing functionality preserved.

---

### ❌ NO - Do Not Modify

1. **End-to-End Encryption** - Core Matrix protocol feature
2. **Cryptography** - Key exchange, encryption algorithms
3. **Core Matrix Protocol** - Room state, events, timelines
4. **Existing Features** - Message sending, room management, etc.
5. **Session Management** - Token handling, authentication core logic

**Principle:** Don't touch protocol-critical or security-critical code.

---

## 📁 Key Files Reference

### Most Important Files to Know

| File | Purpose | Status |
|------|---------|--------|
| `project.yml` | XcodeGen main config | ✅ Updated |
| `app.yml` | App settings (bundle ID, display name) | ✅ Updated |
| `ketal/SupportingFiles/target.yml` | App target config | ✅ Updated |
| `ketal/Sources/Application/AppSettings.swift` | Runtime config | 🟡 TBD |
| `ketal/Sources/Services/Authentication/` | Login/auth logic | 🟡 TBD |
| `ketal/Sources/Screens/Authentication/` | Login UI screens | 🟡 TBD |
| `ketal/Sources/Services/ElementCall/` | Calling service | 🟡 TBD |
| `ketal/Sources/Screens/RoomScreen/` | Room UI with call buttons | 🟡 TBD |

---

## 🚀 Next Steps (In Order)

### Immediate (On macOS VM)
1. [ ] Copy code to macOS VM (already synced via `sync-to-mac.sh`)
2. [ ] Run `swift run tools setup-project` to generate Xcode project
3. [ ] Open `ketal.xcodeproj` in Xcode
4. [ ] Verify scheme is "ketal" (not "ElementX")
5. [ ] Select iOS simulator
6. [ ] Build and run to verify no build errors
7. [ ] Test existing features (messages, calls)

### Phase 2 Development
1. [ ] Design server architecture (Keycloak + Synapse + MAS)
2. [ ] Deploy test server stack
3. [ ] Implement OTP authentication in iOS
4. [ ] Add audio call button feature
5. [ ] Implement username selection screen
6. [ ] Add .well-known discovery
7. [ ] End-to-end testing
8. [ ] Create TestFlight build

### Phase 2 Completion
1. [ ] Document deployment process
2. [ ] Create GitHub repositories (public or private)
3. [ ] Write README files
4. [ ] Test "happy path" (signup → message → audio call → video call)
5. [ ] Upload to TestFlight
6. [ ] Final verification and delivery

---

## 📚 Documentation Available

All created during Phase 1 analysis:

1. **SCOPE_ANALYSIS.md** (this file) - Complete scope breakdown
2. **IMPLEMENTATION_ROADMAP.md** - Technical specs for Phase 2 development
3. **SAFE_CHANGES.md** - Areas safe/unsafe to modify
4. **KETAL_QUICKSTART.md** - Quick start for macOS build
5. **.rebranding-strategy.md** - Strategy for upstream merges
6. **REBRANDING_SUMMARY.txt** (in root) - Phase 1 summary
7. **.github/copilot-instructions.md** - Updated with ketal references

---

## 🔐 Security & Compliance

### Critical Requirements

**Must NOT Change:**
- ✋ End-to-end encryption procedures
- ✋ Key exchange methods
- ✋ Cryptographic algorithms
- ✋ Message integrity checks

**Must Follow:**
- ✅ Matrix security best practices
- ✅ Certificate provisioning (Let's Encrypt)
- ✅ Admin API protection
- ✅ Email verification before account creation
- ✅ OTP expiration (reasonable timeout)
- ✅ HTTPS only (no HTTP)

**Must Verify:**
- ✅ No sensitive data in logs
- ✅ Tokens not exposed to client network
- ✅ Database encrypted at rest (if applicable)
- ✅ Rate limiting on auth attempts

---

## 📊 Project Metrics

| Metric | Value |
|--------|-------|
| **Files Modified (Phase 1)** | 149+ configuration files |
| **Test Files Updated** | 154 files |
| **Total App Files** | 1,239 in ketal/ |
| **New Documentation** | 4 comprehensive guides |
| **Estimated Phase 2 Effort** | 8-12 days |
| **Estimated Phase 3 Effort** | 5-7 days (server) |
| **Total Milestone 1** | 3-4 weeks |

---

## ✨ Success Criteria

Milestone 1 is complete when:

1. ✅ App rebranded to "ketal" (Phase 1 - DONE)
2. ✅ Email OTP authentication working end-to-end
3. ✅ Audio call button functional (camera off, earpiece mode)
4. ✅ Username selection on first login
5. ✅ Homeserver discovery via .well-known
6. ✅ Server stack deployed on custom domain
7. ✅ TestFlight build created and testable
8. ✅ All documentation complete
9. ✅ Happy path working (signup → message → audio call → video call)
10. ✅ Code remains close to upstream ElementX

---

## 🎓 Learning Resources

**Matrix Protocol:**
- https://matrix.org/docs/
- https://spec.matrix.org/

**Element X iOS:**
- https://github.com/element-hq/element-x-ios
- Project uses Matrix Rust SDK + SwiftUI

**Keycloak:**
- https://www.keycloak.org/
- Docker Compose for easy deployment

**Synapse:**
- https://github.com/matrix-org/synapse
- Ansible playbook for production deployment

---

## 📞 Questions to Consider

Before starting Phase 2, clarify with stakeholders:

1. **Domain & Infrastructure**
   - What domain to use? (myapp.com, custom.io, etc.)
   - Which VPS provider? (DigitalOcean, Linode, AWS, etc.)
   - Who will manage infrastructure?

2. **Email Provider**
   - Use Resend.io or different SMTP?
   - Who pays for email service?
   - Testing email addresses for QA?

3. **UI/Design**
   - Figma design provided - review it?
   - Customize Keycloak login UI to match app?
   - Branding colors and fonts?

4. **Testing & Deployment**
   - Internal testing only or beta users?
   - How many concurrent users expected?
   - Backup and disaster recovery plan?

5. **Apple Developer Account**
   - Bundle signing (7J4U792NQT team in current config)?
   - TestFlight build distribution?
   - App Store submission timeline?

---

## 🎯 Summary

**Status:** ✅ Phase 1 Complete | 📋 Phase 2 Ready  
**Rebranding:** ✅ 100% Complete  
**App Ready:** ✅ For macOS build  
**Documentation:** ✅ Comprehensive  
**Next:** Server architecture + iOS feature development

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-22  
**Author:** Development Team  
**Project:** ketal iOS - Milestone 1  
**For:** Client review and team implementation
