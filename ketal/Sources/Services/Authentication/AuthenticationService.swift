//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

class AuthenticationService: AuthenticationServiceProtocol {
    private var client: ClientProtocol?
    private var sessionDirectories: SessionDirectories
    private let passphrase: String

    private let clientFactory: AuthenticationClientFactoryProtocol
    private let userSessionStore: UserSessionStoreProtocol
    private let appSettings: AppSettings
    private let appHooks: AppHooks

    private let homeserverSubject: CurrentValueSubject<LoginHomeserver, Never>
    var homeserver: CurrentValuePublisher<LoginHomeserver, Never> {
        homeserverSubject.asCurrentValuePublisher()
    }

    private(set) var flow: AuthenticationFlow

    init(userSessionStore: UserSessionStoreProtocol,
         encryptionKeyProvider: EncryptionKeyProviderProtocol,
         clientFactory: AuthenticationClientFactoryProtocol = AuthenticationClientFactory(),
         appSettings: AppSettings,
         appHooks: AppHooks) {
        sessionDirectories = .init()
        passphrase = encryptionKeyProvider.generateKey().base64EncodedString()
        self.clientFactory = clientFactory
        self.userSessionStore = userSessionStore
        self.appSettings = appSettings
        self.appHooks = appHooks

        // When updating these, don't forget to update the reset method too.
        homeserverSubject = .init(LoginHomeserver(address: appSettings.accountProviders[0], loginMode: .unknown))
        flow = .login
    }

    // MARK: - Public

    func configure(for homeserverAddress: String, flow: AuthenticationFlow) async -> Result<Void, AuthenticationServiceError> {
        do {
            var homeserver = LoginHomeserver(address: homeserverAddress, loginMode: .unknown)

            let client = try await makeClient(homeserverAddress: homeserverAddress)
            let loginDetails = await client.homeserverLoginDetails()

            homeserver.loginMode = if loginDetails.supportsOidcLogin() {
                .oidc(supportsCreatePrompt: loginDetails.supportedOidcPrompts().contains(.create))
            } else if loginDetails.supportsPasswordLogin() {
                .password
            } else {
                .unsupported
            }

            if flow == .login, homeserver.loginMode == .unsupported {
                return .failure(.loginNotSupported)
            }
            if flow == .register, !homeserver.loginMode.supportsOIDCFlow {
                return .failure(.registrationNotSupported)
            }

            self.client = client
            self.flow = flow
            homeserverSubject.send(homeserver)
            return .success(())
        } catch ClientBuildError.WellKnownDeserializationError(let error) {
            MXLog.error("The user entered a server with an invalid well-known file: \(error)")
            return .failure(.invalidWellKnown(error))
        } catch ClientBuildError.SlidingSyncVersion(let error) {
            MXLog.info("User entered a homeserver that isn't configured for sliding sync: \(error)")
            return .failure(.slidingSyncNotAvailable)
        } catch RemoteSettingsError.elementProRequired(let serverName) {
            return .failure(.elementProRequired(serverName: serverName))
        } catch {
            MXLog.error("Failed configuring a server: \(error)")
            return .failure(.invalidHomeserverAddress)
        }
    }

