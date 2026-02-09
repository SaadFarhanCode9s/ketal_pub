//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// The screen shown at the beginning of the onboarding flow.
struct AuthenticationStartScreen: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let context: AuthenticationStartScreenViewModel.Context

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                    .frame(height: UIConstants.spacerHeight(in: geometry))

                content
                    .frame(width: geometry.size.width)
                    .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.hidden)

                buttons
                    .frame(width: geometry.size.width)
                    .padding(.bottom, UIConstants.actionButtonBottomPadding)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 20)
                    .padding(.top, 0)

                Spacer()
                    .frame(height: UIConstants.spacerHeight(in: geometry))
            }
            .frame(maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                versionText
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    .onTapGesture(count: 7) {
                        context.send(viewAction: .reportProblem)
                    }
                    .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.appVersion)
            }
        }
        .navigationBarHidden(true)
        .background {
            AuthenticationStartScreenBackgroundImage()
        }
        .introspect(.window, on: .supportedVersions) { window in
            context.send(viewAction: .updateWindow(window))
        }
    }

    var content: some View {
        VStack(spacing: 0) {
            if verticalSizeClass == .regular {
                Image(asset: Asset.Images.splash)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 100)
            }
        }
        .padding(.bottom)
        .padding(.horizontal, 16)
        .readableFrame()
    }

    /// The main action buttons.
    var buttons: some View {
        VStack(spacing: 16) {
            //        if context.viewState.showQRCodeLoginButton {
            //          Button { context.send(viewAction: .loginWithQR) } label: {
            //            Label(L10n.screenOnboardingSignInWithQrCode, icon: \.qrCode)
            //      }
            //    .buttonStyle(.compound(.primary))
            //  .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.signInWithQr)
            // }

            Button { context.send(viewAction: .login) } label: {
                Text("Sign in")
            }
            .buttonStyle(.compound(.primary))
            .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.signIn)
            .shadow(color: Color.gray.opacity(0.9), radius: 10, x: 0, y: 0)
            .frame(maxWidth: 200)

            if context.viewState.showCreateAccountButton {
                Button { context.send(viewAction: .register) } label: {
                    Text(L10n.screenCreateAccountTitle)
                }
                .buttonStyle(.compound(.tertiary))
            }
        }
        .padding(.horizontal, verticalSizeClass == .compact ? 128 : 24)
        .readableFrame()
    }

    var versionText: Text {
        // Let's not deal with snapshotting a changing version string.
        let shortVersionString = ProcessInfo.isRunningTests ? "0.0.0" : InfoPlistReader.main.bundleShortVersionString
        return Text(L10n.screenOnboardingAppVersion(shortVersionString))
    }
}

// MARK: - Previews

struct AuthenticationStartScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let provisionedViewModel = makeViewModel(provisionedServerName: "example.com")

    static var previews: some View {
        AuthenticationStartScreen(context: viewModel.context)
            .previewDisplayName("Default")
        AuthenticationStartScreen(context: provisionedViewModel.context)
            .previewDisplayName("Provisioned")
    }

    static func makeViewModel(provisionedServerName: String? = nil) -> AuthenticationStartScreenViewModel {
        AuthenticationStartScreenViewModel(authenticationService: AuthenticationService.mock,
                                           provisioningParameters: provisionedServerName.map { .init(accountProvider: $0, loginHint: nil) },
                                           isBugReportServiceEnabled: true,
                                           appSettings: ServiceLocator.shared.settings,
                                           userIndicatorController: UserIndicatorControllerMock())
    }
}
