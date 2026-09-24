import Foundation
import OnePassModels

/// Finds the one-time code in an email using the 2FHey parser (see `OTPParser.swift`).
///
/// The subject is searched first, then `bodyText`. The returned string is what the user
/// would type: 2FHey's normalization applies (spaces and dashes dropped, e.g. "123 456"
/// → "123456"), except Google's "G-123456" form, which 2FHey returns with its prefix.
public struct OTPCodeExtractor: CodeExtracting {
    private let parser: OTPParser

    public init() {
        parser = .shared
    }

    public func extractCode(from message: FetchedMessage) -> String? {
        // `from` is an email address, not a phone number, so it is not passed as 2FHey's
        // `sender` (which exists to keep an SMS sender's own number from being returned).
        if let parsed = parser.parse(message.subject, mode: .emailSubject) {
            return parsed.code
        }
        return parser.parse(message.bodyText, mode: .emailBody)?.code
    }
}