    func urlForOIDCLogin(loginHint: String?) async -> Result<OIDCAuthorizationDataProxy, AuthenticationServiceError> {
        guard let client else { return .failure(.oidcError(.urlFailure)) }

        func attemptLogin(config: OidcConfiguration) async throws -> OIDCAuthorizationDataProxy {
            MXLog.info("[OIDC DEBUG] Attempting login with configuration")
            let oidcData = try await client.urlForOidc(oidcConfiguration: config,
                                                       prompt: nil,
                                                       loginHint: loginHint,
                                                       deviceId: nil,
                                                       additionalScopes: nil)
            MXLog.info("[OIDC DEBUG] Authorization data retrieved successfully")
            return OIDCAuthorizationDataProxy(underlyingData: oidcData)
        }

        // PRIORITY 1: Attempt well-known discovery first (zero-hardcoding approach)
        // Extract domain from the homeserver address (could be domain or full URL)
        let homeserverAddress = homeserver.value.address
        let domain = extractDomain(from: homeserverAddress)

        // Fetch configuration once to avoid redundant network calls
        let wellKnownConfig = await fetchOIDCConfigFromWellKnown(domain: domain)

        if let oidcConfig = wellKnownConfig {
            let issuer = oidcConfig.issuer
            // This will now be "01JTFZH15V95D7JNP5CJJHJH46" from your well-known file
            let discoveredClientId = oidcConfig.clientId

            MXLog.info("[OIDC DEBUG] Discovered OIDC configuration: issuer=\(issuer), clientId=\(discoveredClientId ?? "nil")")

            var staticRegistrations: [String: String] = [:]
            if let cid = discoveredClientId {
                staticRegistrations[issuer] = cid
                MXLog.info("[OIDC DEBUG] Using client ID from well-known: \(cid) for issuer: \(issuer)")
            } else {
                MXLog.warning("[OIDC DEBUG] No client_id found in well-known! MAS may require Dynamic Client Registration.")
            }

            let discoveredConfig = OIDCConfiguration(clientName: "ketal",
                                                     redirectURI: "ketal://oidc",
                                                     clientURI: appSettings.websiteURL,
                                                     logoURI: appSettings.logoURL,
                                                     tosURI: appSettings.acceptableUseURL,
                                                     policyURI: appSettings.privacyURL,
                                                     staticRegistrations: staticRegistrations).rustValue

            MXLog.info("[OIDC DEBUG] Config - redirectURI: ketal://oidc, clientName: ketal")
            MXLog.info("[OIDC DEBUG] staticRegistrations: \(staticRegistrations)")

            do {
                let result = try await attemptLogin(config: discoveredConfig)
                return .success(result)
            } catch {
                let nsError = error as NSError
                MXLog.error("[OIDC DEBUG] Login attempt FAILED")
                MXLog.error("[OIDC DEBUG] Error domain: \(nsError.domain), code: \(nsError.code)")
                MXLog.error("[OIDC DEBUG] Error userInfo: \(nsError.userInfo)")
                MXLog.error("[OIDC DEBUG] Error description: \(error.localizedDescription)")
                if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] {
                    MXLog.error("[OIDC DEBUG] Underlying error: \(underlyingError)")
                }
                return .failure(.oidcError(.notSupported))
            }
        }

        else {
            let issuerFound = false // config is nil, so issuer is missing (or fetch failed)
            let clientIdFound = false
            MXLog.info("Well-known discovery incomplete: issuer=\(issuerFound ? "found" : "missing"), clientId=\(clientIdFound ? "found" : "missing")")
        }

