
//
// Copyright 2026 Ketal Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
//

import SwiftUI
import WebKit

struct OIDCWebViewScreen: View {
    @StateObject private var viewModel: OIDCWebViewViewModel
    let onSuccess: (URL) -> Void
    let onCancel: () -> Void

    init(authorizationURL: URL,
         redirectURI: String,
         onSuccess: @escaping (URL) -> Void,
         onCancel: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: OIDCWebViewViewModel(authorizationURL: authorizationURL,
                                                                    redirectURI: redirectURI))
        self.onSuccess = onSuccess
        self.onCancel = onCancel
    }


    // var body: some View {
    //     ZStack {
    //         // 1. "Stark white backdrop"
    //         Color.white.ignoresSafeArea()

    //         GeometryReader { geometry in
    //             // 2. The "central focus" card
    //             ZStack(alignment: .topTrailing) {
    //                 // WebView fills the card area
    //                 WebView(viewModel: viewModel)
    //                     .frame(maxWidth: .infinity, maxHeight: .infinity)
    //                     .opacity(viewModel.isLoading ? 0 : 1)
    //                     .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                    
    //                 if viewModel.isLoading {
    //                     ProgressView().scaleEffect(1.5).frame(maxWidth: .infinity, maxHeight: .infinity)
    //                 }

    //                 // 3. Small, black "X" icon
    //                 Button(action: onCancel) {
    //                     Image(systemName: "xmark")
    //                         .font(.system(size: 20, weight: .light))
    //                         .foregroundColor(.black)
    //                         .padding(28) // Inset from the corner
    //                 }
    //             }
    //             .background(Color.white)
    //             .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
    //             // 4. "Soft, diffused shadows"
    //             .shadow(color: .black.opacity(0.06), radius: 30, x: 0, y: 15)
    //             // Ensures the card "occupies a large portion" but centers it
    //             .frame(width: geometry.size.width * 0.92, height: geometry.size.height * 0.85)
    //             .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
    //         }
    //     }
    //     // CRITICAL: Forces the white background to fill behind the notch/status bar
    //     .ignoresSafeArea() 
    //     .navigationBarHidden(true)
    //     .onAppear { viewModel.loadAuthorizationPage() }
    //     .onChange(of: viewModel.callbackURL) { _, newValue in
    //         if let callbackURL = newValue { onSuccess(callbackURL) }
    //     }
    // }


    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                navigationBar
                ZStack {
                    WebView(viewModel: viewModel)
                        .opacity(viewModel.isLoading ? 0 : 1)
                        .ignoresSafeArea()
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                    }
                    if let error = viewModel.error {
                        errorView(error)
                    }
                }
            }
        }
        .background(Color.white)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 36, topTrailingRadius: 36))
        .shadow(color: .black.opacity(0.52), radius: 18, x: 0, y: -4)
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: viewModel.callbackURL) { _, newValue in
            if let callbackURL = newValue {
                onSuccess(callbackURL)
            }
        }
        .onAppear {
            viewModel.loadAuthorizationPage()
        }
    }
    
    private var navigationBar: some View {
        HStack {
            Spacer()
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.compound.textPrimary)
                    .padding(12)
                    .background(Color.compound.bgCanvasDefault)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 3)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.compound.textCriticalPrimary)

            Text("Authentication Error")
                .font(.compound.headingMDBold)
                .foregroundColor(.compound.textPrimary)

            Text(error)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Try Again") {
                viewModel.retry()
            }
            .buttonStyle(.compound(.primary))
            .padding(.top, 8)
        }
        .padding()
    }
}

// MARK: - WebView

private struct WebView: UIViewRepresentable {
    @ObservedObject var viewModel: OIDCWebViewViewModel

    func makeUIView(context: Context) -> WKWebView {
        viewModel.webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // No updates needed
    }
}

#Preview {
    OIDCWebViewScreen(authorizationURL: URL(string: "https://www.google.com")!,
                      redirectURI: "http://localhost",
                      onSuccess: { _ in },
                      onCancel: { })
}
	
