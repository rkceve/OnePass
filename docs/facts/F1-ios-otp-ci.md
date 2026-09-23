# F1 — iOS AutoFill One-Time-Code Credential Provider + CI Facts

Fact-collection only. No recommendations, conclusions, or design suggestions. Every fact below is quoted/paraphrased with its exact source. Anything not found is listed under **Gaps**.

---

## 1. AuthenticationServices one-time-code support (iOS 18+)

### `ASOneTimeCodeCredentialIdentity`
```swift
class ASOneTimeCodeCredentialIdentity
```
Initializer:
```swift
init(serviceIdentifier: ASCredentialServiceIdentifier, label: String, recordIdentifier: String?)
init?(coder: NSCoder)
```
Property: `var label: String`
Availability: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, visionOS 2.0+
Overview (quoted): "An `ASOneTimeCodeCredentialIdentity` is used to describe an identity that can use a service upon successful one-time code based authentication. Use this class to save entries into `ASCredentialIdentityStore`."
Source: https://developer.apple.com/tutorials/data/documentation/authenticationservices/asonetimecodecredentialidentity.json

### `ASOneTimeCodeCredential`
```swift
class ASOneTimeCodeCredential
```
Initializer:
```swift
init(code: String)
```
Property: `var code: String`
Availability: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, visionOS 2.0+
Inherits from `NSObject`; conforms to `ASAuthorizationCredential`, `NSSecureCoding`, `Sendable`, etc.
Source: https://developer.apple.com/tutorials/data/documentation/authenticationservices/asonetimecodecredential.json

### `ASOneTimeCodeCredentialRequest`
```swift
class ASOneTimeCodeCredentialRequest
```
Initializers:
```swift
init(credentialIdentity: ASOneTimeCodeCredentialIdentity)
init?(coder: NSCoder)
```
Conforms to `ASCredentialRequest`. Availability: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, visionOS 2.0+
Source: https://developer.apple.com/tutorials/data/documentation/authenticationservices/asonetimecodecredentialrequest.json

### `ASCredentialIdentityStore` — save/replace/remove/getState
(These methods are generic — they take `any ASCredentialIdentity`, which `ASOneTimeCodeCredentialIdentity` conforms to; there are no OTP-specific overloads.)
```swift
func getState(_ completion: @escaping (ASCredentialIdentityStoreState) -> Void)
func saveCredentialIdentities(_ credentialIdentities: [any ASCredentialIdentity], completion: ((Bool, (any Error)?) -> Void)?)
func replaceCredentialIdentities(_ credentialIdentities: [any ASCredentialIdentity], completion: ((Bool, (any Error)?) -> Void)?)
func removeCredentialIdentities(_ credentialIdentities: [any ASCredentialIdentity], completion: ((Bool, (any Error)?) -> Void)?)
func removeAllCredentialIdentities(_ completion: ((Bool, (any Error)?) -> Void)?)
```
Availability shown for these signatures: iOS 12.0+, iPadOS 12.0+, macOS 11.0+, Mac Catalyst 14.0+, visionOS 1.0+ (i.e., these are the pre-existing generic methods; OTP support comes via the `ASOneTimeCodeCredentialIdentity` type being a conforming `ASCredentialIdentity`, not via new store methods).
Source: https://developer.apple.com/tutorials/data/documentation/authenticationservices/ascredentialidentitystore.json
Note: "Use incremental change methods (save/remove) instead of replace when possible to avoid rewriting the entire store" and "When the extension is disabled, the system clears and disables the shared store" are stated in the same source page's guidance text.

### `ASCredentialProviderViewController.provideCredentialWithoutUserInteraction(for:)`
```swift
func provideCredentialWithoutUserInteraction(for credentialRequest: any ASCredentialRequest)
```
Availability: iOS 17.0+, iPadOS 17.0+, Mac Catalyst 17.0+, macOS 14.0+, visionOS 1.0+
Discussion (quoted/paraphrased): "After the person selects a credential identity, the system creates a credential request. The contents depend on the credential type: Password or OTP requests: the request (`ASPasswordCredentialRequest` or `ASOneTimeCodeCredentialRequest`) contains a credential identity... OTP credentials: `completeOneTimeCodeRequest(using:completionHandler:)`... Your view controller isn't presented during this method call, so don't show or use any user interface from this method."
Source: https://developer.apple.com/tutorials/data/documentation/authenticationservices/ascredentialproviderviewcontroller/providecredentialwithoutuserinteraction(for:)-3mo23.json

