#if os(iOS) && !targetEnvironment(macCatalyst)
import Foundation
import UIKit
@preconcurrency import AppAuth
@preconcurrency import AppAuthCore
import SkiPassAuth
import SkiPassModels

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
        let additionalParameters: [String: String]? = loginHint
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .flatMap { $0.isEmpty ? nil : ["login_hint": $0] }
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
                    additionalParameters: additionalParameters
                )
                // OIDAuthState+IOS.h: presents, then performs the code exchange. The returned session
                // must stay alive until the callback (README "Authorizing – iOS").
                let session = OIDAuthState.authState(byPresenting: request, presenting: presenting) { state, error in
                    flow.finish()
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
                flow.hold(session)
            }
        }
    }
}

/// Keeps the in-flight external-user-agent session alive until its callback fires.
///
/// `@unchecked Sendable`: `session` and `finished` are only touched under `lock`. The holder is
/// shared between AppAuth callbacks whose queue is not guaranteed for every path (the
/// ASWebAuthenticationSession completion that reports a failure is not documented to run on main).
private final class FlowHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var session: OIDExternalUserAgentSession?
    private var finished = false

    /// Retains `session` unless the flow already finished (then it is dropped at once).
    func hold(_ session: OIDExternalUserAgentSession?) {
        lock.lock(); defer { lock.unlock() }
        if !finished { self.session = session }
    }

    /// Releases the session once the callback has fired.
    func finish() {
        lock.lock(); defer { lock.unlock() }
        finished = true
        session = nil
    }
}
#endif