        // PRIORITY 2: Fallback to static configuration from AppSettings
        do {
            let config = appSettings.oidcConfiguration.rustValue
            let result = try await attemptLogin(config: config)
            return .success(result)
        } catch {
            MXLog.error("Failed to get URL for OIDC login with static config: \(error)")

            // If we found issuer but not client ID (logic reused from cached fetch)
            if let config = wellKnownConfig, config.clientId == nil {
                MXLog.error("OIDC issuer found in well-known but client_id is missing. Ensure .well-known/matrix/client includes 'client_id' in the authentication block.")
            }

            return .failure(.oidcError(.urlFailure))
        }
    }

    /// Extract domain from homeserver address (handles both domain and URL formats)
    private func extractDomain(from address: String) -> String {
        // Remove protocol if present
        var domain = address
        if let url = URL(string: address), let host = url.host {
            return host
        }
        // Remove protocol manually if URL parsing failed
        if domain.contains("://") {
            domain = String(domain.split(separator: "/")[2])
        }
        // Remove port if present
        if let colonIndex = domain.firstIndex(of: ":") {
            domain = String(domain[..<colonIndex])
        }
        // Remove path if present
        if let slashIndex = domain.firstIndex(of: "/") {
            domain = String(domain[..<slashIndex])
        }
        return domain
    }

    /// Manual .well-known discovery helper
    private func fetchOIDCConfigFromWellKnown(domain: String) async -> (issuer: String, clientId: String?)? {
        let urlString = "https://\(domain)/.well-known/matrix/client"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                func extractConfig(from authBlock: [String: Any]) -> (String, String?)? {
                    guard let issuer = authBlock["issuer"] as? String else { return nil }
                    let clientId = authBlock["client_id"] as? String

                    return (issuer, clientId)
                }

                // Priority 1: Stable Matrix Spec
                if let authKey = json["m.authentication"] as? [String: Any],
                   let config = extractConfig(from: authKey) {
                    return config
                }

                // Priority 2: Unstable MSC2965 (Native OIDC)
                if let authKey = json["org.matrix.msc2965.authentication"] as? [String: Any],
                   let config = extractConfig(from: authKey) {
                    return config
                }
            }
        } catch {
            MXLog.error("Discovery failed for \(domain): \(error)")
        }
        return nil
    }

    func abortOIDCLogin(data: OIDCAuthorizationDataProxy) async {
        guard let client else { return }
        MXLog.info("Aborting OIDC login.")
        await client.abortOidcAuth(authorizationData: data.underlyingData)
    }

    func loginWithOIDCCallback(_ callbackURL: URL) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        guard let client else { return .failure(.failedLoggingIn) }
        do {
            try await client.loginWithOidcCallback(callbackUrl: callbackURL.absoluteString)
            return await userSession(for: client)
        } catch OidcError.Cancelled {
            return .failure(.oidcError(.userCancellation))
        } catch {
            MXLog.error("Login with OIDC failed: \(error)")
            return .failure(.failedLoggingIn)
        }
    }

    func login(username: String, password: String, initialDeviceName: String?, deviceID: String?) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        guard let client else { return .failure(.failedLoggingIn) }
        do {
            try await client.login(username: username, password: password, initialDeviceName: initialDeviceName, deviceId: deviceID)

            let refreshToken = try? client.session().refreshToken
            if refreshToken != nil {
                MXLog.warning("Refresh token found for a non oidc session, can't restore session, logging out")
                _ = try? await client.logout()
                return .failure(.sessionTokenRefreshNotSupported)
            }

            return await userSession(for: client)
        } catch let ClientError.MatrixApi(errorKind, _, _, _) {
            MXLog.error("Failed logging in with error kind: \(errorKind)")
            switch errorKind {
            case .forbidden:
                return .failure(.invalidCredentials)
            case .userDeactivated:
                return .failure(.accountDeactivated)
            default:
                return .failure(.failedLoggingIn)
            }
        } catch {
            MXLog.error("Failed logging in with error: \(error)")
            return .failure(.failedLoggingIn)
        }
    }

    func loginWithQRCode(data: Data) -> QRLoginProgressPublisher {
        let progressSubject = CurrentValueSubject<QRLoginProgress, AuthenticationServiceError>(.starting)

        let qrData: QrCodeData
        do {
            qrData = try QrCodeData.fromBytes(bytes: data)
        } catch {
            MXLog.error("QRCode decode error: \(error)")
            progressSubject.send(completion: .failure(.qrCodeError(.invalidQRCode)))
            return progressSubject.asCurrentValuePublisher()
        }

        guard let scannedServerName = qrData.serverName() else {
            MXLog.error("The QR code is from a device that is not yet signed in.")
            progressSubject.send(completion: .failure(.qrCodeError(.deviceNotSignedIn)))
            return progressSubject.asCurrentValuePublisher()
        }

        if !appSettings.allowOtherAccountProviders, !appSettings.accountProviders.contains(scannedServerName) {
            MXLog.error("The scanned device's server is not allowed: \(scannedServerName)")
            progressSubject.send(completion: .failure(.qrCodeError(.providerNotAllowed(scannedProvider: scannedServerName, allowedProviders: appSettings.accountProviders))))
            return progressSubject.asCurrentValuePublisher()
        }

        let listener = SDKListener { progress in
            guard let progress = QRLoginProgress(rustProgress: progress) else { return }
            progressSubject.send(progress)
        }

        Task {
            do {
                let client = try await makeClient(homeserverAddress: scannedServerName)
                let qrCodeHandler = client.newLoginWithQrCodeHandler(oidcConfiguration: appSettings.oidcConfiguration.rustValue)
                try await qrCodeHandler.scan(qrCodeData: qrData, progressListener: listener)

                switch await userSession(for: client) {
                case .success(let userSession):
                    progressSubject.send(.signedIn(userSession))
                case .failure(let error):
                    progressSubject.send(completion: .failure(error))
                }
            } catch let error as HumanQrLoginError {
                MXLog.error("QRCode login error: \(error)")
                progressSubject.send(completion: .failure(error.serviceError))
            } catch RemoteSettingsError.elementProRequired(let serverName) {
                progressSubject.send(completion: .failure(.elementProRequired(serverName: serverName)))
            } catch {
                MXLog.error("QRCode login unknown error: \(error)")
                progressSubject.send(completion: .failure(.qrCodeError(.unknown)))
            }
        }

        return progressSubject.asCurrentValuePublisher()
    }

    func reset() {
        homeserverSubject.send(LoginHomeserver(address: appSettings.accountProviders[0], loginMode: .unknown))
        flow = .login
        client = nil
    }

    // MARK: - Private

    private func makeClient(homeserverAddress: String) async throws -> ClientProtocol {
        // Use a fresh session directory each time the user enters a different server
        // so that caches (e.g. server versions) are always fresh for the new server.
        rotateSessionDirectory()

        let client = try await clientFactory.makeClient(homeserverAddress: homeserverAddress,
                                                        sessionDirectories: sessionDirectories,
                                                        passphrase: passphrase,
                                                        clientSessionDelegate: userSessionStore.clientSessionDelegate,
                                                        appSettings: appSettings,
                                                        appHooks: appHooks)
        try await appHooks.remoteSettingsHook.initializeCache(using: client, applyingTo: appSettings).get()

        return client
    }

    private func rotateSessionDirectory() {
        sessionDirectories.delete()
        sessionDirectories = .init()
    }

    private func userSession(for client: ClientProtocol) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        switch await userSessionStore.userSession(for: client, sessionDirectories: sessionDirectories, passphrase: passphrase) {
        case .success(let clientProxy):
            return .success(clientProxy)
        case .failure:
            return .failure(.failedLoggingIn)
        }
    }
}

private extension HumanQrLoginError {
    var serviceError: AuthenticationServiceError {
        switch self {
        case .Cancelled:
            .qrCodeError(.cancelled)
        case .ConnectionInsecure:
            .qrCodeError(.connectionInsecure)
        case .Declined:
            .qrCodeError(.declined)
        case .LinkingNotSupported:
            .qrCodeError(.linkingNotSupported)
        case .Expired:
            .qrCodeError(.expired)
        case .SlidingSyncNotAvailable:
            .qrCodeError(.deviceNotSupported)
        case .OtherDeviceNotSignedIn:
            .qrCodeError(.deviceNotSignedIn)
        case .Unknown, .NotFound, .OidcMetadataInvalid, .CheckCodeAlreadySent, .CheckCodeCannotBeSent:
            .qrCodeError(.unknown)
        }
    }
}

// MARK: - Mocks

extension AuthenticationService {
    static var mock: AuthenticationService {
        AuthenticationService(userSessionStore: UserSessionStoreMock(configuration: .init()),
                              encryptionKeyProvider: EncryptionKeyProvider(),
                              clientFactory: AuthenticationClientFactoryMock(configuration: .init()),
                              appSettings: ServiceLocator.shared.settings,
                              appHooks: AppHooks())
    }
}