### `prepareOneTimeCodeCredentialList(for:)`
```swift
func prepareOneTimeCodeCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier])
```
Availability: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, visionOS 2.0+
Discussion (quoted): "The system calls this method to tell your extension's view controller to prepare a list of OTPs to present. After calling this method, the system presents the view controller to the person. Use the given `serviceIdentifiers` array to filter or prioritize the credentials to display... Items in the array with lower indices represent more specific identifiers for which an OTP is requested... When someone selects an OTP, represent the passcode as an `ASOneTimeCodeCredential` and pass it to the system by calling `completeOneTimeCodeRequest(using:completionHandler:)`... Always provide a way for someone to cancel the operation from your view controller (e.g., with a Cancel button). When cancelled, call `cancelRequest(withError:)` with error domain `ASExtensionErrorDomain` and code `ASExtensionError.userCanceled`."
Source: https://developer.apple.com/tutorials/data/documentation/authenticationservices/ascredentialproviderviewcontroller/prepareonetimecodecredentiallist(for:).json

### `prepareInterfaceToProvideCredential(for:)`
```swift
func prepareInterfaceToProvideCredential(for credentialRequest: any ASCredentialRequest)
```
Availability: iOS 17.0+, iPadOS 17.0+, Mac Catalyst 17.0+, macOS 14.0+, visionOS 1.0+
Discussion (quoted): "The system calls this method when your extension can't supply the requested credential without user interaction. Limit user interaction to operations required for providing the requested credential... For one-time passcodes: `completeOneTimeCodeRequest(using:completionHandler:)`... For errors, call `cancelRequest(withError:)` with `ASExtensionErrorDomain` and an appropriate error code (e.g., `ASExtensionError.Code.credentialIdentityNotFound`)."
Source: https://developer.apple.com/tutorials/data/documentation/authenticationservices/ascredentialproviderviewcontroller/prepareinterfacetoprovidecredential(for:)-68qpo.json

### `ASCredentialProviderExtensionContext.completeOneTimeCodeRequest(using:completionHandler:)`
```swift
func completeOneTimeCodeRequest(
    using credential: ASOneTimeCodeCredential,
    completionHandler: (@Sendable (Bool) -> Void)? = nil
)
func completeOneTimeCodeRequest(using credential: ASOneTimeCodeCredential) async -> Bool
```
Availability: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, visionOS 2.0+
Parameters (quoted): "credential: The OTP credential chosen by the person. completionHandler (optional): Optional work that the extension performs as a background priority task after the request completes. The `expired` parameter is `YES` if the system prematurely terminates a previous non-expiration invocation of the `completionHandler`"
Source: https://developer.apple.com/tutorials/data/documentation/authenticationservices/ascredentialproviderextensioncontext/completeonetimecoderequest(using:completionhandler:).json

### `cancelRequest(withError:)`
```swift
func cancelRequest(withError error: any Error)
```
Availability: iOS 12.0+, iPadOS 12.0+, Mac Catalyst 14.0+, macOS 11.0+, visionOS 1.0+
Quoted: "This instance method on `ASCredentialProviderExtensionContext` cancels the credential provider request and dismisses the extension's view controller automatically." Parameter guidance: "The `error` parameter should use an error domain of `ASExtensionErrorDomain` and a code of type `ASExtensionError.Code`."
Source: https://developer.apple.com/tutorials/data/documentation/authenticationservices/ascredentialproviderextensioncontext/cancelrequest(witherror:).json

