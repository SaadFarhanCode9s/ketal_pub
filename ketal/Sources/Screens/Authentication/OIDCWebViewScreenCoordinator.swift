//
// Copyright 2026 Ketal Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
//

import Combine
import SwiftUI

struct OIDCWebViewScreenCoordinatorParameters {
    let authorizationURL: URL
    let oidcData: OIDCAuthorizationDataProxy
    let authenticationService: AuthenticationServiceProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum OIDCWebViewScreenCoordinatorResult {
    case success(UserSessionProtocol)
    case cancel
}

@MainActor
class OIDCWebViewScreenCoordinator: CoordinatorProtocol {
    private let parameters: OIDCWebViewScreenCoordinatorParameters
    private var callback: ((OIDCWebViewScreenCoordinatorResult) -> Void)?

    init(parameters: OIDCWebViewScreenCoordinatorParameters) {
        self.parameters = parameters
    }

    func start() {
        // No initial action needed
    }

    func stop() {
        callback = nil
    }

    func toPresentable() -> AnyView {
        // Extract the redirect URI from the authorization URL parameters to ensure we match exactly what the server expects
        let components = URLComponents(url: parameters.authorizationURL, resolvingAgainstBaseURL: false)
        let redirectURI = components?.queryItems?.first(where: { $0.name == "redirect_uri" })?.value ?? "ketal://oidc"

        return AnyView(OIDCWebViewScreen(authorizationURL: parameters.authorizationURL,
                                         redirectURI: redirectURI,
                                         onSuccess: { [weak self] callbackURL in
                                             self?.handleCallback(callbackURL)
                                         },
                                         onCancel: { [weak self] in
                                             self?.handleCancellation()
                                         }))
    }

    func callback(_ callback: @escaping (OIDCWebViewScreenCoordinatorResult) -> Void) {
        self.callback = callback
    }

    // MARK: - Private

    private func handleCallback(_ callbackURL: URL) {
        Task {
            await processCallback(callbackURL)
        }
    }

    private func processCallback(_ callbackURL: URL) async {
        // Show loading indicator
        startLoading()
        defer { stopLoading() }

        MXLog.info("[OIDC WebView Coordinator] Processing callback URL")

        switch await parameters.authenticationService.loginWithOIDCCallback(callbackURL) {
        case .success(let userSession):
            MXLog.info("[OIDC WebView Coordinator] Successfully logged in")
            callback?(.success(userSession))

        case .failure(.oidcError(.userCancellation)):
            MXLog.info("[OIDC WebView Coordinator] User cancelled login")
            callback?(.cancel)

        case .failure(let error):
            MXLog.error("[OIDC WebView Coordinator] Login failed: \(error)")
            parameters.userIndicatorController.alertInfo = AlertInfo(id: .init(),
                                                                     title: "Authentication Failed",
                                                                     message: "Unable to complete login. Please try again.")
            callback?(.cancel)
        }
    }

    private func handleCancellation() {
        Task {
            MXLog.info("[OIDC WebView Coordinator] User cancelled authentication")
            await parameters.authenticationService.abortOIDCLogin(data: parameters.oidcData)
            callback?(.cancel)
        }
    }

    // MARK: - Loading Indicator

    private static let loadingIndicatorID = "\(OIDCWebViewScreenCoordinator.self)-Loading"

    private func startLoading() {
        parameters.userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorID,
                                                                         type: .modal,
                                                                         title: L10n.commonLoading,
                                                                         persistent: true))
    }

    private func stopLoading() {
        parameters.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorID)
    }
}
