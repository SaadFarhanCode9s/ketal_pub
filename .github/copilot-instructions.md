# ketal iOS - AI Agent Instructions
## git config --global alias.sync '!git fetch upstream && git merge upstream/main && git push origin main'
## Project Overview
ketal iOS is a next-generation Matrix client built with Swift 6.1+ targeting iOS 18.2+. It uses the **Matrix Rust SDK** (via FFI/SwiftPackage) as the backend and applies the **MVVM-Coordinator pattern** with **reactive state management** via Combine.

**Key Architecture**: Coordinator → Screen (View) ↔ ViewModel → Services → Rust SDK
- Project generation via **XcodeGen** from YAML configs
- SwiftUI-based UI with reactive state binding
- Comprehensive mocking for testing
- Localization via Localazy (shared with Element X Android)

## Getting Started & Development Workflow

### Initial Setup
```bash
swift run tools setup-project  # Install dependencies, git hooks, run xcodegen
swift run tools build-sdk      # Optional: build Matrix Rust SDK locally for development
```

### Generating Project
- **Never edit `.pbxproj` directly**—use `project.yml`, `app.yml`, and target-specific `target.yml` files
- Run `swift run tools setup-project` or xcodegen after YAML changes
- Post-gen script automatically runs; verify with `file_search` for `.pbxproj` mtime

### Building & Testing
```bash
# Build via Xcode scheme "ketal" (includes main app + unit/UI tests)
xcodebuild -scheme "ketal" -configuration Debug
# Unit tests: UnitTests/ target
# UI/Preview tests: UITests/, PreviewTests/ targets
# Snapshot tests use Git LFS (auto-installed)
```

## Architecture Patterns

### 1. Coordinator Pattern
**Every screen** follows: `[Name]ScreenCoordinator` + `[Name]ScreenViewModel` + `[Name]Screen` (SwiftUI View)

Example structure (e.g., `AppLockSetupPINScreen/`):
```
AppLockSetupPINScreenCoordinator.swift  # Handles navigation & lifecycle
AppLockSetupPINScreenViewModel.swift    # State & business logic
AppLockSetupPINScreen.swift             # SwiftUI View using viewModel.context
AppLockSetupPINScreenModels.swift       # ViewState, ViewAction, CoordinatorAction enums
```

**Coordinator responsibilities**:
- Initialize ViewModel with dependencies
- Listen to `viewModel.actions` publisher
- Send navigation actions via `actionsSubject`
- Implement `CoordinatorProtocol` with `start()`, `toPresentable()`
- Use `@MainActor` annotation

**Coordinator Parameters struct**: Groups all dependencies (services, callbacks)
```swift
struct AppLockSetupPINScreenCoordinatorParameters {
    let initialMode: AppLockSetupPINScreenInitialMode
    let isMandatory: Bool
    let appLockService: AppLockServiceProtocol
}
```

### 2. ViewModel & State Management
Use **StateStoreViewModel** or **StateStoreViewModelV2** base classes:
- `ViewState`: BindableState with `bindings` struct for UI-bound properties
- `ViewAction`: User interactions (button taps, input changes)
- `ViewModelAction`: Internal events sent to parent Coordinator via `actionsPublisher`

Example:
```swift
struct TimelineViewState: BindableState {
    var bindings: TimelineViewStateBindings  // UI-reactive properties
    var roomNameForIDResolver: (@MainActor (String) -> String?)?
}

struct TimelineViewStateBindings {
    var isScrolledToBottom = true
    var alertInfo: AlertInfo<TimelineAlertInfoType>?
}

enum TimelineViewAction {
    case scrollToBottom
    case sendMessage(String)
}
```

**Binding pattern**: Use `@dynamicMemberLookup` for computed bindings (see `LabsScreenViewStateBindings`).

### 3. Flow Coordinators & State Machines
Multi-screen flows use **SwiftState** for explicit state transitions.

Key flow coordinators:
- `AppCoordinator`: Top-level app lifecycle
- `AuthenticationFlowCoordinator`: Login/register/soft-logout
- `UserSessionFlowCoordinator`: Main app flow after auth
- `ChatsFlowCoordinator`: Room list & chat navigation
- `RoomFlowCoordinator`: Single room + details/members/threads
- `AppLockFlowCoordinator`: Biometric/PIN security

State machines are created via `StateMachineFactory` (or `PublishedStateMachineFactory` for testing).

Example state enum:
```swift
enum State: StateType {
    case initial
    case joinRoomScreen
    case room
    case thread(threadRootEventID: String, previousState: State)
    case roomDetails(isRoot: Bool)
}
```

### 4. Service Layer
Services handle domain logic and Rust SDK interaction. Key services:
- **ClientProxy**: Matrix client operations
- **UserSession**: Authenticated user state
- **RoomProxy**: Single room operations
- **AppLockService**: PIN/biometric security
- **Analytics**: Event tracking
- **NotificationManager**: Push notifications
- **ComposerDraftService**: Message draft persistence

All services expose **protocols** for mocking in tests.

### 5. Dependency Injection
- **Constructor injection** for screen/service dependencies
- **ServiceLocator** singleton for app-level services (analytics, settings, userIndicator)
- **NavigationStackCoordinator** for stack-based screen transitions

## Testing Strategy

### Test Organization
- `UnitTests/Sources/Unit/`: ViewModel & logic tests
- `UITests/Sources/`: User flow tests with snapshot assertions
- `PreviewTests/Sources/`: SwiftUI Preview rendering tests
- `AccessibilityTests/Sources/`: A11y validation
- `IntegrationTests/Sources/`: End-to-end flows

