# Ketal iOS - Technical Implementation Roadmap

## Phase 2: iOS Features Development

This document outlines the exact technical steps needed to implement the remaining iOS features for Milestone 1.

---

## Feature 1: Email OTP Authentication Flow

### 1.1 Overview
Replace traditional password-based login with passwordless email OTP flow. Uses WebView-based authentication via Matrix Authentication Service (MAS) with Keycloak backend.

### 1.2 Architecture Decision
```
Client App (ketal)
    ↓
WebView (uses ASWebAuthenticationSession or embedded WKWebView)
    ↓
Keycloak (auth.myapp.com)
    ↓ Initiates OTP flow
    ↓ Sends OTP email via Resend
    ↓
User enters OTP in Keycloak UI
    ↓
Keycloak verifies → Creates OIDC token
    ↓
MAS exchanges OIDC for Matrix access token
    ↓
Client receives Matrix token → User authenticated
```

### 1.3 iOS Implementation Steps

#### Step 1: Configure AppSettings for OTP
**File:** `ketal/Sources/Application/AppSettings.swift`

Current structure likely has:
```swift
struct OIDCConfiguration {
    let clientId: String
    let redirectUrl: String
    let discoveryUrl: String  // Keycloak's .well-known endpoint
}
```

**Changes Needed:**
```swift
struct OIDCConfiguration {
    let clientId: String
    let redirectUrl: String
    let discoveryUrl: String
    
    // OTP-specific
    let passwordlessFlowEnabled: Bool = true
    let authMethod: String = "password-less-email-otp"  // or similar
}
```

#### Step 2: Modify Authentication Service
**File:** `ketal/Sources/Services/Authentication/AuthenticationService.swift`

**Current Flow:** Likely supports OIDC with username/password

**New Flow:**
```swift
// When user initiates login
func initiatePasswordlessOTPAuth(email: String) async throws {
    // 1. Call Keycloak endpoint to initiate OTP flow
    // 2. Keycloak sends OTP email via Resend
    // 3. Return to user: "Check your email"
}

// When user enters OTP
func verifyOTPAndAuthenticate(email: String, otpCode: String) async throws -> AuthenticationResult {
    // 1. Send OTP code to Keycloak
    // 2. Keycloak verifies → issues OIDC token
    // 3. Exchange OIDC token with MAS for Matrix token
    // 4. Return authentication result with Matrix access token
}
```

#### Step 3: Update Login Screen
**File:** `ketal/Sources/Screens/Authentication/LoginScreen.swift`
**Related:** `ketal/Sources/Screens/Authentication/LoginScreenViewModel.swift`

**Current State:** Likely shows username/password form

**New State:** Email OTP form
```swift
// Step 1: Email entry screen
@State var email: String = ""
@State var isEmailSubmitted: Bool = false

// Step 2: OTP entry screen (after email submitted)
@State var otpCode: String = ""
@State var remainingTime: Int = 600  // 10 minutes
@State var canResendOTP: Bool = false

// View structure:
if !isEmailSubmitted {
    // EmailEntryView
} else {
    // OTPEntryView
}
```

**UI Components Needed:**
- Email text field (validation)
- OTP input fields (6 digits)
- Timer showing OTP expiration
- "Resend OTP" button (disabled until timer expires)
- Error messages for invalid OTP

#### Step 4: Handle WebView-Based Auth (if needed)
**File:** `ketal/Sources/Services/Authentication/AuthenticationService.swift`

If Keycloak UI is complex or requires custom branding:
```swift
func initiateWebViewOTPAuth(presentationAnchor: ASPresentationAnchor) async throws {
    // Use ASWebAuthenticationSession
    let session = ASWebAuthenticationSession(
        url: keycloakOAuthURL,
        callbackURLScheme: "io.ketal.app",
        completionHandler: { url, error in
            // Handle OAuth redirect with OIDC code
        }
    )
    session.presentationContextProvider = self
    session.start()
}
```

#### Step 5: Token Exchange with MAS
**File:** `ketal/Sources/Services/Authentication/AuthenticationService.swift`

```swift
func exchangeOIDCTokenForMatrixToken(oidcToken: String) async throws -> MatrixAuthResult {
    // MAS endpoint: POST /api/m.authentication_issuer/authorize
    // Send OIDC token → Get Matrix access token
    // Store token for Synapse client
}
```

