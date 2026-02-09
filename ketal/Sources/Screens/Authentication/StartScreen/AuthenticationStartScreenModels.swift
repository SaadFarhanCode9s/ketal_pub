//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import UIKit

// MARK: - Coordinator

enum AuthenticationStartScreenCoordinatorAction {
    case loginWithQR
    case login
    case register
    case reportProblem
    case loginDirectlyWithOIDC(data: OIDCAuthorizationDataProxy, window: UIWindow)
    case loginDirectlyWithPassword(loginHint: String?)
}

/// Replace your existing AuthenticationStartScreenViewModelAction with this:
enum AuthenticationStartScreenViewModelAction: Equatable {
    case loginWithQR
    case login
    case register
    case reportProblem
    case requestOIDCEmail
    case loginDirectlyWithPassword(loginHint: String?)
    case loginDirectlyWithOIDC(data: OIDCAuthorizationDataProxy)

    static func == (lhs: AuthenticationStartScreenViewModelAction, rhs: AuthenticationStartScreenViewModelAction) -> Bool {
        switch (lhs, rhs) {
        case (.loginWithQR, .loginWithQR), (.login, .login), (.register, .register),
             (.reportProblem, .reportProblem), (.requestOIDCEmail, .requestOIDCEmail):
            return true
        case (.loginDirectlyWithPassword(let lhsHint), .loginDirectlyWithPassword(let rhsHint)):
            return lhsHint == rhsHint
        case (.loginDirectlyWithOIDC, .loginDirectlyWithOIDC):
            return true // FIX: Removed the function call that was causing the crash
        default:
            return false
        }
    }
}

// enum AuthenticationStartScreenViewModelAction: Equatable {
//     static func == (lhs: AuthenticationStartScreenViewModelAction, rhs: AuthenticationStartScreenViewModelAction) -> Bool {
//         switch (lhs, rhs) {
//         case (.loginWithQR, .loginWithQR):
//             return true
//         case (.login, .login):
//             return true
//         case (.register, .register):
//             return true
//         case (.reportProblem, .reportProblem):
//             return true
//         case (.requestOIDCEmail, .requestOIDCEmail):
//             return true
//         case (.loginDirectlyWithPassword(let lhsLoginHint), .loginDirectlyWithPassword(let rhsLoginHint)):
//             return lhsLoginHint == rhsLoginHint
//         default:
//             return false
//         }
//     }

//     case loginWithQR
//     case login
//     case register
//     case reportProblem

//     case requestOIDCEmail
//     case loginDirectlyWithPassword(loginHint: String?)
// }

struct AuthenticationStartScreenViewState: BindableState {
    /// The presentation anchor used for OIDC authentication.
    var window: UIWindow?

    let serverName: String?
    let showCreateAccountButton: Bool
    let showQRCodeLoginButton: Bool

    let hideBrandChrome: Bool

    var bindings = AuthenticationStartScreenViewStateBindings()

    var loginButtonTitle: String {
        if let serverName {
            L10n.screenOnboardingSignInTo(serverName)
        } else if showQRCodeLoginButton {
            L10n.screenOnboardingSignInManually
        } else {
            L10n.actionContinue
        }
    }
}

struct AuthenticationStartScreenViewStateBindings {
    var alertInfo: AlertInfo<AuthenticationStartScreenAlertType>?
}

enum AuthenticationStartScreenAlertType {
    case genericError
}

enum AuthenticationStartScreenViewAction {
    /// Updates the window used as the OIDC presentation anchor.
    case updateWindow(UIWindow)

    case loginWithQR
    case login
    case register
    case reportProblem
}
