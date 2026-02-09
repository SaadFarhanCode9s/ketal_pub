//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum RemoteSettingsError: Error {
    case elementProRequired(serverName: String)
}

protocol RemoteSettingsHookProtocol {
    #if IS_MAIN_APP
    @MainActor func initializeCache(using client: ClientProtocol, applyingTo appSettings: CommonSettingsProtocol) async -> Result<Void, RemoteSettingsError>
    func updateCache(using client: ClientProtocol) async
    @MainActor func reset(_ appSettings: CommonSettingsProtocol)
    #endif
    @MainActor func loadCache(forHomeserver homeserver: String, applyingTo appSettings: CommonSettingsProtocol)
}

struct DefaultRemoteSettingsHook: RemoteSettingsHookProtocol {
    #if IS_MAIN_APP
    /// A best effort implementation to let Element X advertise to users when they should be using
    /// Element Pro. In an ideal world the backend would be able to validate the client's requests
    /// instead of relying on it to check a well-known file for this.
    func initializeCache(using client: ClientProtocol, applyingTo appSettings: CommonSettingsProtocol) async -> Result<Void, RemoteSettingsError> {
        await updateElementCallURL(using: client, applyingTo: appSettings)

        guard case let .success(wellKnownData) = await client.elementWellKnown() else {
            // Nothing to check, carry on as normal.
            return .success(())
        }
        
        do {
            let wellKnown = try JSONDecoder().decode(ElementWellKnown.self, from: wellKnownData)
            if wellKnown.enforceElementPro == true {
                let serverName = client.server() ?? client.homeserver()
                let displayableServerName = LoginHomeserver(address: serverName, loginMode: .unknown).address
                return .failure(.elementProRequired(serverName: displayableServerName))
            } else {
                return .success(())
            }
        } catch {
            // If it doesn't decode we have to assume it's a 404 page or similar.
            return .success(())
        }
    }
    
    func updateCache(using client: ClientProtocol) async {
        guard let appSettings = ServiceLocator.shared.settings else {
            MXLog.warning("RemoteSettings: ServiceLocator.settings not registered, skipping updateCache.")
            return
        }

        await updateElementCallURL(using: client, applyingTo: appSettings)
    }
    func reset(_ appSettings: any CommonSettingsProtocol) { }

    private func updateElementCallURL(using client: ClientProtocol, applyingTo appSettings: CommonSettingsProtocol) async {
        guard let appSettings = appSettings as? AppSettings else { return }
        guard case let .success(wellKnownData) = await client.clientWellKnown() else {
            MXLog.warning("RemoteSettings: failed to load /.well-known/matrix/client from server.")
            return
        }

        guard let callURL = Self.extractCallURL(from: wellKnownData) else {
            MXLog.warning("RemoteSettings: no org.matrix.msc3401.call.url found in well-known.")
            return
        }

        let normalized = Self.normalizedCallURL(callURL)
        await MainActor.run {
            appSettings.elementCallBaseURLOverride = normalized
        }
        MXLog.info("RemoteSettings: Element Call URL override set to \(normalized.absoluteString)")
    }
    #endif

    func loadCache(forHomeserver homeserver: String, applyingTo appSettings: CommonSettingsProtocol) {
        guard let appSettings = appSettings as? AppSettings else { return }

        Task {
            let candidates = Self.wellKnownCandidateURLs(forHomeserver: homeserver)
            for url in candidates {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let callURL = Self.extractCallURL(from: data) {
                        let normalized = Self.normalizedCallURL(callURL)
                        await MainActor.run {
                            appSettings.elementCallBaseURLOverride = normalized
                        }
                        MXLog.info("RemoteSettings: Element Call URL override loaded from \(url.absoluteString) -> \(normalized.absoluteString)")
                        return
                    }
                } catch {
                    MXLog.debug("RemoteSettings: failed to fetch well-known from \(url.absoluteString): \(error)")
                }
            }
        }
    }

    private static func wellKnownCandidateURLs(forHomeserver homeserver: String) -> [URL] {
        var urls: [URL] = []

        if let homeserverURL = URL(string: homeserver), let host = homeserverURL.host {
            // First try the homeserver host directly (e.g. matrix.ketals.online)
            if let direct = URL(string: "https://\(host)/.well-known/matrix/client") {
                urls.append(direct)
            }

            // Then try stripping the first label to reach the server name (e.g. ketals.online)
            let parts = host.split(separator: ".")
            if parts.count > 2 {
                let strippedHost = parts.dropFirst().joined(separator: ".")
                if let stripped = URL(string: "https://\(strippedHost)/.well-known/matrix/client") {
                    urls.append(stripped)
                }
            }
        }

        return urls
    }

    private static func extractCallURL(from data: Data) -> URL? {
        guard let wellKnown = try? JSONDecoder().decode(ClientWellKnown.self, from: data),
              let callURLString = wellKnown.msc3401Call?.url,
              let callURL = URL(string: callURLString) else {
            return nil
        }
        return callURL
    }

    private static func normalizedCallURL(_ callURL: URL) -> URL {
        // Ensure no trailing slash to match Origin expectations for Widget API
        if callURL.path.hasSuffix("/") {
            let string = callURL.absoluteString
            if string.hasSuffix("/"), let trimmed = URL(string: String(string.dropLast())) {
                return trimmed
            }
        }
        return callURL
    }
}

private struct ClientWellKnown: Decodable {
    struct MSC3401Call: Decodable {
        var url: String
    }

    var msc3401Call: MSC3401Call?

    enum CodingKeys: String, CodingKey {
        case msc3401Call = "org.matrix.msc3401.call"
    }
}

private struct ElementWellKnown: Decodable {
    var version: Int
    var enforceElementPro: Bool?
    
    enum CodingKeys: String, CodingKey {
        case version
        case enforceElementPro = "enforce_element_pro"
    }
}
