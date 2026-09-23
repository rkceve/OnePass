# F2 — Mail IMAP / OAuth Authentication: Collected Facts

Fact-collection only. No recommendations, conclusions, or design suggestions are included. All quotes are verbatim from the cited source. "Gaps" section at the end lists everything not found.

---

## 1. Cocoanetics/SwiftMail

Latest release tag: `1.12.0`, commit SHA `62102d79c15b1bb8d5af0ede21cdef388b3ed611` (verified via `git rev-parse 1.12.0`). All URLs below use `https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/<path>#L<n>`.

Class: `public actor IMAPServer` — https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/IMAPServer.swift#L30

### (a) Connect over TLS

Primary initializer, https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/IMAPServer.swift#L238-L279:
```swift
public init(
    host: String,
    port: Int,
    transportSecurity: MailTransportSecurity = .automatic,
    certificateVerificationPolicy: MailCertificateVerificationPolicy = .fullVerification,
    minimumTLSVersion: MailTLSMinimumVersion = .tlsv12,
    numberOfThreads: Int = 1,
    responseBufferLimit: Int = IMAPServer.defaultResponseBufferLimit,
    parserLimits: IMAPParserLimits = .default
) {
```
Legacy overload, https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/IMAPServer.swift#L281-L296:
```swift
public init(
    host: String,
    port: Int,
    useTLS: Bool?,
    numberOfThreads: Int = 1,
    responseBufferLimit: Int = IMAPServer.defaultResponseBufferLimit
) {
```
`connect()`, https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/IMAPServer+Connection.swift#L21-L23:
```swift
public func connect() async throws {
    try await primaryConnection.connect()
}
```
Doc-comment usage example at top of `IMAPServer.swift`, https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/IMAPServer.swift#L15-L20:
```swift
let server = IMAPServer(host: "imap.example.com", port: 993)
try await server.connect()
try await server.login(username: "user@example.com", password: "password")
```
Note: the README.md "Usage" section contains no connect/login code example — its only Swift code blocks are for creating drafts (quoted below). The example above is the only verbatim connect/login snippet found in the repo.

### (b) Authenticate

LOGIN, https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/IMAPServer+Connection.swift#L71-L79:
```swift
public func login(username: String, password: String) async throws {
    try await primaryConnection.login(username: username, password: password)
    ...
}
```
AUTHENTICATE PLAIN, https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/IMAPServer+Connection.swift#L92-L100:
```swift
public func authenticatePlain(username: String, password: String) async throws {
    try await primaryConnection.authenticatePlain(username: username, password: password)
    ...
}
```
XOAUTH2, https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/IMAPServer+Connection.swift#L108-L116:
```swift
public func authenticateXOAUTH2(email: String, accessToken: String) async throws {
    try await primaryConnection.authenticateXOAUTH2(email: email, accessToken: accessToken)
    ...
}
```
Dynamic token-refresh provider, https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/IMAPServer+Connection.swift#L120-L128: `setXOAUTH2AccessTokenProvider(email:accessTokenProvider:)`.

### (c) Select INBOX

https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/IMAPServer+Mailbox.swift#L41-L44:
```swift
@discardableResult public func selectMailbox(_ mailboxName: String) async throws -> Mailbox.Selection {
    let command = SelectMailboxCommand(mailboxName: resolveMailboxPath(mailboxName))
    return try await executeCommand(command)
}
```
Called as `selectMailbox("INBOX")`. Read-only counterpart `examineMailbox(_:)` at https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/IMAPServer+Mailbox.swift#L59-L63.

### (d) Search by date/recency or UID range

Two entry points, https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/IMAPServer+Search.swift#L55-L79 and #L105-L137:
```swift
public func search<T: MessageIdentifier>(
    identifierSet: MessageIdentifierSet<T>? = nil,
    criteria: [SearchCriteria],
    sortCriteria: [SortCriterion],
    sortCharset: String = "UTF-8",
    calendar: Calendar = Calendar(identifier: .gregorian)
) async throws -> [T]
```
```swift
public func extendedSearch<T: MessageIdentifier>(
    identifierSet: MessageIdentifierSet<T>? = nil,
    criteria: [SearchCriteria],
    sortCriteria: [SortCriterion] = [],
    sortCharset: String = "UTF-8",
    calendar: Calendar = Calendar(identifier: .gregorian),
    partialRange: PartialRange? = nil
) async throws -> ExtendedSearchResult<T>
```
`public indirect enum SearchCriteria: Sendable`, https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/Models/SearchCriteria.swift#L11 — relevant cases: `before(Date)` L24-25, `on(Date)` L67, `since(Date)` L88, `sentBefore(Date)` L79, `sentOn(Date)` L82, `sentSince(Date)` L85, `older(seconds: Int)` L126, `younger(seconds: Int)` L131 (RFC 5032 WITHIN extension, requires server `WITHIN` capability), `new` L58, `recent` L73, `old` L64, `uid(Int)` L103.