### `ASExtensionError.Code` values
Cases found: `credentialIdentityNotFound`, `failed`, `userCanceled`, `userInteractionRequired`, `matchedExcludedCredential`.
Quoted description for `matchedExcludedCredential`: "This error should only be used for a passkey registration request, if the `excludedCredentials` property matches a known passkey."
Note: the availability shown by the fetch for all cases was "iOS 12.0+ / iPadOS 12.0+ / Mac Catalyst 14.0+ / macOS 11.0+ / visionOS 1.0+" for every case including `matchedExcludedCredential`, which is inconsistent with `matchedExcludedCredential` being passkey-related (passkeys were introduced later). This is flagged as unverified/possibly a fetch-summarization artifact — see Gaps.
Source: https://developer.apple.com/tutorials/data/documentation/authenticationservices/asextensionerror/code.json
Cross-reference (from the OTP article, see below): the code used for the "extension needs to present UI" case is `ASExtensionError.Code.userInteractionRequired`.

### `ASCredentialRequestType.oneTimeCode`
Cases found: `passkeyAssertion`, `passkeyRegistration`, `password`, `oneTimeCode`.
Quoted description for `oneTimeCode`: "The app or website is requesting a one-time passcode."
Availability shown for all cases: iOS 17.0+, iPadOS 17.0+, Mac Catalyst 17.0+, macOS 14.0+, visionOS 1.0+
Source: https://developer.apple.com/tutorials/data/documentation/authenticationservices/ascredentialrequesttype.json

### Official article: "Providing one-time passcodes to AutoFill"
Full article text (verbatim, retrieved via JSON data endpoint):

> ## Overview
> Many online services rely on one-time passcodes (OTPs), particularly time-based one-time passcodes (TOTP), as an additional factor when someone authenticates with the service. For example, a website might ask someone to provide their username, a password which the person knows, and a TOTP generated by the person's authenticator app to enter the site.
> Your credential provider extension can supply OTPs to AutoFill so that people can automatically fill out passcodes in apps and on websites. Someone can configure multiple credential providers in Settings so that different apps supply their passwords and OTPs in AutoFill.
>
> ### Indicate that your extension provides OTPs
> Open your credential provider extension's information property list file in Xcode and add a key to the `ASCredentialProviderExtensionCapabilities` dictionary. Set the key's name to `ProvidesOneTimeCodes`, and its value to the Boolean `true`.
>
> ### Respond to system requests for OTP AutoFill
> The system calls your credential provider view controller's `provideCredentialWithoutUserInteraction(for:)` method with a request type of `ASCredentialRequestType.oneTimeCode` to request an OTP. If your credential provider extension can provide the code without presenting UI, call `completeOneTimeCodeRequest(using:completionHandler:)` to supply the text to the system.
> Otherwise, if your credential provider extension needs to present UI to provide the OTP, call `cancelRequest(withError:)`. Use the error domain `ASExtensionErrorDomain`, and the code `ASExtensionError.Code.userInteractionRequired`. The system calls `prepareInterfaceToProvideCredential(for:)`. In your implementation, present the UI you need for someone to choose the OTP for the request. Call `completeOneTimeCodeRequest(using:completionHandler:)` to supply the text to the system, or `cancelRequest(withError:)` to inform the system if an error occurs.
>
> ### Provide a list of available OTPs
> When someone uses a text field to complete an OTP using AutoFill, they can tap a button to see a list of all available OTPs. The system calls `prepareOneTimeCodeCredentialList(for:)` to get the list of OTPs from your extension, then presents your controller.
>
> Copyright © 2026 Apple Inc.

Source: https://developer.apple.com/tutorials/data/documentation/authenticationservices/providing-one-time-passcodes-to-autofill.md

### `Info.plist` keys under `ASCredentialProviderExtensionCapabilities`
Keys found: `ProvidesPasskeys`, `ProvidesPasswords`, `SupportsConditionalPasskeyRegistration`, `ProvidesOneTimeCodes`, `ProvidesTextToInsert`, `ShowsConfigurationUI`. All are Boolean.
Quoted description for `ProvidesOneTimeCodes`: "Allows the credential provider to show up in one-time-code text fields for filling time-based verification codes."
Quoted description for `ProvidesTextToInsert`: "Allows the credential provider to show up in the system AutoFill context menu for filling text in any text field."
Availability shown for the whole family: iOS 17.0+, iPadOS 17.0+, Mac Catalyst 17.0+, macOS 14.0+ (note: the OTP article above states `ProvidesOneTimeCodes` is used for OTP support introduced with iOS 18 APIs; the exact per-key availability floor for `ProvidesOneTimeCodes` specifically was not independently confirmed — see Gaps).
Source: https://developer.apple.com/tutorials/data/documentation/authenticationservices/ascredentialproviderextensioncapabilities.json (fetched via the parent path; direct `.../providesonetimecodes.json` endpoint returned HTTP 404)

