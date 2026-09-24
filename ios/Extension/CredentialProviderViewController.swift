import AuthenticationServices
import Foundation

/// OnePass AutoFill credential provider (CONTRACTS §6).
///
/// All paths are silent: a code is supplied when one is found, otherwise the request is
/// cancelled without showing anything (decided: no UI on quota exhaustion / no match / errors).
final class CredentialProviderViewController: ASCredentialProviderViewController {

    /// nil when the build lacks the server configuration; every request then cancels.
    private lazy var resolver: OneTimeCodeResolver? = LiveDependencies.makeResolver()

    // MARK: - No-UI path (QuickType suggestion tapped)

    override func provideCredentialWithoutUserInteraction(for credentialRequest: any ASCredentialRequest) {
        guard let request = credentialRequest as? ASOneTimeCodeCredentialRequest else {
            extensionContext.cancelRequest(withError: ASExtensionError(.credentialIdentityNotFound))
            return
        }
        let service = request.credentialIdentity.serviceIdentifier.identifier
        resolveAndCompleteOneTimeCode(service: service, failure: .failed)
    }

    // MARK: - Paths where the system presents the view controller

    // OPEN(extension-ui): spec defines no extension UI. The three methods below run the same
    // resolver and complete immediately, or cancel with .userCanceled, adding no views of their own.

    override func prepareOneTimeCodeCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        // Lower indices are the more specific identifiers (docs/facts/F1 §1).
        resolveAndCompleteOneTimeCode(service: serviceIdentifiers.first?.identifier, failure: .userCanceled)
    }

    override func prepareInterfaceToProvideCredential(for credentialRequest: any ASCredentialRequest) {
        guard let request = credentialRequest as? ASOneTimeCodeCredentialRequest else {
            extensionContext.cancelRequest(withError: ASExtensionError(.credentialIdentityNotFound))
            return
        }
        let service = request.credentialIdentity.serviceIdentifier.identifier
        resolveAndCompleteOneTimeCode(service: service, failure: .userCanceled)
    }

    /// iOS 18.4+ calls this instead of `prepareInterfaceToProvideCredential` for one-time-code
    /// fields in some cases, and iOS 18 requires it to avoid "AutoFill Unavailable" (docs/facts/F1 §2).
    /// No service identifier is available here, so the newest code email is used (spec §5.6).
    override func prepareInterfaceForUserChoosingTextToInsert() {
        guard let resolver else {
            extensionContext.cancelRequest(withError: ASExtensionError(.userCanceled))
            return
        }
        Task { @MainActor [weak self] in
            let resolved = await resolver.resolve(service: nil)
            guard let self else { return }
            guard let resolved else {
                self.extensionContext.cancelRequest(withError: ASExtensionError(.userCanceled))
                return
            }
            self.extensionContext.completeRequest(
                withTextToInsert: resolved.code,
                completionHandler: Self.fillReporter(resolver: resolver, messageID: resolved.messageID)
            )
        }
    }

    // MARK: - Private

    private func resolveAndCompleteOneTimeCode(service: String?, failure: ASExtensionError.Code) {
        guard let resolver else {
            extensionContext.cancelRequest(withError: ASExtensionError(failure))
            return
        }
        Task { @MainActor [weak self] in
            let resolved = await resolver.resolve(service: service)
            guard let self else { return }
            guard let resolved else {
                self.extensionContext.cancelRequest(withError: ASExtensionError(failure))
                return
            }
            self.extensionContext.completeOneTimeCodeRequest(
                using: ASOneTimeCodeCredential(code: resolved.code),
                completionHandler: Self.fillReporter(resolver: resolver, messageID: resolved.messageID)
            )
        }
    }

    /// Completion handler that counts the fill (CONTRACTS §6: fire-and-forget after completion).
    ///
    /// The system runs this handler as background work after the request completes and passes
    /// `expired == true` when it ends that time early (docs/facts/F1 §1). The fill report is
    /// started on the first invocation and waited for at most `reportWait`, so that the extension
    /// is not suspended before the request is sent; the result is ignored either way.
    private static func fillReporter(resolver: OneTimeCodeResolver,
                                     messageID: String) -> @Sendable (Bool) -> Void {
        let reportWait: DispatchTimeInterval = .seconds(5)
        return { expired in
            guard !expired else { return }
            let done = DispatchSemaphore(value: 0)
            Task.detached {
                await resolver.reportFill(messageID: messageID)
                done.signal()
            }
            _ = done.wait(timeout: .now() + reportWait)
        }
    }
}
