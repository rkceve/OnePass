#if os(iOS) && !targetEnvironment(macCatalyst)
import Foundation
import UIKit
@preconcurrency import AppAuth
@preconcurrency import AppAuthCore
import OnePassAuth
import OnePassModels

// Interactive sign-in: app only. `AppAuth` (not `AppAuthCore`) contains
// OIDExternalUserAgentIOSCustomBrowser.m, which calls `[UIApplication sharedApplication]`
// (L147-L157), an API unavailable to app extensions.
extension OAuthService {
    /// Opens the provider's official sign-in page (ASWebAuthenticationSession via
    /// `OIDExternalUserAgentIOS`), exchanges the code (PKCE), and returns the signed-in address with
    /// the archived `OIDAuthState` to store under `oauth.<mailboxID>`.
    ///
    /// - Parameter loginHint: The address the user typed; sent as `login_hint` so the page opens
    ///   prefilled (Google: developers.google.com/identity/protocols/oauth2/native-app;
    ///   Microsoft: learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow).
    @MainActor
    public func signIn(kind: ProviderKind, presenting: UIViewController,
                       loginHint: String?) async throws -> (address: String, authStateData: Data) {
        let settings = try OAuthProviderSettings.settings(for: kind, clients: clients)
        var parameters: [String: String] = [:]
        if let hint = loginHint?.trimmingCharacters(in: .whitespacesAndNewlines), !hint.isEmpty {
            parameters["login_hint"] = hint
        }
        let flow = FlowHolder()

        return try await withCheckedThrowingContinuation { continuation in
            // OIDAuthorizationService.h L105-L106; completion runs on the main queue.
            OIDAuthorizationService.discoverConfiguration(forIssuer: settings.issuer) { discovered, error in
                guard let discovered else {
                    continuation.resume(throwing: error ?? OAuthError.signInFailed)
                    return
                }
                let configuration = settings.omitIssuer
                    ? OIDServiceConfiguration(authorizationEndpoint: discovered.authorizationEndpoint,
                                              tokenEndpoint: discovered.tokenEndpoint)
                    : discovered
                // OIDAuthorizationRequest.h L154-L160: generates state and PKCE (S256).
                let request = OIDAuthorizationRequest(
                    configuration: configuration,
                    clientId: settings.clientID,
                    scopes: settings.scopes,
                    redirectURL: settings.redirectURL,
                    responseType: OIDResponseTypeCode,
                    additionalParameters: parameters.isEmpty ? nil : parameters
                )
                // OIDAuthState+IOS.h: presents, then performs the code exchange. The returned session
                // must stay alive until the callback (README "Authorizing – iOS").
                flow.session = OIDAuthState.authState(byPresenting: request, presenting: presenting) { state, error in
                    flow.session = nil
                    guard let state else {
                        continuation.resume(throwing: error ?? OAuthError.signInFailed)
                        return
                    }
                    do {
                        let address = try Self.address(of: state, loginHint: loginHint)
                        continuation.resume(returning: (address, try Self.archive(state)))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}

/// Keeps the in-flight external-user-agent session alive until its callback fires.
private final class FlowHolder {
    var session: OIDExternalUserAgentSession?
}
#endif