UID-range convenience overloads on `fetchMessageInfos`, https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/IMAPServer+Fetch.swift#L230-L245 (see (e)).

### (e) Fetch headers and body parts

`Sources/SwiftMail/IMAP/IMAPServer+Fetch.swift`:
```swift
public func fetchMessageInfo<T: MessageIdentifier>(
    for identifier: T,
    options: FetchMessageInfoOptions = .default,
    headerFields: [String]? = nil
) async throws -> MessageInfo?
```
(L198-208)
```swift
public func fetchMessageInfosBulk<T: MessageIdentifier>(
    using identifierSet: MessageIdentifierSet<T>,
    options: FetchMessageInfoOptions = .default,
    headerFields: [String]? = nil
) async throws -> [MessageInfo]
```
(L216-225). Return type `MessageInfo` — `public struct MessageInfo: Codable, Sendable` (https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/Models/MessageInfo.swift#L7-L61) with fields including `subject`, `from`, `to`, `cc`, `bcc`, `date` (envelope Date header), `internalDate`.

UID-range overloads, L230-245:
```swift
public func fetchMessageInfos(
    uidRange: PartialRangeFrom<UID>,
    options: FetchMessageInfoOptions = .default,
    headerFields: [String]? = nil
) async throws -> [MessageInfo]

public func fetchMessageInfos(
    uidRange: ClosedRange<UID>,
    options: FetchMessageInfoOptions = .default,
    headerFields: [String]? = nil
) async throws -> [MessageInfo]
```
Fetch a MIME part by section, https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/IMAPServer+Fetch.swift#L46-L49:
```swift
public func fetchPart<T: MessageIdentifier>(section: Section, of identifier: T) async throws -> Data
```
Fetch MIME structure, L24-27: `public func fetchStructure<T: MessageIdentifier>(_ identifier: T) async throws -> [MessagePart]`.
Fetch every part + data, L131-140: returns `[MessagePart]`.
Fetch complete `Message` object, L178-190: `public func fetchMessage(from header: MessageInfo) async throws -> Message`.
Fetch raw RFC822 message, L120-123: `public func fetchRawMessage<T: MessageIdentifier>(identifier: T) async throws -> Data`.

### (f) Disconnect

`Sources/SwiftMail/IMAP/IMAPServer+Connection.swift`:
```swift
public func disconnect() async throws {
    try await closeAllConnections()
}
```
(L178-180, immediate close, no LOGOUT)
```swift
public func logout() async throws {
    let command = LogoutCommand()
    try await executeCommand(command)
    try await closeAllConnections()
}
```
(L266-270, sends LOGOUT then closes)

### README.md verbatim Swift code blocks

Only Swift examples in README.md are for draft creation (no connect/login/fetch example exists in the README):
```swift
let draft = Email(
    sender: EmailAddress(name: "Me", address: "me@example.com"),
    recipients: [],
    subject: "Quarterly update",
    textBody: "Jot down your notes here…"
)

let appendResult = try await imapServer.createDraft(from: draft)
if let uid = appendResult.firstUID {
    print("Draft stored with UID \(uid.value)")
}
```
```swift
try await imapServer.append(
    email: draft,
    to: "Archive/Drafts",
    flags: [.seen]
)
```

### Package.swift

Source: https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Package.swift

- **Products**: library `SwiftMail` (targets: `["SwiftMail"]`); executables `SwiftIMAPCLI` and `SwiftSMTPCLI` (guarded to not build on Windows/Android).
- **Dependencies**: `thebarndog/swift-dotenv` from 2.1.0; `apple/swift-log` from 1.0.0; `Cocoanetics/SwiftCross` from 1.2.0; `apple/swift-nio` from 2.101.3; `apple/swift-nio-imap` from 0.3.0; `apple/swift-nio-ssl` from 2.37.1; `apple/swift-collections` from 1.0.0; `apple/swift-testing` exact 6.3.2; `apple/swift-argument-parser` from 1.3.0.
- **Platform minimums** (`platforms:` array in Package.swift):
```swift
.macOS("12.0"),
.iOS("15.0"),
.tvOS("15.0"),
.watchOS("8.0"),
.macCatalyst("15.0")
```
  In-file comment: "Floors raised to satisfy the SwiftCross dependency (iOS 15 / tvOS 15 / watchOS 8); SwiftCross's own floor is set by its URLSession.bytes shim."
  Discrepancy noted: README.md's "Requirements" section states "macOS 11.0+, iOS 14.0+, tvOS 14.0+, watchOS 7.0+, macCatalyst 14.0+" — this does not match the actual `Package.swift` platform floors at tag 1.12.0 (iOS 15.0, not 14.0).
- `swift-tools-version: 5.9`

### APPLICATION_EXTENSION_API_ONLY

NOT FOUND — zero occurrences anywhere in the repository at tag 1.12.0 (full-tree grep).

### BODY.PEEK vs BODY (read-marking on fetch)

All body-fetching FETCH attributes in `Sources/SwiftMail/IMAP/IMAP/Commands/FetchCommands.swift` are constructed with `peek: true`:
- L75: `attributes.append(.bodySection(peek: true, .header, nil))` (full header fetch)
- L78: `attributes.append(.bodySection(peek: true, section, nil))` (named header fields)
- L155: `.bodySection(peek: true, section, range)` (`FetchMessagePartCommand`, used by `fetchPart(section:of:)`)
- L193: `.bodySection(peek: true, SectionSpecifier.complete, nil)` (`FetchRawMessageCommand`, used by `fetchRawMessage(identifier:)`)

Doc comments confirming this, https://github.com/Cocoanetics/SwiftMail/blob/1.12.0/Sources/SwiftMail/IMAP/IMAPServer+Fetch.swift#L51-L56 and #L113-L114:
```
Fetches a validated byte range of a message part without setting `\Seen`.
The wire request is `BODY.PEEK[section]<offset.count>`. ...
```
```
Fetches the complete raw RFC822 message (headers + body) without setting the \Seen flag.
```
No occurrence of `.bodySection(peek: false, ...)` or a non-`.PEEK` `BODY[` fetch was found anywhere in `Sources/SwiftMail/`. Fact: every body/header fetch path uses `BODY.PEEK`.

---

## 2. openid/AppAuth-iOS

Latest release tag: `3.0.0`, commit `a972daac82d449d58ab119e91c68153e29ddac33`, tagged 2026-08-24. URLs use `https://github.com/openid/AppAuth-iOS/blob/a972daac82d449d58ab119e91c68153e29ddac33/<path>#L<n>`.

### SPM product names

Source: https://github.com/openid/AppAuth-iOS/blob/a972daac82d449d58ab119e91c68153e29ddac33/Package.swift#L29-L38
```swift
products: [
    .library(
        name: "AppAuthCore",
        targets: ["AppAuthCore"]),
    .library(
        name: "AppAuth",
        targets: ["AppAuth"]),
    .library(
        name: "AppAuthTV",
        targets: ["AppAuthTV"])
],
```

### Discovery

Note: the actual API name is `discoverServiceConfigurationForIssuer:completion:`, not `discoverConfiguration(forIssuer:completion:)`.
Source: https://github.com/openid/AppAuth-iOS/blob/a972daac82d449d58ab119e91c68153e29ddac33/Sources/AppAuthCore/OIDAuthorizationService.h#L105-L106
```objc
+ (void)discoverServiceConfigurationForIssuer:(NSURL *)issuerURL
                                   completion:(OIDDiscoveryCallback)completion;
```

### OIDAuthorizationRequest initializer

Source: https://github.com/openid/AppAuth-iOS/blob/a972daac82d449d58ab119e91c68153e29ddac33/Sources/AppAuthCore/OIDAuthorizationRequest.h#L154-L160
```objc
- (instancetype)
    initWithConfiguration:(OIDServiceConfiguration *)configuration
                 clientId:(NSString *)clientID
                   scopes:(nullable NSArray<NSString *> *)scopes
              redirectURL:(NSURL *)redirectURL
             responseType:(NSString *)responseType
     additionalParameters:(nullable NSDictionary<NSString *, NSString *> *)additionalParameters;
```
(3 other initializer overloads also exist in the file.)

### OIDExternalUserAgentIOS initializer

Source: https://github.com/openid/AppAuth-iOS/blob/a972daac82d449d58ab119e91c68153e29ddac33/Sources/AppAuth/iOS/OIDExternalUserAgentIOS.h#L47-L49
```objc
- (nullable instancetype)initWithPresentingViewController:
    (UIViewController *)presentingViewController
    NS_DESIGNATED_INITIALIZER;
```
An ephemeral-session variant also exists at L59-62.

### OIDAuthState.authState(byPresenting:presenting:callback:)

Actual Obj-C selector: `authStateByPresentingAuthorizationRequest:externalUserAgent:callback:`.
Source: https://github.com/openid/AppAuth-iOS/blob/a972daac82d449d58ab119e91c68153e29ddac33/Sources/AppAuthCore/OIDAuthState.h#L138-L141
```objc
+ (id<OIDExternalUserAgentSession>)
    authStateByPresentingAuthorizationRequest:(OIDAuthorizationRequest *)authorizationRequest
                            externalUserAgent:(id<OIDExternalUserAgent>)externalUserAgent
                                     callback:(OIDAuthStateAuthorizationCallback)callback;
```

### Token refresh: performActionWithFreshTokens:

Source: https://github.com/openid/AppAuth-iOS/blob/a972daac82d449d58ab119e91c68153e29ddac33/Sources/AppAuthCore/OIDAuthState.h#L220-L225
```objc
/*! @brief Calls the block with a valid access token (refreshing it first, if needed), or if a
        refresh was needed and failed, with the error that caused it to fail.
    @param action The block to execute with a fresh token. This block will be executed on the main
        thread.
 */
- (void)performActionWithFreshTokens:(OIDAuthStateAction)action;
```
Two overloads also exist (L234-236 and L246-249) adding `additionalRefreshParameters:` and `dispatchQueue:` parameters.

### Archiving OIDAuthState (NSSecureCoding)

Conformance declaration, https://github.com/openid/AppAuth-iOS/blob/a972daac82d449d58ab119e91c68153e29ddac33/Sources/AppAuthCore/OIDAuthState.h#L60:
```objc
@interface OIDAuthState : NSObject <NSSecureCoding>
```
Implementation methods in `OIDAuthState.m`: `supportsSecureCoding` (L254), `initWithCoder:` (L258), `encodeWithCoder:` (L275).

README guidance, https://github.com/openid/AppAuth-iOS/blob/a972daac82d449d58ab119e91c68153e29ddac33/README.md#L156-L159:
```
`OIDAuthState` is a class that keeps track of the authorization and token
requests and responses, and provides a convenience method to call an API with
fresh tokens. This is the only object that you need to serialize to retain the
authorization state of the session.
```

### App extensions

README.md: NOT FOUND (no "app extension" or "NSExtension" mentions; only unrelated matches for "PKCE extension" and OAuth-2 "extensions" as a protocol concept).

CHANGELOG.md does document iOS-extension support as a design rationale, https://github.com/openid/AppAuth-iOS/blob/a972daac82d449d58ab119e91c68153e29ddac33/CHANGELOG.md#L117-L118 (duplicated at L124-125), under the "1.0.0.beta1"/"1.0.0.beta2 (2018-09-27)" entries:
```
`AppAuth/Core` subspec, and AppAuthCore Framework added to support
    iOS extensions.
```
No further elaboration (e.g. scoping to "token refresh only") was found in README.md, CHANGELOG.md, or header doc-comments in `Sources/AppAuthCore`. GitHub issue search did not surface any issue confirming or denying app-extension safety for `performActionWithFreshTokens:` specifically.

---

## 3. Redirect URI rules for iOS OAuth clients

### Google — reversed client ID scheme

Source: https://developers.google.com/identity/sign-in/ios/start-integrating
> "The reversed client ID is your client ID with the order of the dot-delimited fields reversed." Example given: `com.googleusercontent.apps.1234567890-abcdefg`. "This is also shown under '_iOS URL scheme_' when selecting an existing iOS OAuth client in the Cloud console."

Source: https://developers.google.com/identity/protocols/oauth2/native-app
> "com.googleusercontent.apps.123 is the reverse DNS notation of the client ID." — given as one of two acceptable custom URI scheme forms for `redirect_uri` (the other being a developer-owned reverse-DNS domain, e.g. `com.example.app`), optionally with a path such as `/oauth2redirect`.

### Microsoft — public client/native app redirect URI

Source: https://learn.microsoft.com/en-us/entra/msal/objc/redirect-uris-ios
> "MSAL uses a default redirect URI, if you don't specify one. The format is `msauth.[Your_Bundle_Id]://auth`."
> "The default redirect URI format works for most apps and scenarios, including brokered authentication and system web view. Use the default format whenever possible."
> "The MSAL redirect URI must be in the form `<scheme>://host`... primarily based on the Bundle Identifier of your application to guarantee uniqueness. For example, if your app's Bundle ID is `com.contoso.myapp`, your redirect URI would be in the form: `msauth.com.contoso.myapp://auth`."

Source: https://learn.microsoft.com/en-us/entra/identity-platform/scenario-desktop-app-configuration (redirected from `scenario-desktop-app-registration`)
> "Under Manage, select Authentication > Add a platform > Mobile and desktop applications"
> "Objective-C or Swift apps for macOS: `msauth.<your.app.bundle.id>://auth`."

---

## 4. Microsoft — IMAP OAuth for personal Outlook.com accounts

### IMAP server/port

Source: https://support.microsoft.com/en-us/outlook/pop-imap-and-smtp-settings-for-outlook-com
> Server name: "outlook.office365.com", Port: "993" (table-cell values).

### OAuth scope for IMAP

Source: https://learn.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth
> Table: "Protocol | Permission scope string" → "IMAP | `https://outlook.office.com/IMAP.AccessAsUser.All`"
> "Ensure to specify the full scopes, including Outlook resource URLs, when authorizing your application and requesting an access token."
> "In addition, you can request for offline_access scope. When a user approves the offline_access scope, your app can receive refresh tokens from the Microsoft identity platform token endpoint."

Also from the same page: `https://outlook.office365.com/.default` is used only for the client-credentials/app-only flow (not user-delegated IMAP scope), and `https://ps.outlook.com/.default` for tenant admin-consent POP/IMAP flows — different code paths from the user-delegated IMAP scope above.

### Authority endpoint (/common vs /consumers)

Source: https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow — table row for the `tenant` parameter:
> "Valid values are `common`, `organizations`, `consumers`, and tenant identifiers."

No explicit "use /consumers for personal accounts" sentence was found on that page. A Microsoft Q&A thread (community content, not official docs) notes the well-known discovery endpoint for Microsoft accounts is `https://login.microsoftonline.com/consumers/v2.0/.well-known/openid-configuration`, and that switching from `/common` to `/consumers` resolves "can't sign in here with a personal account" errors — flagged as community Q&A, not official-docs prose.

### App registration settings

Source: https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app — "Supported account types" table:
> "**Any Entra ID Tenant + Personal Microsoft accounts** | For *multitenant* apps that support both organizational and personal Microsoft accounts (for example, Skype, Xbox, Live, Hotmail)."
> "**Personal accounts only** | For apps used only by personal Microsoft accounts (for example: Xbox, Live, Hotmail)."

Platform type, source https://learn.microsoft.com/en-us/entra/identity-platform/scenario-desktop-app-configuration:
> "1. Under Manage, select Authentication > Add a platform > Mobile and desktop applications"
(Exact label is "Mobile and desktop applications", not "Mobile and desktop" alone.)

### invalid_scope with graph-prefixed IMAP scope

Sources disagree on the exact fix:

- Microsoft Q&A thread https://learn.microsoft.com/en-us/answers/questions/1019643/invalid-scope-error-when-using-auth-code-flow-for — user got `invalid_scope` using `https://outlook.office365.com/IMAP.AccessAsUser.All` for a personal account against `/common`; Microsoft support engineer's stated fix:
> "You just need to change `https://outlook.office365.com/IMAP.AccessAsUser.All` to `https://graph.microsoft.com/IMAP.AccessAsUser.All`, and Microsoft recommends using Microsoft Graph to access Outlook mail, calendar, and contacts."
  (i.e. fix direction `outlook.office365.com` → `graph.microsoft.com` in this thread)

- The official docs page (section above) instead specifies `https://outlook.office.com/IMAP.AccessAsUser.All` (`outlook.office.com`, not `outlook.office365.com`) as the correct scope prefix for IMAP.

- A secondary, not-independently-fetch-verified summary surfaced during search claimed: "outlook.office.com works as the scope FQDN but outlook.office365.com will not if you are attempting to support personal accounts... attempting to use a personal account with outlook.office365.com as the FQDN in the scope values will result in an invalid_scopes error," with corrected scopes given as `https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/POP.AccessAsUser.All https://outlook.office.com/SMTP.Send offline_access`. Not independently confirmed via direct fetch of the source page.

Net fact: the official Exchange docs page specifies `outlook.office.com` as the IMAP scope prefix; separate Microsoft Q&A community threads report `invalid_scope` errors tied to using `outlook.office365.com` instead, with inconsistent fix guidance (one thread recommends switching to `graph.microsoft.com`, not `outlook.office.com`).

---

## 5. Google — IMAP XOAUTH2, consent screen, IMAP status

### IMAP server/port

Source: https://developers.google.com/gmail/imap/imap-smtp
> "Incoming connections to the IMAP server at `imap.gmail.com:993` require SSL."

### SASL XOAUTH2 string format

Source: https://developers.google.com/workspace/gmail/imap/xoauth2-protocol
Format: `base64("user=" {User} "^Aauth=Bearer " {Access Token} "^A^A")`
> "`^A` represents a Control+A (\001)."
Example (unencoded) given on the page: `"user=someuser@example.com^Aauth=Bearer ya29.vF9dft4qmTc2Nvb3RlckBhdHRhdmlzdGEuY29tCg^A^A"`

### OAuth scope

Source: https://developers.google.com/workspace/gmail/imap/xoauth2-protocol
> "The scope for IMAP, POP, and SMTP access is `https://mail.google.com/`."

### Consent screen Testing mode

Source: https://support.google.com/cloud/answer/15549945?hl=en
> "Projects configured with a publishing status of Testing are limited to up to 100 test users listed in the OAuth consent screen."
> On refresh-token 7-day expiry: "If your OAuth client requests an `offline` access type and receives a refresh token, that token will also expire" after seven days (clause fragmented in the fetched page; researching agent flagged this specific sentence as worth re-verifying directly on the live page before quoting further, since the fetch returned it in fragments).

### Gmail IMAP default-on status (2025-2026)

Google Workspace admin help, https://knowledge.workspace.google.com/admin/sync/turn-pop-and-imap-on-or-off-for-users?hl=en (redirected from https://support.google.com/a/answer/105694?hl=en):
- Page's instructions begin with "Step 1: Turn on POP & IMAP," implying manual activation for Workspace admin-managed accounts, but the page contains no explicit sentence stating "IMAP is off/on by default."
- Page shows "Last updated 2026-09-18 UTC."
- This page concerns Google Workspace (managed) accounts, not necessarily personal/consumer Gmail accounts, which may differ. NOT FOUND: an explicit Google statement (on any official page located) that IMAP is enabled by default for personal/consumer Gmail accounts specifically.

---

## 6. iCloud Mail IMAP

Source: https://support.apple.com/en-us/102525

- Server name: "imap.mail.me.com"; Port: "993"
- Password: "Generate an app-specific password."
- Username: "This is usually the name of your iCloud Mail email address (for example, johnappleseed, not johnappleseed@icloud.com). If your email client app can't connect to iCloud Mail using just the name of your email address, try using the full address."
- For reference (same page), SMTP settings: Server name "smtp.mail.me.com", Port "587", with username guidance given as the full address ("johnappleseed@icloud.com, not johnappleseed") — noted as an asymmetry between the IMAP short-username guidance and SMTP full-address guidance stated on the same page.

---

## 7. Yahoo Mail IMAP

Server/port, source https://help.yahoo.com/kb/SLN4075.html:
> "Server - imap.mail.yahoo.com" and "Port - 993"

App password, source https://help.yahoo.com/kb/SLN15241.html:
> "Third-party email apps (that do not use our Yahoo branded sign-in page) require you to enter a single password for login credentials."
> "App passwords are randomly generated codes that let non-Yahoo email apps access your account when they don't use Yahoo's sign-in page."

NOT FOUND: an explicit official Yahoo sentence directly tying the app-password requirement specifically to "two-step verification being enabled" — SLN15241 does not state this connection explicitly in the fetched text (it only cross-references two-step verification as a "related article" with no stated causal link). A related page, https://help.yahoo.com/kb/SLN27791.html ("Ways to securely access Yahoo Mail"), was not fetched/verified verbatim in this research pass.

---

## 8. SoFriendly/2fhey (TwoFHey)

Repo: `https://github.com/SoFriendly/2fhey` (org `SoFriendly`, not archived at clone time). Commit at HEAD (default branch): `76a3c02df52ea98bba5263233ec337823310df07`, dated 2026-08-28. URLs use `https://github.com/SoFriendly/2fhey/blob/76a3c02df52ea98bba5263233ec337823310df07/<path>#L<n>`.

File: `TwoFHey/OTPParser/OTPParser.swift` (361 lines).

### Full public interface

Top-of-file comment, L1-9:
```
//
//  OTPParser.swift
//  2FHey
//
//  Extracts one-time codes from message text. Every candidate code must survive
//  the NumberGuard, which rejects anything that looks like a phone number, the
//  sender's own number, money, a time, or a date — so a phone number can never
//  be returned as a code.
//
```
Imports, L11-12: `import Foundation`, `import AppKit`.

`ParsedOTP`, L14-25:
```swift
struct ParsedOTP: Equatable {
    let service: String?
    let code: String

    /// Copies the code to the clipboard and returns the previous contents (for later restore).
    func copyToClipboard() -> String? {
        let original = AppStateManager.shared.restoreContentsEnabled ? NSPasteboard.general.string(forType: .string) : nil
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        return original
    }
}
```
Fact: `ParsedOTP`, `OTPParser`, and every method/property in the file carry no `public` keyword anywhere — all are implicit-`internal` or explicitly `private`/`private static`.

`OTPParser` class and nested types, L27-65:
```swift
final class OTPParser {
    private struct LanguageFile: Codable {
        let keywords: [String]
        let patterns: [String]
    }

    private struct CustomPatternsFile: Codable {
        struct Entry: Codable {
            let service: String
            let pattern: String
        }
        let customPatterns: [Entry]
    }

    private struct Configuration {
        var keywords: [String] = []
        var languagePatterns: [NSRegularExpression] = []
        var customPatterns: [(service: String, regex: NSRegularExpression)] = []
    }

    private static let languageFiles = ["en.json", "fr.json", "zh.json", "es.json", "de.json", "pt.json", "he.json"]
    private static let customPatternsFile = "custom-patterns.json"
    private static let remoteBaseURL = "https://raw.githubusercontent.com/SoFriendly/2fhey/main/TwoFHey/OTPKeywords"

    private let lock = NSLock()
    private var _configuration: Configuration
    private var configuration: Configuration {
        lock.lock()
        defer { lock.unlock() }
        return _configuration
    }

    init() {
        Self.clearCacheIfAppVersionChanged()
        _configuration = Self.loadConfiguration()
        Task.detached(priority: .utility) { [weak self] in
            await self?.refreshFromRemote()
        }
    }
```

Only non-private instance method (the parse entry point), L153-156:
```swift
/// Parses a message body for a one-time code. `sender` (a handle, phone number,
/// or notification title) is never searched for codes — it is only used to make
/// sure the sender's own number is never returned.
func parse(_ text: String, sender: String? = nil) -> ParsedOTP? {
```
All other methods (`clearCacheIfAppVersionChanged`, `loadConfiguration`, `fileData`, `cacheDirectory`, `refreshFromRemote`, `normalize`, `isPlausibleCode`, `stripURLs`, `extractService`) are `private`/`private static`.

`NumberGuard` helper struct, L306-330:
```swift
private struct NumberGuard {
    private static let forbiddenPatterns: [NSRegularExpression] = [ ... ]
    private let forbidden: [Range<String.Index>]
    private let senderDigits: String

    init(text: String, senderDigits: String) {
```
Its one non-private method, L355-360:
```swift
func allows(_ range: Range<String.Index>, code: String) -> Bool {
    if forbidden.contains(where: { $0.overlaps(range) }) { return false }
    let digits = String(code.filter(\.isNumber))
    if digits.count >= 4, senderDigits.contains(digits) { return false }
    return true
}
```

### Loading OTPKeywords/*.json and custom-patterns.json

L83-119:
```swift
private static func loadConfiguration() -> Configuration {
    var config = Configuration()
    for fileName in languageFiles {
        guard let data = fileData(fileName),
              let file = try? JSONDecoder().decode(LanguageFile.self, from: data) else { continue }
        config.keywords.append(contentsOf: file.keywords.map { $0.lowercased() })
        config.languagePatterns.append(contentsOf: file.patterns.compactMap {
            try? NSRegularExpression(pattern: $0, options: .caseInsensitive)
        })
    }
    if let data = fileData(customPatternsFile),
       let file = try? JSONDecoder().decode(CustomPatternsFile.self, from: data) {
        config.customPatterns = file.customPatterns.compactMap { entry in
            (try? NSRegularExpression(pattern: entry.pattern)).map { (entry.service, $0) }
        }
    }
    return config
}

private static func fileData(_ fileName: String) -> Data? {
    let cached = cacheDirectory().appendingPathComponent(fileName)
    if let data = try? Data(contentsOf: cached) {
        return data
    }
    let resource = (fileName as NSString).deletingPathExtension
    let bundle = Bundle(for: OTPParser.self)
    let url = bundle.url(forResource: resource, withExtension: "json", subdirectory: "OTPKeywords")
        ?? bundle.url(forResource: resource, withExtension: "json")
    return url.flatMap { try? Data(contentsOf: $0) }
}

private static func cacheDirectory() -> URL {
    let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("OTPKeywords")
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}
```
Remote refresh (downloads updated pattern files from GitHub at runtime, caches them), L124-151:
```swift
private func refreshFromRemote() async {
    var updatedAny = false
    for fileName in Self.languageFiles + [Self.customPatternsFile] {
        guard let url = URL(string: "\(Self.remoteBaseURL)/\(fileName)"),
              let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200 else { continue }

        let isValid = fileName == Self.customPatternsFile
            ? (try? JSONDecoder().decode(CustomPatternsFile.self, from: data)) != nil
            : (try? JSONDecoder().decode(LanguageFile.self, from: data)) != nil
        guard isValid else { continue }

        do {
            try data.write(to: Self.cacheDirectory().appendingPathComponent(fileName))
            updatedAny = true
        } catch {
            DebugLogger.shared.log("Failed to cache pattern file", category: "PARSER", data: fileName)
        }
    }

    if updatedAny {
        let refreshed = Self.loadConfiguration()
        lock.lock()
        _configuration = refreshed
        lock.unlock()
        DebugLogger.shared.log("Pattern files refreshed from GitHub", category: "PARSER")
    }
}
```
Remote base URL constant (L49): `"https://raw.githubusercontent.com/SoFriendly/2fhey/main/TwoFHey/OTPKeywords"`.

### JSON schema, verbatim excerpts

`TwoFHey/OTPKeywords/en.json` (full file):
```json
{
  "keywords": [
    "code", "verification", "verify", "otp", "pin", "authentication",
    "authenticate", "auth", "security", "2fa", "two-factor", "2-factor",
    "confirmation", "confirm", "activate", "activation", "passcode",
    "password", "one-time", "validation"
  ],
  "patterns": [
    "([A-Za-z0-9]{4,8})\\s+is\\s+(?:your|the)\\s+(?:[A-Za-z][\\w.'-]*\\s+){0,3}?(?:code|otp|pin|passcode|password)\\b",
    "(?:code|otp|pin|passcode|password)\\s+is[\\s:]+([A-Za-z0-9-]{4,10})",
    "use[,\\s:]+([A-Za-z0-9-]{4,10})"
  ]
}
```
(16 patterns total in the source file; only the first three quoted above.) Schema: top-level object `{"keywords": [String], "patterns": [String]}` (regex source strings), decoded by `LanguageFile: Codable`.

`TwoFHey/OTPKeywords/custom-patterns.json` (excerpt, first entries):
```json
{
  "customPatterns": [
    {
      "service": "DBS Bank",
      "pattern": "use [A-Z]{3}-([0-9]{6}) within"
    },
    {
      "service": "MIGov",
      "pattern": "Your passcode is[\\s\\n]+(\\d{4})-(\\d{6})"
    },
    {
      "service": "pf-bank",
      "pattern": "^([0-9]{8})[\\s\\n]+Valid"
    }
  ]
}
```
Schema: top-level object `{"customPatterns": [{"service": String, "pattern": String}]}`, decoded by `CustomPatternsFile: Codable` / `CustomPatternsFile.Entry: Codable`.

Other language files present (filenames only, not read in full): `de.json`, `es.json`, `fr.json`, `he.json`, `pt.json`, `zh.json`, all in `TwoFHey/OTPKeywords/`.

### LICENSE

Root `LICENSE` file confirmed to be CC0 1.0 Universal. Opening lines quoted verbatim:
```
Creative Commons Legal Code

CC0 1.0 Universal

    CREATIVE COMMONS CORPORATION IS NOT A LAW FIRM AND DOES NOT PROVIDE
    LEGAL SERVICES. DISTRIBUTION OF THIS DOCUMENT DOES NOT CREATE AN
    ATTORNEY-CLIENT RELATIONSHIP. ...
```
Full "Statement of Purpose" and Waiver/Public License Fallback/Limitations sections present as the standard CC0 1.0 Universal legal text.

### macOS-only APIs

- L12: `import AppKit` (explicit macOS-only framework import in `OTPParser.swift`).
- `NSRegularExpression` used 16 times in the file — a Foundation type, cross-platform, not macOS-exclusive.
- `ParsedOTP.copyToClipboard()` (L19-24) uses `NSPasteboard` (AppKit, macOS-only): `NSPasteboard.general.string(forType:)`, `.clearContents()`, `.setString(_:forType:)`.
- Repo-wide grep for `import AppKit` also found it in `TwoFHey/Services/GoogleMessagesSetupService.swift` — one other file, not an exhaustive search of every file for additional AppKit-only symbols.
- Project structure is a native macOS menu-bar app (`TwoFHey.xcodeproj`, `AppIcon.icon`, `AutoLauncher`, bundled `Google Messages.dmg`).

---

## Gaps (not found after search)

- **SwiftMail**: no README code example covering the full connect → login → selectMailbox → search → fetch flow (only the in-source doc comment shows connect/login).
- **SwiftMail**: `APPLICATION_EXTENSION_API_ONLY` — no occurrence anywhere in the repo at tag 1.12.0.
- **AppAuth-iOS**: README.md has no discussion of app-extension usage; only CHANGELOG.md documents that `AppAuthCore` was split out "to support iOS extensions" (2018 entry), with no elaboration on whether this covers token refresh only vs. full auth flow. No GitHub issue found confirming/denying extension safety for `performActionWithFreshTokens:`.
- **Microsoft**: no official-docs sentence explicitly instructing use of `/consumers` (vs `/common`) specifically for personal accounts — only a community Q&A thread makes this claim.
- **Microsoft**: the `invalid_scope` fix for graph-prefixed IMAP scopes is inconsistently sourced — one Microsoft Q&A thread says switch to `graph.microsoft.com`-prefixed scope; the official docs specify `outlook.office.com`-prefixed scope; a third, unverified source claims `outlook.office365.com` is the broken one. No single authoritative source reconciles these.
- **Google**: exact full sentence on refresh-token 7-day expiry in Testing mode was returned fragmented by the fetch; needs re-verification directly against the live support.google.com page for an exact quote.
- **Google**: no official statement located (Workspace admin docs only cover managed accounts) confirming IMAP is enabled by default for personal/consumer Gmail accounts specifically.
- **Yahoo**: no official Yahoo text explicitly tying the app-password requirement to two-step verification being enabled; related page https://help.yahoo.com/kb/SLN27791.html not verified verbatim in this pass.