### `ASSettingsHelper`
```swift
class func openCredentialProviderAppSettings(completionHandler: (((any Error)?) -> Void)?)
class func openVerificationCodeAppSettings(completionHandler: (((any Error)?) -> Void)?)
class func requestToTurnOnCredentialProviderExtension(completionHandler: (Bool) -> Void)
```
Quoted description for `requestToTurnOnCredentialProviderExtension`: "Call this method from your containing app to request to turn on a contained Credential Provider Extension. If the extension is not currently enabled, a prompt will be shown to allow it to be turned on. The completion handler is called with YES or NO depending on whether the credential provider is enabled." Also noted: "You must wait 10 seconds before making additional requests to this API."
Availability: iOS 17.0+, iPadOS 17.0+, Mac Catalyst 17.0+, macOS 14.0+, visionOS 1.0+ (all three methods)
Source: https://developer.apple.com/tutorials/data/documentation/authenticationservices/assettingshelper.json

---

## 2. QuickType bar display of third-party OTP identity / iOS 18.4+ regression

### How the OTP list is triggered (Apple Staff forum reply, verbatim)
> "On iOS, `ASCredentialProviderViewController.prepareOneTimeCodeCredentialList(for:)` is called from Safari when a user focuses a one time code field and taps the key icon in the QuickType bar to see more suggestions. If you do this and still don't see your method being called, please file a Feedback with a sysdiagnose and we will be happy to investigate further."
Source: https://developer.apple.com/forums/thread/762086 ("One Time Codes" thread, Apple Staff reply, Aug '24)

Original poster's setup in the same thread (verbatim):
> "1. I've added the `ProvidesOneTimeCodes` key to the Info.plist. 2. I've added the `com.apple.developer.authentication-services.autofill-credential-provider` entitlement... 4. The app is enabled in the `AUTOFILL FROM:` in Settings App."
Source: https://developer.apple.com/forums/thread/762086