### 1.4 Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `AppSettings.swift` | Modify | Add OTP configuration |
| `AuthenticationService.swift` | Modify | Implement OTP flow |
| `AuthenticationServiceProtocol.swift` | Modify | Add OTP method signatures |
| `LoginScreen.swift` | Replace | Email + OTP entry form |
| `LoginScreenViewModel.swift` | Modify | OTP validation logic |
| `OTPEmailService.swift` | Create (maybe) | Handle OTP delivery orchestration |

### 1.5 Testing Considerations

```swift
// Mock implementation for testing
class AuthenticationServiceMock: AuthenticationServiceProtocol {
    func initiatePasswordlessOTPAuth(email: String) async throws {
        // Simulate OTP sent
    }
    
    func verifyOTPAndAuthenticate(
        email: String, 
        otpCode: String
    ) async throws -> AuthenticationResult {
        // Simulate successful auth
        return AuthenticationResult(
            accessToken: "mock_token",
            userId: "@user:matrix.myapp.com"
        )
    }
}
```

---

## Feature 2: Audio Call Button

### 2.1 Overview
Add audio call button alongside existing video call button. Same underlying Element Call infrastructure, different initial configuration.

### 2.2 Architecture
```
User taps "Audio Call" button
    ↓
RoomScreen detects call type
    ↓
ElementCallService.initiateCall(type: .audio)
    ↓
ElementCall opens with audio config:
    - camera: off
    - microphone: on
    - audio mode: earpiece
    ↓
Peer receives call indication
    ↓
Call established with audio configuration
```

### 2.3 iOS Implementation Steps

#### Step 1: Add Call Type Enum
**File:** `ketal/Sources/Services/ElementCall/ElementCallServiceConstants.swift` (or similar)

```swift
enum CallType {
    case audio
    case video
}

extension CallType {
    var cameraEnabled: Bool {
        switch self {
        case .audio: return false
        case .video: return true
        }
    }
    
    var audioMode: AudioMode {
        switch self {
        case .audio: return .earpiece
        case .video: return .speaker
        }
    }
}
```

#### Step 2: Update ElementCallService
**File:** `ketal/Sources/Services/ElementCall/ElementCallService.swift`

**Current method (likely):**
```swift
func startCall(roomID: String, callId: String) async throws {
    // Opens Element Call with video enabled
}
```

**New method:**
```swift
func startCall(
    roomID: String,
    callId: String,
    type: CallType = .video
) async throws {
    // Pass call type to Element Call
    // Element Call receives config and applies settings
}
```

**Configuration handling:**
```swift
private func buildCallConfig(type: CallType) -> ElementCallConfig {
    return ElementCallConfig(
        cameraEnabled: type.cameraEnabled,
        audioMode: type.audioMode,
        defaultDevice: type.defaultDevice  // earpiece vs speaker
    )
}
```

#### Step 3: Update RoomScreen UI
**File:** `ketal/Sources/Screens/RoomScreen/RoomScreen.swift`

**Current state (likely):**
```swift
HStack {
    Button(action: { startVideoCall() }) {
        Image("video-call")
    }
}
```

**New state:**
```swift
HStack {
    Button(action: { startAudioCall() }) {
        Image("audio-call")  // Handset/phone icon
            .font(.system(size: 20))
    }
    .help("Start audio call")
    
    Button(action: { startVideoCall() }) {
        Image("video-call")  // Video camera icon
            .font(.system(size: 20))
    }
    .help("Start video call")
}
```

#### Step 4: Implement Call Initiators
**File:** `ketal/Sources/Screens/RoomScreen/RoomScreenViewModel.swift`

```swift
func startAudioCall() {
    Task {
        do {
            let callId = UUID().uuidString
            try await elementCallService.startCall(
                roomID: roomID,
                callId: callId,
                type: .audio
            )
        } catch {
            errorSubject.send(error)
        }
    }
}

func startVideoCall() {
    Task {
        do {
            let callId = UUID().uuidString
            try await elementCallService.startCall(
                roomID: roomID,
                callId: callId,
                type: .video
            )
        } catch {
            errorSubject.send(error)
        }
    }
}
```

#### Step 5: UI State Management
**File:** `ketal/Sources/Screens/RoomScreen/RoomScreenViewState.swift`

```swift
struct RoomScreenViewState: BindableState {
    var bindings: RoomScreenViewStateBindings
    var isAudioCallAvailable: Bool = true
    var isVideoCallAvailable: Bool = true
}

struct RoomScreenViewStateBindings {
    var isCallInProgress: Bool = false
}
```

