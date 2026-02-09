//
// Copyright 2026 Ketal Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
//

import Combine
import Foundation
import WebKit

@MainActor
class OIDCWebViewViewModel: NSObject, ObservableObject {
    @Published var isLoading = true
    @Published var error: String?
    @Published var callbackURL: URL?

    private let authorizationURL: URL
    private let redirectURI: String

    // lazy var webView: WKWebView = {
    //     let config = WKWebViewConfiguration()
    //     // Use non-persistent data store to avoid sharing cookies with the app
    //     config.websiteDataStore = .nonPersistent()

    //     let webView = WKWebView(frame: .zero, configuration: config)
    //     webView.navigationDelegate = self
    //     webView.customUserAgent = UserAgentBuilder.makeASCIIUserAgent()
    //     // Style the webview
    //     webView.isOpaque = false
    //     webView.backgroundColor = .clear
    //     webView.scrollView.backgroundColor = .clear
    //     webView.scrollView.contentInsetAdjustmentBehavior = .never
        
    //     return webView
    // }()

    lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.customUserAgent = UserAgentBuilder.makeASCIIUserAgent()
        
        // Ensure total transparency to match the SwiftUI Card backdrop
        webView.isOpaque = false 
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        
        // This prevents the webview from adding its own padding for the notch
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        return webView
    }()

    init(authorizationURL: URL, redirectURI: String) {
        self.authorizationURL = authorizationURL
        self.redirectURI = redirectURI
        super.init()
    }

    func loadAuthorizationPage() {
        isLoading = true
        error = nil

        var request = URLRequest(url: authorizationURL)
        request.setValue(UserAgentBuilder.makeASCIIUserAgent(), forHTTPHeaderField: "User-Agent")

        webView.load(request)
    }

    func retry() {
        loadAuthorizationPage()
    }

    func cleanup() {
        // Clear all website data after authentication
        let dataStore = WKWebsiteDataStore.nonPersistent()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let date = Date(timeIntervalSince1970: 0)

        dataStore.removeData(ofTypes: dataTypes, modifiedSince: date) {
            MXLog.info("Cleared WebView data after OIDC authentication")
        }
    }
}

// MARK: - WKNavigationDelegate

extension OIDCWebViewViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        MXLog.info("[OIDC WebView] Navigation to: \(url.absoluteString)")

        // CRITICAL FIX: Only intercept if the SCHEME matches the redirect URI scheme.
        // The authorization URL also contains the redirect_uri as a parameter, so simple string matching fails.
        // Example: https://matrix.ketals.online/auth/authorize?...&redirect_uri=ketal://oidc... <- DO NOT INTERCEPT
        // Example: ketal://oidc?code=... <- INTERCEPT THIS

        if let scheme = url.scheme, redirectURI.hasPrefix(scheme + ":") {
            MXLog.info("[OIDC WebView] Intercepted redirect URI with callback")

            // Capture the callback URL
            callbackURL = url

            // Prevent the WebView from navigating to the custom scheme
            decisionHandler(.cancel)

            // Clean up
            cleanup()
            return
        }

        // Validate that we're navigating to expected domains (security measure)
        if let host = url.host {
            let allowedDomains = ["ketals.online", "matrix.ketals.online", "auth.ketals.online"]
            if !allowedDomains.contains(where: { host.hasSuffix($0) }) {
                MXLog.error("[OIDC WebView] Blocked navigation to untrusted domain: \(host)")
                error = "Navigation blocked to untrusted domain"
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        MXLog.info("[OIDC WebView] Page loaded successfully")
    }

    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation!,
                 withError error: Error) {
        isLoading = false
        self.error = error.localizedDescription
        MXLog.error("[OIDC WebView] Navigation failed: \(error)")
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        isLoading = false

        // Ignore cancellations (these are expected when we intercept the redirect)
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
            return
        }

        self.error = error.localizedDescription
        MXLog.error("[OIDC WebView] Provisional navigation failed: \(error)")
    }
}