### Mocking Patterns
Create `[Name]Mock` classes implementing protocol:
```swift
class AppLockServiceMock: AppLockServiceProtocol {
    let configuration: AppLockServiceMockConfiguration
    init(_ configuration: AppLockServiceMockConfiguration) {
        self.configuration = configuration
    }
}
```

Use mocks in test coordinators (e.g., `UITestsAppCoordinator`) to pre-configure flows.

### Snapshot Testing
- `UITests` and `PreviewTests` record snapshots in `__Snapshots__/` directories
- Git LFS stores image files
- Modify UI → snapshot fails → review & update via test UI

## Code Conventions & Patterns

### Swift & SwiftUI Standards
- **@MainActor** for UI code (coordinators, viewmodels, SwiftUI views)
- **Combine** for reactive streams (no SwiftAsync alternatives)
- Protocol-first design; use `XProtocol` naming for protocols
- Computed properties over imperative getters
- `CombineLatest` / `MergeMany` for multi-stream coordination

### File Naming
- Coordinator: `[Name]Coordinator.swift`
- ViewModel: `[Name]ViewModel.swift`
- View: `[Name]Screen.swift`
- Models: `[Name]Models.swift` (ViewState, ViewAction, CoordinatorAction, CoordinatorParameters)
- Service: `[ServiceName]Service.swift` or `[ServiceName]ServiceProtocol.swift`

### Localization
- **Never edit** `Localizable.strings`, `Localizable.stringsdict`, `InfoPlist.strings` directly
- Add new strings to `Untranslated.strings`/`Untranslated.stringsdict`
- Team transfers to Localazy; translations managed cross-platform with Element X Android

### Logging
Use `MXLog.info()`, `MXLog.error()` (central logging utility) in coordinators on state transitions and errors.

## Key Dependencies & Integration Points

### Matrix Rust SDK Integration
- **Package**: `matrix-rust-components-swift` (exactVersion: 26.1.13)
- **Access**: Via `ClientProxy` (FFI wrapper)
- **Local dev**: `swift run tools build-sdk` clones & builds locally
- **Fallback**: Uncommenting path-based dependencies in `project.yml` for linked development

### External Packages
- **Compound**: Design system (UIComponent library)
- **AnalyticsEvents**: Shared analytics event definitions
- **WysiwygComposer**: Rich text editor
- **EmbeddedElementCall**: VoIP integration
- **SwiftOGG**: Audio codec support
- **Emojibase**: Emoji data

### Network & Debugging
Set `HTTPS_PROXY` env var in ketal scheme for proxy debugging (e.g., mitmproxy on localhost:8080).

## CI/CD & Code Quality

### Continuous Integration
- **Tool**: Fastlane (see `fastlane/Fastfile`)
- **Checks**: SwiftLint, SwiftFormat, Danger, SonarCloud
- **Coverage**: Codecov reports on every PR
- **Strings**: Localazy integration (auto-sync on merge)

### Code Style Enforcement
- **SwiftLint**: Rules in `.swiftlint.yml` (compile-time checks)
- **SwiftFormat**: Config in `.swiftformat` (formatting)
- **SonarCloud**: Quality gates & complexity analysis
- **Apple Swift Conventions**: https://swift.org/documentation/api-design-guidelines/

### Required PR Labels
Use `pr-` labels for changelog categorization (see `.github/release.yml`). Auto-credit to GitHub username.

## Common Development Tasks

### Adding a New Screen
1. Use template: `swift run tools create-screen MyScreenName`
2. Generates: Coordinator, ViewModel, Models, View scaffolds
3. Implement ViewModel logic with state transitions
4. Create View with `viewModel.context` binding
5. Register in parent FlowCoordinator
6. Add ViewModel test + UI test

### Debugging State Machines
- `PublishedStateMachineFactory` in tests publishes state transitions for assertions
- Use `stateMachine.state` for current state inspection
- Log state transitions with `MXLog.info()`

### Working with Rust SDK
- **ClientProxy pattern**: Wraps async Rust SDK calls, exposes reactive publishers
- **RoomProxy**: Room-level operations (send message, fetch timeline)
- **LocalDeveloped SDK**: Modify SDK repo, run `swift run tools build-sdk --path ../matrix-rust-sdk`

## Project Structure Reference
```
ElementX/Sources/
├── Application/        # AppDelegate, AppCoordinator, ServiceLocator
├── Services/           # Domain logic, Rust SDK wrappers, platform services
├── FlowCoordinators/   # Multi-screen state machine coordinators
├── Screens/            # Individual screen coordinators/viewmodels/views
├── Other/              # Utilities, extensions, ViewModel base classes
└── Generated/          # Code-gen output (Sourcery, Localazy strings)

Tests:
├── UnitTests/          # ViewModel, service logic tests
├── UITests/            # User flow + snapshot tests
├── PreviewTests/       # SwiftUI Preview rendering tests
└── AccessibilityTests/ # A11y validation flows
```

## Useful Commands & Links
- **Xcode scheme**: "ketal" (main + tests)
- **Tests in Xcode**: Cmd+U or via schemes
- **Fastlane options**: `bundle exec fastlane --help` or `bundle exec fastlane list`
- **Localazy docs**: https://localazy.com/p/element
- **Matrix.org**: https://matrix.org/
- **Team chat**: #element-x-ios:matrix.org