### 2.4 Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `ElementCallServiceConstants.swift` | Modify | Add CallType enum |
| `ElementCallService.swift` | Modify | Add type parameter |
| `RoomScreen.swift` | Modify | Add audio call button |
| `RoomScreenViewModel.swift` | Modify | Add audio call logic |
| `RoomScreenViewState.swift` | Modify | Add call type state |
| `Assets.xcassets` | Add | Audio call button icon |

### 2.5 Icon Requirements

**Audio Call Icon:**
- Handset/phone icon (filled or outline)
- Size: 20x20 to 24x24 points
- Match existing video call icon style
- Light and dark mode variants

**Suggested sources:**
- SF Symbols: `phone.fill` or `phone`
- Custom design matching app theme

### 2.6 Integration with Element Call

**Assumption:** Element Call already accepts configuration parameters

**If Element Call doesn't support config:**
- May need to pass settings via custom header
- Or use environment variables
- Or pre-configure audio mode before Element Call opens

---

## Feature 3: Username Selection (First Login)

### 3.1 Overview
After successful OTP authentication, first-time users are prompted to choose/verify a username before accessing the app.

### 3.2 Flow
```
User logs in via OTP
    ↓
System checks if user has username
    ↓
No username? → Show username selection screen
    ↓
User enters desired username
    ↓
Check availability via Synapse API
    ↓
Username available? → Confirm and set
    ↓
Continue to app
```

### 3.3 iOS Implementation

#### Step 1: Create New Screen
**File:** `ketal/Sources/Screens/UsernameSetupScreen/UsernameSetupScreen.swift` (new)

```swift
struct UsernameSetupScreen: View {
    @ObservedObject var viewModel: UsernameSetupScreenViewModel
    
    var body: some View {
        VStack {
            Text("Choose your username")
                .font(.title2)
                .fontWeight(.bold)
            
            TextField("Username", text: $viewModel.context.bindings.username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if let error = viewModel.context.usernameError {
                Text(error).foregroundColor(.red)
            }
            
            if viewModel.context.isCheckingAvailability {
                ProgressView()
            }
            
            Button("Continue") {
                viewModel.send(action: .confirmUsername)
            }
            .disabled(!viewModel.context.canConfirm)
        }
    }
}
```

#### Step 2: Create Coordinator
**File:** `ketal/Sources/Screens/UsernameSetupScreen/UsernameSetupScreenCoordinator.swift` (new)

```swift
@MainActor
final class UsernameSetupScreenCoordinator: CoordinatorProtocol {
    private var viewModel: UsernameSetupScreenViewModel
    
    private let usersService: UsersServiceProtocol
    
    init(parameters: UsernameSetupScreenCoordinatorParameters) {
        self.usersService = parameters.usersService
        self.viewModel = UsernameSetupScreenViewModel(
            usersService: usersService
        )
    }
    
    func start() -> AnyPublisher<CoordinatorAction, Never> {
        viewModel.actions
    }
    
    func toPresentable() -> AnyView {
        AnyView(UsernameSetupScreen(viewModel: viewModel))
    }
}
```

#### Step 3: Create ViewModel
**File:** `ketal/Sources/Screens/UsernameSetupScreen/UsernameSetupScreenViewModel.swift` (new)

```swift
@MainActor
final class UsernameSetupScreenViewModel: StateStoreViewModel<
    UsernameSetupViewState,
    UsernameSetupViewAction,
    UsernameSetupCoordinatorAction
> {
    private let usersService: UsersServiceProtocol
    private var availabilityCheckTask: Task<Void, Never>?
    
    init(usersService: UsersServiceProtocol) {
        self.usersService = usersService
        super.init(initialViewState: UsernameSetupViewState())
    }
    
    override func process(viewAction: UsernameSetupViewAction) {
        switch viewAction {
        case .usernameChanged(let username):
            state.bindings.username = username
            checkUsernameAvailability(username)
            
        case .confirmUsername:
            confirmUsername()
        }
    }
    
    private func checkUsernameAvailability(_ username: String) {
        availabilityCheckTask?.cancel()
        
        guard !username.isEmpty else {
            state.usernameError = nil
            state.canConfirm = false
            return
        }
        
        state.isCheckingAvailability = true
        
        availabilityCheckTask = Task {
            do {
                let isAvailable = try await usersService.isUsernameAvailable(username)
                state.isCheckingAvailability = false
                
                if isAvailable {
                    state.usernameError = nil
                    state.canConfirm = true
                } else {
                    state.usernameError = "Username taken"
                    state.canConfirm = false
                }
            } catch {
                state.isCheckingAvailability = false
                state.usernameError = "Error checking availability"
            }
        }
    }
    
    private func confirmUsername() {
        Task {
            do {
                try await usersService.setUsername(state.bindings.username)
                actionsSubject.send(.setupComplete)
            } catch {
                state.usernameError = "Failed to set username"
            }
        }
    }
}
```