No official Apple document (HTML doc, JSON endpoint, or WWDC24 session transcript search) was found describing the exact QuickType bar suggestion text/label format (e.g., whether it shows app name + code, or just code) for a third-party one-time-code identity. WWDC24 "What's new in privacy" (session 10123, https://developer.apple.com/videos/play/wwdc2024/10123/) was identified as the relevant session by title, but its transcript content specific to OTP QuickType bar label formatting was not retrieved — see Gaps.

### iOS 18.4+ regression: `prepareInterfaceToProvideCredential` `.oneTimeCode` not called
Thread: "prepareInterfaceToProvideCredential .oneTimeCode case is not called" — https://developer.apple.com/forums/thread/782865

Original post (verbatim, author ArnasPeciukonis, Apr '25):
> "Since release of 18.4. prepareInterfaceToProvideCredential .oneTimeCode case is not called and instead prepareInterfaceForUserChoosingTextToInsert() is called. That is the wrong delegate for this case and it causes confusion for the users.
> Also, some TOTP fields are recognised however, the key icon button is not presented above the keyboard next to TOTP suggestions.
> I've also tested 18.5 and it has the same issue. provideOneTimeCodeWithoutUserInteraction works just fine."

Replies (verbatim):
> Systems Engineer (Apple Staff), May '25: "Thanks for letting us know! Can you please file this through Feedback Assistant?"
> Asquare17, May '25: "@Systems Engineer Any update on this, pls?"
> ronz, Aug '26: "Still happening"

Status as of the latest reply found (Aug 2026): unresolved. No statement of a fix in iOS 26 was found in this thread or via search; the most recent reply (Aug '26, "Still happening") postdates the iOS 26 GA release, indicating the regression was still being reported after iOS 26 shipped, per this single forum report.
Source: https://developer.apple.com/forums/thread/782865

### `prepareInterfaceForUserChoosingTextToInsert()` — how to trigger it (Apple Staff reply, verbatim)
> "Once you have implemented the API and enabled your extension in Settings > General > AutoFill & Passwords, you can tap twice or long press in any text field to bring up the callout bar (the UI for actions like Copy or Paste) and from there select AutoFill > Passwords to show your extension UI. Note that this API is for iOS only."
Source: https://developer.apple.com/forums/thread/762705 ("How to test/trigger 'prepareInterfaceForUserChoosingTextToInsert'")

### Related bug report (not confirmed to be the same regression)
Thread: "ASCredentialProviderExtensionContext completeRequestWithTextToInsert:completionHandler: sometimes fails to return text" — https://developer.apple.com/forums/thread/776124
Original post summary (author michaelr, Mar '25, environment iOS 18.3.1, Feedback Assistant report FB16788563): describes `completeRequestWithTextToInsert:completionHandler:` "frequently fails on first invocation during debugger testing," occurring "intermittently in released app extensions" and in the native Passwords app. Reproduction steps given: reboot iPhone, App Library → right-click Autofill → Passwords → Passwords (App) → select a password → expected password inserted, actual: nothing inserted (intermittently). Thread had 0 replies as fetched.

### Related thread: two iOS 18 methods required to avoid "AutoFill Unavailable" error
Thread: https://developer.apple.com/forums/thread/770824
Original poster (DrD, Dec '24) reported an "AutoFill Unavailable — The developer needs to update it to work with this feature" error dialog when tapping AutoFill from the context menu, despite the extension working via the Passwords bar above the keyboard.
Reply (michaelr, Mar '25, verbatim as fetched): "iOS 18 introduced two new methods that must be implemented: 1. `ASCredentialProviderViewController prepareInterfaceForUserChoosingTextToInsert` 2. `ASCredentialProviderExtensionContext completeRequestWithTextToInsert:completionHandler:`... This is the interface required to satisfy such requests. If it doesn't exist and your credential provider is the only one selected you will see that message."

---

## 3. Credential provider extensions in iOS Simulator

- General setting path referenced across multiple forum threads: **Settings > General > AutoFill & Passwords** (this is the enable path stated in the Apple Staff reply quoted in §2, in the context of a device/simulator running the extension).
- No official Apple document was found explicitly confirming or denying that credential provider extensions can be enabled and tested in the iOS Simulator via Settings > General > AutoFill & Passwords. Forum/search evidence found is indirect:
  - A search-result summary (not a verbatim quote) stated: "Timeout doesn't happen for debug builds, or when running on the simulator, so you can take your time to debug the extension without the system interrupting" — source unclear (aggregated from search snippet, not fetched from a single verified page); treat as unverified.
  - A search-result summary noted "Password AutoFill works on device but not in the simulator when using local servers with Associated Domains" — this pertains to Associated Domains / web credential matching, not credential-provider-extension enablement generally, and was not independently verified against a primary source.
- No known-limitations list specific to credential provider extensions on Simulator (e.g., OTP list, QuickType key icon, biometric prompts) was found in an official or authoritative source during this research pass.

---

## 4. XCUITest: cross-app driving, QuickType tap, hardware keyboard in CI

### `XCUIApplication(bundleIdentifier:)` for other apps
Confirmed via community source (testableapple.com) with code examples, not an official Apple doc:
```swift
let app = XCUIApplication(bundleIdentifier: "com.my.app")

override func setUp() {
    super.setUp()
    app.launch()
}
```
```swift
enum Alert: String {
    case left, right, ok
}
func alert(button: Alert) {
    let buttonIndex = (.right == button) ? 2 : 1
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let alertBtn = springboard.buttons.element(boundBy: buttonIndex)
    if alertBtn.exists { alertBtn.tap() }
}
```
Quoted: "any app installed in the system is open to us" — "with great power there must also come great responsibility."
Source: https://testableapple.com/test-multiple-apps-using-bundle-identifier-in-xctest/
Note: this source demonstrates the technique generically (using `com.apple.springboard` as the example bundle ID for system alerts) but does NOT explicitly demonstrate or confirm `com.apple.Preferences` (Settings) or `com.apple.mobilesafari` (Safari) by bundle ID in the fetched excerpt — see Gaps.

### Tapping QuickType/AutoFill suggestion buttons above the keyboard
No official Apple document or forum post was found in this research pass that describes the exact accessibility-hierarchy representation (element type, identifier, or label) of the QuickType/AutoFill suggestion bar buttons for XCUITest purposes. General XCUITest guidance found (not specific to QuickType): elements are queried via the accessibility tree using identifiers/labels, and Accessibility Inspector can be used to inspect the hierarchy — this is generic XCUITest guidance, not OTP/QuickType-specific. — see Gaps.

### Hardware keyboard disabling in CI
Two mechanisms found in a community reference repository (not an official Apple document):
1. `defaults`/PlistBuddy approach, targeting `~/Library/Preferences/com.apple.iphonesimulator.plist`, keyed per-simulator by UDID:
```bash
/usr/libexec/PlistBuddy -c "add :DevicePreferences:${udid}:ConnectHardwareKeyboard bool false" ${plist_file_path}
# or, if the entry already exists:
/usr/libexec/PlistBuddy -c "set :DevicePreferences:${udid}:ConnectHardwareKeyboard false" ${plist_file_path}
```
2. AppleScript/UI-automation approach (toggling via the Simulator app's menu shortcut):
```applescript
tell application "Simulator" to activate
tell application "System Events"
    keystroke "K" using {command down, shift down}
end tell
```
Source: https://github.com/vinceplusplus/ios-simulator-keyboard-and-ci/blob/main/README.md
Note: the simpler global form `defaults write com.apple.iphonesimulator ConnectHardwareKeyboard 0` (without a per-UDID key) was referenced in search-result summaries as an older/less reliable method superseded by the per-UDID PlistBuddy approach, but the exact verbatim source page for that simpler global command was not independently fetched/confirmed in this pass — see Gaps.

---

## 5. GitHub Actions macOS runner images (as of Sept 2026)

### Image labels and installed Xcode versions (macos-15 image)
Fetched directly from the runner-images repository README for the `macos-15` image:
```
Version | Build | Path
26.3   | 17C529   | /Applications/Xcode_26.3.app
26.2   | 17C52    | /Applications/Xcode_26.2.app
26.1.1 | 17B100   | /Applications/Xcode_26.1.1.app
26.0.1 | 17A400   | /Applications/Xcode_26.0.1.app
16.4 (default) | 16F6     | /Applications/Xcode_16.4.app
16.3   | 16E140   | /Applications/Xcode_16.3.app
16.2   | 16C5032a | /Applications/Xcode_16.2.app
16.1   | 16B40    | /Applications/Xcode_16.1.app
16.0   | 16A242d  | /Applications/Xcode_16.app
```
iOS simulator runtimes listed for this image (per the "Installed Simulators" section, paraphrased from fetch): iOS 18.5, iOS 18.6, iOS 26.0, iOS 26.1, iOS 26.2, with device lineups including iPhone 16/16 Plus/16 Pro/16 Pro Max/16e, iPhone SE (3rd gen), various iPad models for 18.5/18.6; and additionally iPhone 17 series, iPhone Air, iPad Pro 11-inch (M5)/13-inch (M5) for 26.0/26.1/26.2. (tvOS/watchOS/visionOS simulators also present, not itemized here.)
`XcodeGen`: searched the full document text — does NOT appear anywhere (case-sensitive or insensitive search returned no match).
Source: https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md

### Other image labels found to exist (repository file listing, from search results)
File names found via search (existence confirmed by search result titles, contents not fetched in this pass): `macos-14-Readme.md`, `macos-14-arm64-Readme.md`, `macos-15-Readme.md`, `macos-15-arm64-Readme.md`, `macos-26-Readme.md`, `macos-26-arm64-Readme.md`, `xcode-27-arm64-Readme.md`.
Source (listing page): https://github.com/actions/runner-images/tree/main/images/macos
Note: contents of `macos-26-Readme.md`, `macos-26-arm64-Readme.md`, `macos-14*-Readme.md`, and `xcode-27-arm64-Readme.md` (exact Xcode/simulator versions, XcodeGen presence) were NOT individually fetched/quoted in this pass — see Gaps.

### `macos-latest` label transition
Search-result summary (not independently verified against a primary changelog source in this pass): "The `macos-latest` label will use macos-26 in June 2026." — see Gaps for primary-source confirmation.

### Homebrew presence
Search-result summary: "Homebrew (Version 5.1.1) is pre-installed in the macOS images" — exact source page not individually re-fetched/quoted verbatim in this pass; treat as unverified pending primary-source confirmation — see Gaps.

### Free minutes for public repos
GitHub Docs (billing page), quoted/paraphrased from fetch:
> "The use of standard GitHub-hosted runners is free" for public repositories (along with GitHub Pages and Dependabot). "Larger runners are always charged for, even when used by public repositories."
Source: https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions

Per-minute rate table found on the same fetch (2026 rates, standard 2-core hosted runners):
| Operating System | Per-minute Rate |
|---|---|
| Linux 1-core (x64) | $0.002 |
| Linux 2-core (x64) | $0.006 |
| Linux 2-core (arm64) | $0.005 |
| Windows 2-core (x64) | $0.010 |
| Windows 2-core (arm64) | $0.010 |
| macOS 3-core or 4-core | $0.062 |
Source: https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions

GitHub Changelog (2025-12-16 pricing update post), quoted verbatim fragment: "Runner usage in public repositories will remain free."
Source: https://github.blog/changelog/2025-12-16-coming-soon-simpler-pricing-and-a-better-experience-for-github-actions/
Note: this changelog post fetch did not surface an explicit macOS-multiplier statement in the retrieved excerpt (a 10x-vs-Linux multiplier figure appeared only in secondary/aggregator search-result summaries, not confirmed verbatim from a primary GitHub source in this pass) — see Gaps.

### `xcrun simctl io <device> recordVideo`
Flags found (via search-result summaries, not a single fetched primary doc page — `simctl` has no web-hosted man page; canonical source is `xcrun simctl io help` on-device):
- `--codec`: `"h264"` or `"hevc"`, default `"hevc"`
- `--display`: `"internal"` or `"external"` (iOS), default `"internal"`
- `--mask`: `"ignored"` or `"black"` (for non-rectangular displays)
- `--force`: overwrite existing output file
Example command found: `xcrun simctl io booted recordVideo --code=h264 --mask=black --force myVideo.mov`
Source (aggregated from search snippets referencing `xcrun simctl io help` output; primary source is the command itself, not a web page): no single authoritative web URL exists for this (Apple does not publish `simctl` help text as a web doc) — see Gaps for verification via `xcrun simctl io help` execution.

### `simctl status_bar` override
Example command found: `xcrun simctl status_bar "iPhone 11" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100`
Quoted: "Running `xcrun simctl status_bar` in your terminal will print a usage explanation and the list of possible override options." "The status bar will immediately show the specified time, but the actual system time doesn't change — only the display."
Source (blog post referenced by search, not independently re-fetched for verbatim confirmation in this pass): Jesse Squires, "Overriding status bar display settings in the iOS simulator," https://www.jessesquires.com/blog/2019/09/26/overriding-status-bar-settings-ios-simulator/ — see Gaps (this is a third-party blog, not an Apple primary source; `simctl status_bar` has no official Apple web documentation).

---

## 6. Simulator screenshot pixel size (iPhone 16 / 16 Pro / iPhone 17)

From Apple's official App Store Connect screenshot specifications page, full "6.3\" Display" row quoted:
> **Devices:** iPhone 18 Pro, iPhone 17 Pro, iPhone 17, iPhone 16 Pro, iPhone 16, iPhone 15 Pro, iPhone 15, iPhone 14 Pro
> **Screenshot sizes:** 1179 x 2556 pixels (portrait), 2556 x 1179 pixels (landscape), 1206 x 2622 pixels (portrait), 2622 x 1206 pixels (landscape)

This confirms iPhone 16, iPhone 16 Pro, and iPhone 17 are all grouped under the "6.3\" Display" category, with **1179 x 2556 pixels (portrait)** as (one of) the accepted screenshot sizes for that group.
Note: the same 6.3" row lists a second pixel size pair (1206 x 2622 / 2622 x 1206) as also valid for this device group — the page does not explicitly disambiguate which exact device within the group maps to which of the two portrait sizes (1179x2556 vs 1206x2622) in the fetched excerpt; this distinction was not resolved in this research pass — see Gaps. This pixel size is the App Store Connect screenshot submission size specification, not independently cross-checked against actual `xcrun simctl` device `.plist` / UIScreen native pixel dimensions for the iOS Simulator in this pass.
Source: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/

---

## Gaps

1. **`ASExtensionError.Code` per-case availability**: the fetch reported identical iOS 12.0+ availability for all cases including `matchedExcludedCredential`, which is inconsistent with that case being passkey-specific (passkeys shipped later than iOS 12). Not independently re-verified against the raw JSON payload.
2. **QuickType bar exact suggestion text/label** for a third-party one-time-code identity (label vs. app name vs. code shown) — no official doc, WWDC24 transcript text, or forum post with this specific detail was retrieved.
3. **WWDC24 "What's new in privacy" (session 10123) transcript** — session identified by title/URL (https://developer.apple.com/videos/play/wwdc2024/10123/) but transcript content was not fetched/quoted in this pass.
4. **iOS 26 fix status for the `prepareInterfaceForUserChoosingTextToInsert` regression** — only evidence found is a single forum reply dated Aug '26 ("Still happening") in thread 782865, which post-dates iOS 26 GA but does not explicitly state which iOS build was being tested. No official release notes or Apple statement confirming or denying a fix were found.
5. **iOS Simulator support for credential provider extensions** — no official Apple document confirming/denying this, or listing known limitations, was found.
6. **XCUITest tapping of QuickType/AutoFill suggestion elements** — no source found describing the exact accessibility hierarchy (element type/identifier/label) for these buttons.
7. **`XCUIApplication(bundleIdentifier:)` explicitly demonstrated for `com.apple.Preferences` and `com.apple.mobilesafari`** — the fetched community source demonstrated the pattern generically and with `com.apple.springboard`, not explicitly with these two bundle IDs.
8. **Simple global `defaults write com.apple.iphonesimulator ConnectHardwareKeyboard 0` form** — referenced only in aggregated search summaries, not fetched/quoted from a primary source; the per-UDID PlistBuddy form was the only one directly confirmed from a fetched page.
9. **Full content of `macos-26-Readme.md`, `macos-26-arm64-Readme.md`, `macos-14-Readme.md`, `macos-14-arm64-Readme.md`, `macos-15-arm64-Readme.md`, `xcode-27-arm64-Readme.md`** — existence confirmed, but exact installed Xcode versions, simulator runtimes, and XcodeGen presence were not individually fetched/quoted for these (only `macos-15-Readme.md` was fetched in full).
10. **`macos-latest` → `macos-26` transition date (June 2026)** — only found in an aggregated search summary, not confirmed against a primary GitHub source page in this pass.
11. **Homebrew version pre-installed on runner images** — only found in an aggregated search summary, not confirmed against a primary source page in this pass.
12. **GitHub Actions macOS multiplier (10x figure)** — appeared only in third-party aggregator/calculator sites (cicdpipelinecost.com, dev.to, etc.), not confirmed verbatim from an official GitHub docs or changelog page in this pass.
13. **`xcrun simctl io recordVideo` and `simctl status_bar` exact flag syntax** — Apple does not host a web page for `simctl` help text; facts above were reconstructed from search-result snippets referencing on-device `xcrun simctl io help` / `xcrun simctl status_bar` output and a third-party blog post, not independently executed or fetched from a primary Apple source in this pass.
14. **Disambiguation within the 6.3" screenshot-size group** — Apple's screenshot spec page lists two portrait pixel sizes (1179x2556 and 1206x2622) for the same device list without a fetched sub-table clarifying which specific device(s) use which; not resolved.
15. **Whether XcodeGen is installed via Homebrew/Mint on any GitHub Actions macOS runner image** — confirmed absent from `macos-15-Readme.md` full-text search; not checked for other image versions (see Gap 9).