#### Step 4: Create View Models
**File:** `ketal/Sources/Screens/UsernameSetupScreen/UsernameSetupScreenModels.swift` (new)

```swift
struct UsernameSetupViewState: BindableState {
    var bindings: UsernameSetupViewStateBindings
    var usernameError: String?
    var isCheckingAvailability: Bool = false
    var canConfirm: Bool = false
}

struct UsernameSetupViewStateBindings {
    var username: String = ""
}

enum UsernameSetupViewAction {
    case usernameChanged(String)
    case confirmUsername
}

enum UsernameSetupCoordinatorAction {
    case setupComplete
}
```

#### Step 5: Integrate into Auth Flow
**File:** `ketal/Sources/FlowCoordinators/AuthenticationFlowCoordinator.swift`

**Current flow (likely):**
```
LoginScreen → Home
```

**New flow:**
```
LoginScreen → UsernameSetupScreen → Home
```

```swift
func handleAuthenticationResult(_ result: AuthenticationResult) {
    if result.needsUsernameSetup {
        // Show username screen
        stateMachine.setUserSession(result.userSession)
        stateMachine.setState(.usernameSetup)
    } else {
        // Skip username screen
        stateMachine.setUserSession(result.userSession)
        stateMachine.setState(.room)
    }
}
```

### 3.4 Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `UsernameSetupScreen.swift` | Create | Username input UI |
| `UsernameSetupScreenCoordinator.swift` | Create | Screen coordinator |
| `UsernameSetupScreenViewModel.swift` | Create | Business logic |
| `UsernameSetupScreenModels.swift` | Create | State/action enums |
| `UsersService.swift` | Modify/Create | Username availability API |
| `AuthenticationFlowCoordinator.swift` | Modify | Add username setup state |

---

## Feature 4: Homeserver Discovery via .well-known

### 4.1 Overview
Instead of hardcoding homeserver URL, fetch it from `.well-known/matrix/client` and `.well-known/matrix/server` endpoints.

### 4.2 Well-Known Endpoints

**Endpoint 1:** `https://myapp.com/.well-known/matrix/client`
```json
{
  "m.homeserver": {
    "base_url": "https://matrix.myapp.com"
  },
  "m.identity_server": {
    "base_url": "https://identity.myapp.com"
  },
  "org.matrix.msc3575.proxy": {
    "url": "https://matrix.myapp.com"
  }
}
```

**Endpoint 2:** `https://matrix.myapp.com/.well-known/matrix/server`
```json
{
  "m.server": "matrix.myapp.com:443"
}
```

### 4.3 iOS Implementation

#### Step 1: Create Well-Known Service
**File:** `ketal/Sources/Services/Client/WellKnownService.swift` (new)

```swift
protocol WellKnownServiceProtocol {
    func discoverHomeserver(domain: String) async throws -> HomeserverInfo
}

final class WellKnownService: WellKnownServiceProtocol {
    func discoverHomeserver(domain: String) async throws -> HomeserverInfo {
        // 1. Try /.well-known/matrix/client first
        let clientUrl = URL(string: "https://\(domain)/.well-known/matrix/client")!
        
        let (data, _) = try await URLSession.shared.data(from: clientUrl)
        let response = try JSONDecoder().decode(
            ClientWellKnownResponse.self,
            from: data
        )
        
        return HomeserverInfo(
            baseUrl: response.homeserver.baseUrl,
            identityServerUrl: response.identityServer?.baseUrl
        )
    }
}

struct ClientWellKnownResponse: Codable {
    struct HomeserverInfo: Codable {
        let baseUrl: String
        enum CodingKeys: String, CodingKey {
            case baseUrl = "base_url"
        }
    }
    
    let homeserver: HomeserverInfo
    let identityServer: HomeserverInfo?
    
    enum CodingKeys: String, CodingKey {
        case homeserver = "m.homeserver"
        case identityServer = "m.identity_server"
    }
}

struct HomeserverInfo {
    let baseUrl: String
    let identityServerUrl: String?
}
```

#### Step 2: Update AppSettings
**File:** `ketal/Sources/Application/AppSettings.swift`

**Before:**
```swift
class AppSettings {
    let homeserverUrl = URL(string: "https://matrix.myapp.com")!
}
```

**After:**
```swift
class AppSettings {
    var homeserverUrl: URL? = nil  // Dynamically discovered
    let appDomain = "myapp.com"  // Domain to discover from
}
```

#### Step 3: Update Client Initialization
**File:** `ketal/Sources/Services/Client/ClientProxy.swift` (or similar)

```swift
class ClientProxy {
    static func initializeClient(domain: String) async throws -> ClientProxy {
        // 1. Discover homeserver
        let wellKnownService = WellKnownService()
        let homserverInfo = try await wellKnownService.discoverHomeserver(domain: domain)
        
        // 2. Initialize Matrix client with discovered URL
        let client = try await MatrixClient(
            baseUrl: homserverInfo.baseUrl
        )
        
        return ClientProxy(client: client)
    }
}
```

#### Step 4: Update Login Flow
**File:** `ketal/Sources/Services/Authentication/AuthenticationService.swift`

```swift
func initializeAuth(domain: String) async throws {
    // Discover homeserver from domain
    let homserverInfo = try await wellKnownService.discoverHomeserver(domain: domain)
    
    // Store for later use
    self.homeserverBaseUrl = homserverInfo.baseUrl
    
    // Initialize client
    self.client = try await ClientProxy.initializeClient(baseUrl: homserverInfo.baseUrl)
}
```

### 4.4 Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `WellKnownService.swift` | Create | .well-known discovery |
| `WellKnownServiceProtocol.swift` | Create | Service protocol |
| `AppSettings.swift` | Modify | Use discovered URLs |
| `ClientProxy.swift` | Modify | Initialize with discovered URL |
| `AuthenticationService.swift` | Modify | Call discovery before auth |

---

## Integration Checklist

### Phase 2 Completion Checklist

When all features are implemented, verify:

**Email OTP Authentication:**
- [ ] User can enter email
- [ ] OTP is received via email
- [ ] User can enter OTP
- [ ] Authentication successful
- [ ] Matrix token obtained
- [ ] User can proceed to app

**Audio Call:**
- [ ] Audio call button visible in room
- [ ] Button opens Element Call
- [ ] Camera is off during audio call
- [ ] Microphone is on
- [ ] Earpiece mode enabled
- [ ] Call can be established

**Username Selection:**
- [ ] First-time users see username screen
- [ ] Username availability checked
- [ ] Valid usernames accepted
- [ ] Invalid usernames rejected
- [ ] Username persisted in Synapse

**Homeserver Discovery:**
- [ ] App discovers homeserver from domain
- [ ] .well-known endpoints called
- [ ] Correct homeserver URL obtained
- [ ] Client initialized correctly

**No Regressions:**
- [ ] Existing video calls still work
- [ ] Message sending works
- [ ] E2EE still functional
- [ ] Room navigation works
- [ ] Settings still accessible

---

## Testing Strategy

### Unit Tests
- OTP validation logic
- Username validation logic
- Well-known response parsing
- Error handling for failed API calls

### Integration Tests
- Full OTP auth flow
- Audio call initiation
- Username setup flow
- Homeserver discovery

### Manual Testing
- End-to-end OTP signup
- OTP resend functionality
- Audio call on various networks
- Username conflicts handling
- Homeserver discovery with invalid domain

---

## Estimated Effort

| Feature | Effort | Notes |
|---------|--------|-------|
| Email OTP Auth | 3-4 days | Depends on Keycloak integration |
| Audio Call Button | 1-2 days | Simple configuration change |
| Username Selection | 1-2 days | New screen + validation |
| .well-known Discovery | 1 day | Network call + parsing |
| Testing & Polish | 2-3 days | Bug fixes and refinement |
| **Total** | **8-12 days** | With blockers: 2-3 weeks |

---

## Next Steps

1. **Confirm Server Stack Design**
   - Keycloak OTP configuration
   - MAS integration details
   - Email provider (Resend.io)

2. **Finalize UI Design**
   - Review Figma for OTP flow
   - Audio call button placement
   - Username setup screen

3. **Begin Implementation**
   - Start with server stack setup
   - Parallel: Begin iOS auth integration
   - Integration testing once both ready

---

**Document Status**: Complete technical roadmap  
**Date**: 2026-01-22  
**Phase**: Phase 2 Planning (iOS Features)
