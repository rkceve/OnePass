# F3 — Server / Billing / Jev Fact Collection

Fact-collection only. No recommendations, conclusions, or design suggestions. Each fact is quoted exactly with its source URL. Unverified/third-party facts are labeled explicitly.

Collected: 2026-09-23.

---

## 1. Jev by TypeSafe AI

### 1.1 Official overview / announcement

- Fact: Company/product overview
  Quote: "TypeSafe AI is an AI lab building machine-native intelligence infrastructure for automation... The company came out of stealth on September 15, 2026 with $40M in seed funding and Jev as its first public model."
  Source: https://typesafe.ai/ [OFFICIAL]

- Fact: Release date / early access
  Quote: "Jev, available today in early access" (Sep 15, 2026)
  Source: https://typesafe.ai/blog/introducing-system-one-models-and-jev [OFFICIAL]

- Fact: Positioning vs. LLMs
  Quote: "Jev achieves similar levels of intelligence on System One tasks compared to existing LLMs, while being two orders of magnitude faster and more efficient."
  Source: https://typesafe.ai/blog/introducing-system-one-models-and-jev [OFFICIAL]

- Fact: Structured output / no-hallucination claim
  Quote: "Type-safe structured values...The model never makes type errors. All answers are accompanied with calibrated probabilities and confidence scores." / "Jev gives up string generation, it's optimized for structured outputs and *can't* hallucinate."
  Source: https://typesafe.ai/blog/introducing-system-one-models-and-jev [OFFICIAL]

- Fact: Home page marketing figures
  Quote: "Jev. Cost: $42 Per Billion input tokens." / "238x Lower input price than Claude Fable 5.1" / "193.6x Faster, 244.6x Cheaper" / "Completed in 0.114s" / "Jev returns typed decisions with calibrated probabilities" / "Zero Hallucinations" / "Jev is TypeSafe's first public System One Model, optimized for automation"
  Source: https://typesafe.ai/ [OFFICIAL]

### 1.2 HTTP API

- Fact: Base URL / endpoint / method
  Quote: "HTTP Base URL: https://api.typesafe.ai/v1/systemone" ... "Method: POST with Content-Type: application/json"
  Source: https://docs.typesafe.ai/api (also https://docs.typesafe.ai/api.md) [OFFICIAL]

- Fact: Auth header
  Quote: "Authorization: Bearer <API_KEY>"
  Source: https://docs.typesafe.ai/api.md [OFFICIAL]

- Fact: Core request fields
  Quote: "state: The content to evaluate. A plain string for text, or structured data" / "model: Use \"jev-latest\" as TypeSafe's flagship model" / "questions: A map of typed Question objects you define"
  Source: https://docs.typesafe.ai/api.md [OFFICIAL]

- Fact: Question type limits
  Quote: "Maximum 255 options per Choice; Scores accept 2–10 levels."
  Source: https://docs.typesafe.ai/api.md [OFFICIAL]

- Fact: Response structure / usage accounting
  Quote: "Answers returned in a map matching your question ids, with: Matching type field / usage object tracking input_tokens and output_tokens / Confidence scores (0–1) for Choice and Score answers"
  Source: https://docs.typesafe.ai/api.md [OFFICIAL]

- Fact: Error codes
  Quote: "401 – Missing or invalid API key" / "429 – You have exceeded your rate limit" / "529 – TypeSafe is temporarily overloaded" / "retry the request with exponential backoff instead of retrying immediately"
  Source: https://docs.typesafe.ai/api.md [OFFICIAL]

### 1.3 "state" object

- Fact: Definition
  Quote: "the content you ask a System One model to evaluate. It could be a support message, a passage of text, or the current state of your application." / "Jev accepts text only. State must be a string, JSON object, or array of text values."
  Source: https://docs.typesafe.ai/concepts/state.md [OFFICIAL]

### 1.4 Question types — exact JSON shapes

- Fact: Noul (yes/no) request JSON
  Quote:
  ```json
  {
    "type": "noul",
    "instructions": "Is the customer asking for a human agent?",
    "criteria": {
      "true": "Explicitly requests to speak with a person",
      "false": "No request for human assistance mentioned"
    }
  }
  ```
  Source: https://docs.typesafe.ai/primitives/noul.md [OFFICIAL]

- Fact: Noul response JSON
  Quote:
  ```json
  {
    "type": "noul",
    "noul": 0.99
  }
  ```
  "The single noul value represents the complete probability distribution—no separate confidence field exists."
  Source: https://docs.typesafe.ai/primitives/noul.md [OFFICIAL]

- Fact: Noul field definitions
  Quote: "A Noul question requires: type: \"noul\" / instructions: The yes/no question or statement to judge / criteria (optional): An object with true and false descriptions clarifying what counts as yes vs. no"
  Source: https://docs.typesafe.ai/primitives/noul.md [OFFICIAL]

- Fact: Choice and Score fields (pieced together from api.md and the Python SDK usage example, not from dedicated choice.md / score.md pages — those were not directly fetched)
  Quote (Python example showing all three types together):
  ```python
  questions = {
      "billing": Noul(instructions="Is this about billing?"),
      "tone": Choice(
          instructions="What is the tone?", criteria={"calm": None, "angry": None}
      ),
      "urgency": Score(
          instructions="How urgent is this?", criteria=["low", "medium", "high"]
      ),
  }
  ```
  Source: https://docs.typesafe.ai/sdk/python/usage.md [OFFICIAL]

### 1.5 Model name / limits / rate limits / latency / pricing

- Fact: Model identifier and aliases
  Quote: "The exact model identifier is jev-1.13.0. Aliases include: jev-latest - \"The most recent stable, official release\" / jev-preview - \"The most recent release, whether or not it is an official one\""
  Source: https://docs.typesafe.ai/models.md [OFFICIAL]

- Fact: Token limits
  Quote: "Overall: \"64k tokens per request\"" / "State-specific: \"32k tokens for state plus the longest question\""
  Source: https://docs.typesafe.ai/models.md [OFFICIAL]
  Note: a third-party source (OpenRouter) separately states "Jev Latest has a 32,000 token context window" [THIRD-PARTY: openrouter.ai] — the two figures were not reconciled.

- Fact: Rate limits
  Quote: "250,000 tokens per second / 1,200 requests per minute" ... "Rate limits are adjusting dynamically...the limits above can change without notice"
  Source: https://docs.typesafe.ai/models.md [OFFICIAL]

- Fact: Input modality restriction
  Quote: "Text only. String, JSON object, or array of text values. No image, audio, or video input."
  Source: https://docs.typesafe.ai/models.md [OFFICIAL]

- Fact: Pricing
  Quote: "$42 / $0.042" per billion / million tokens respectively; "Output tokens are free."
  Source: https://docs.typesafe.ai/models.md [OFFICIAL] and https://typesafe.ai/blog/introducing-system-one-models-and-jev [OFFICIAL] ("Input tokens: $0.042 / MTok ($42 per billion tokens). Output tokens: FREE (too cheap to meter).")

- Fact: Latency figures
  Quote: "End-to-end response time is 70ms-500ms" ... "40x-200x faster for the same levels of frontier intelligence"
  Source: https://typesafe.ai/blog/introducing-system-one-models-and-jev [OFFICIAL]

- Fact: Cardinality limit (blog, matches the 255-option Choice limit in docs)
  Quote: "Jev supports a cardinality up to 255."
  Source: https://typesafe.ai/blog/introducing-system-one-models-and-jev [OFFICIAL]

- Fact: Free tier / trial credits — no fact found. See Gaps.

### 1.6 Data retention / training policy

- Fact: Training policy summary (paraphrase of legal index page, not verbatim DPA/Privacy Policy text)
  Quote: "our commitment not to train models on user data" (Privacy Policy) / "how we process customer data on your behalf, including data retention" (Data Processing Agreement) / "zero data retention (ZDR) for enterprise customers," inquiries to privacy@typesafe.ai
  Source: https://docs.typesafe.ai/legal.md [OFFICIAL]

- Fact: Additional training-policy claim (found only via search snippet, sentence itself not independently confirmed by direct fetch)
  Quote: "Jev is not trained on customer requests or responses... is not fine-tuned or LoRA-adapted with customer data, and is trained with RLCD to return calibrated decisions, with the same weights serving every account."
  Source: search result citing docs.typesafe.ai/models [OFFICIAL, unverified by direct fetch of this exact sentence]

### 1.7 Official JS SDK `@typesafe-ai/sdk`

- Fact: npm package existence/metadata (WebFetch of npmjs.com returned HTTP 403; this is from a search snippet only, not a direct page read)
  Quote: "@typesafe-ai/sdk is a TypeScript SDK for the TypeSafe API... The latest version is 0.6.0, last published 7 days ago."
  Source: https://www.npmjs.com/package/@typesafe-ai/sdk [OFFICIAL package page, content via search snippet only]

- Fact: Install command and runtime requirement
  Quote: "The SDK requires Node.js 20 or newer" and installs via "npm install @typesafe-ai/sdk"
  Source: https://docs.typesafe.ai/sdk/javascript.md [OFFICIAL]
  Note: no statement found (official or otherwise) about Cloudflare Workers / fetch-only environment compatibility. See Gaps.

- Fact: JS SDK code example (Choice type; the official JS docs did not contain a Noul-specific example)
  Quote:
  ```ts
  import { choice, TypeSafeClient } from "@typesafe-ai/sdk";

  const client = new TypeSafeClient();
  const response = await client.systemOne({
    state: { document: "I was charged twice. Please fix this ASAP." },
    questions: {
      category: choice("What is this ticket about?", {
        billing: null,
        technical: null,
        other: null,
      }),
    },
  });

  console.log(response.answers.category.choice);
  ```
  Source: https://docs.typesafe.ai/sdk/javascript.md [OFFICIAL]

- Fact: The clearest official Noul (yes/no) example found is in the **Python** SDK, not JS
  Quote:
  ```python
  from typesafe_sdk import Choice, Noul, Score, TypeSafeClient

  client = TypeSafeClient()
  state = "I was charged twice. Please help ASAP."
  questions = {
      "billing": Noul(instructions="Is this about billing?"),
      "tone": Choice(
          instructions="What is the tone?", criteria={"calm": None, "angry": None}
      ),
      "urgency": Score(
          instructions="How urgent is this?", criteria=["low", "medium", "high"]
      ),
  }
  result = client.system_one(state, questions)
  print(
      result.nouls["billing"].noul,
      result.choices["tone"].choice,
      result.scores["urgency"].score,
  )
  ```
  Source: https://docs.typesafe.ai/sdk/python/usage.md [OFFICIAL]
  Install: `pip install typesafe-sdk` (Source: https://docs.typesafe.ai/introduction/quickstart [OFFICIAL], quickstart page)

- Fact: Official quickstart also references a coding-agent plugin install (reported as found, not run/verified)
  Quote: "Install with `claude plugin marketplace add typesafe-ai/skills` (Claude Code) or `npx skills add typesafe-ai/skills --skill typesafe-ai` (other agents)."
  Source: https://docs.typesafe.ai/introduction/quickstart [OFFICIAL]

### 1.8 Third-party sources (explicitly separated)

- Fact: Founder/background claim
  Quote: "Typesafe AI, founded by former OpenAI researcher Diego Almeida, says the model uses a new sampler and a training method it calls reinforcement learning for calibrated decisions." / "Jev is built by Diego Almeida, a co-creator of ChatGPT and RLHF who worked at OpenAI before starting the company."
  Source: search snippets citing https://www.mindstudio.ai/blog/jev-system-one-model-launch and https://www.langchain.com/blog/building-a-harness-with-jev [THIRD-PARTY: mindstudio.ai, langchain.com] — not confirmed on any official typesafe.ai page.

- Fact: Seed round claim
  Quote: "alongside the announcement of a US$40 million seed round led by DCVC"
  Source: search snippet citing en.wikipedia.org/wiki/Jev_(AI_model) [THIRD-PARTY: en.wikipedia.org] — not cross-checked against an official typesafe.ai page directly.

- Fact: Third-party performance claim (numbers differ from the official blog's "40x-200x" figure)
  Quote: "TypeSafe AI's Jev offers an alternative to LLMs that claims to be 193x faster and 445x cheaper... System One type model is bespoke for probabilistic decision-making"
  Source: https://www.tomshardware.com/tech-industry/artificial-intelligence/typesafe-ais-jev-offers-an-alternative-to-llms-that-claims-to-be-193x-faster-and-445x-cheaper-system-one-type-model-is-bespoke-for-probabilistic-decision-making [THIRD-PARTY: tomshardware.com]

- Fact: Third-party pricing/context-window framing
  Quote: "Jev runs 40x-200x faster than frontier LLMs on comparable tasks, costs $0.042 per million input tokens with free output, and mathematically cannot hallucinate or produce type errors. Jev Latest has a 32,000 token context window."
  Source: search snippet citing https://kie.ai/blog/what-is-jev and openrouter.ai model page [THIRD-PARTY: kie.ai, openrouter.ai]

- Fact: Numerous near-identical unofficial GitHub repositories under different usernames, all claiming to be "the official" JS SDK
  Quote (repeated verbatim as the description across multiple distinct repos): "The official TypeScript/JavaScript library for the TypeSafe API"
  Source: e.g. https://github.com/typesafe-ai/typesafe-sdk-js , https://github.com/koriyoshi2041/typesafe-sdk-js , https://github.com/arunimshukla/typesafe-sdk-js , https://github.com/Kewe63/typesafe-sdk-js , https://github.com/Joe-Simo/typesafe-sdk-js , https://github.com/aoright/typesafe-sdk-js [UNCLEAR PROVENANCE / THIRD-PARTY: github.com, multiple non-organizational usernames]. Content of these repos was not inspected; this is reported only as an observed pattern.

- Fact: Additional apparent copycat/aggregator domains discussing Jev (content not fetched/verified)
  Quote (domain names only): jevmodel.org, jevtypesafeai.com — also note the task's own examples jevapi.org, jev-llm.com, jevai.org were not specifically found/verified as distinct sites in this search pass.
  Source: https://jevmodel.org/api/ , https://jevtypesafeai.com/ [THIRD-PARTY]

### 1.9 Gaps (Jev / TypeSafe AI)

- npmjs.com/package/@typesafe-ai/sdk could not be fetched directly (403 Forbidden); all npm-page facts are from a search snippet only.
- No official JS/TS SDK example demonstrating `noul()` was found (only `choice()` appears in the fetched JS SDK docs page). A Rust SDK snippet (`typesafeai_sdk::noul`) surfaced in search but was not verified by direct fetch and is a different package.
- No statement (official or third-party) found describing `@typesafe-ai/sdk` compatibility with Cloudflare Workers or fetch-only runtimes — only "Node.js 20 or newer" was stated.
- Full verbatim text of the Data Processing Agreement / Privacy Policy was not retrieved (only the legal.md index/summary).
- Founder identity and seed-round investor were not confirmed on any official typesafe.ai page — third-party only.
- Discrepancy between docs.typesafe.ai/models.md ("64k tokens per request" / "32k tokens for state plus the longest question") and a third-party OpenRouter listing ("32,000 token context window") was not reconciled.
- No explicit numeric limit on "questions per request" (count of question objects in one `questions` map) was found — only per-question-type limits (255 Choice options, 2–10 Score levels).
- No free tier / trial credit details found anywhere (official or third-party).
- No additional latency methodology (p50/p95/p99, benchmark conditions) beyond the single blog figures ("70ms-500ms", "0.114s" example) was found.
- Choice/Score dedicated docs pages (`primitives/choice.md`, `primitives/score.md`) were not directly fetched; their field shapes above are inferred from `api.md` and the Python SDK example only, not confirmed against a dedicated per-type reference page.

---

## 2. RevenueCat

### 2.1 Test Store

- Fact: How to enable
  Quote: "In the *Test configuration* section, create a new Test Store and you will be presented with an API key to use in the SDK."
  Source: https://www.revenuecat.com/docs/test-and-launch/sandbox/test-store [OFFICIAL]

- Fact: API key prefix
  Quote: "your Test Store API Key, which starts with the prefix test_"
  Source: https://www.revenuecat.com/docs/test-and-launch/sandbox/test-store [OFFICIAL, via search-engine summary of the page]

- Fact: Minimum SDK versions
  Quote: "Test Store requires minimum SDK versions of iOS 5.43.0 and Android 9.9.0" (also listed: Flutter 9.8.0, React Native 9.5.4, Capacitor 11.2.6, Cordova 7.2.0, Unity 8.3.0, KMP 2.2.2, Web 1.15.0)
  Source: https://www.revenuecat.com/docs/test-and-launch/sandbox/test-store [OFFICIAL]

- Fact: iOS Simulator support
  Quote (RevenueCat Developer Support Engineer Matt Heaney): "Yes, the Test Store does work in the iOS simulator, and this shouldn't require any additional configuration such as setting up a StoreKit configuration file." (additionally: offerings must contain Test Store products in packages, not just iOS-only products)
  Source: https://community.revenuecat.com/general-questions-7/does-test-store-work-in-ios-simulator-7514 [OFFICIAL staff reply on community forum, not the formal docs page]

- Fact: Purchase UI/modal
  Quote: "Instead of invoking the system in-app purchase flow, your app will present a modal with metadata about the product being purchased, along with buttons to simulate a successful purchase, a failed purchase, or cancel the purchase entirely."
  Source: https://www.revenuecat.com/docs/test-and-launch/sandbox/test-store [OFFICIAL]

- Fact: Test purchases behave like real ones
  Quote: "Test purchases made through Test Store behave like real purchases and subscriptions: they update CustomerInfo, trigger entitlements, and appear in your RevenueCat dashboard."
  Source: https://www.revenuecat.com/docs/test-and-launch/sandbox/test-store [OFFICIAL]

- Fact: Production warning
  Quote: "Never submit an app to the App Store or Google Play that is configured with a Test Store API key."
  Source: https://www.revenuecat.com/docs/test-and-launch/sandbox/test-store [OFFICIAL]

- Fact: Whether Test Store entitlements are visible via REST API — **no fact found either confirming or denying this.** See Gaps.

### 2.2 REST API — reading entitlements

- Fact: v1 base URL
  Quote: `"https://api.revenuecat.com/v1"`
  Source: https://www.revenuecat.com/docs/api-v1 [OFFICIAL]

- Fact: v1 auth header
  Quote: "Authentication for the RevenueCat REST API is achieved by setting the `Authorization` header with a valid API key." Example: `Authorization: Bearer YOUR_REVENUECAT_API_KEY`
  Source: https://www.revenuecat.com/docs/api-v1 [OFFICIAL]

- Fact: v1 endpoint
  Quote: "Get or Create Customer — `GET /subscribers/{app_user_id}`" (full path: `https://api.revenuecat.com/v1/subscribers/{app_user_id}`)
  Source: https://www.revenuecat.com/docs/api-v1/customers [OFFICIAL]

- Fact: v1 entitlements response fields + example JSON
  Quote:
  ```json
  "entitlements": {
    "pro_cat": {
      "expires_date": null,
      "grace_period_expires_date": null,
      "product_identifier": "onetime",
      "purchase_date": "2019-04-05T21:52:45Z"
    }
  }
  ```
  "Dictionary of the entitlements of this Customer (including any expired entitlements)."
  Source: https://www.revenuecat.com/docs/api-v1/customers [OFFICIAL]

- Fact: v2 base URL and auth
  Quote: Base URL `"https://api.revenuecat.com/v2"`; header `"Authorization: Bearer YOUR_REVENUECAT_API_KEY"`; "the RevenueCat REST API v2 requires stating the authorization type Bearer in the Authorization header" (per RFC 7235)
  Source: https://www.revenuecat.com/docs/api-v2 [OFFICIAL]

- Fact: v2 resource groups (index page only — exact endpoint paths/response schema not retrieved)
  Quote: "Customer — 12 endpoints" and "Subscription — 7 endpoints" listed as resource groups
  Source: https://www.revenuecat.com/docs/api-v2 [OFFICIAL]

### 2.3 purchases-ios SDK

- Fact: `configure(withAPIKey:appUserID:)` — source with doc comment
  Quote:
  ```swift
  /**
   * ...
   * The instance will be set as a singleton.
   * You should access the singleton instance using ``Purchases/shared``
   *
   * - Note: Best practice is to use a salted hash of your unique app user ids.
   * - Warning: Use this initializer if you have your own user identifiers that you manage.
   * - Parameter apiKey: The API Key generated for your app from https://app.revenuecat.com/
   * - Parameter appUserID: The unique app user id for this user. This user id will allow users to share their
   * purchases and subscriptions across devices. Pass `nil` or an empty string if you want ``Purchases``
   * to generate this for you.
   * - Returns: An instantiated ``Purchases`` object that has been set as a singleton.
   */
  @_disfavoredOverload
  @objc(configureWithAPIKey:appUserID:)
  @discardableResult static func configure(withAPIKey apiKey: String, appUserID: String?) -> Purchases {
      Self.configure(withAPIKey: apiKey,
                     appUserID: appUserID,
                     purchasesAreCompletedBy: .revenueCat,
                     storeKitVersion: .default)
  }
  ```
  Source: https://github.com/RevenueCat/purchases-ios/blob/main/Sources/Purchasing/Purchases/Purchases.swift, line 2372

- Fact: Offerings/packages fetch — SDK signatures
  Quote:
  ```swift
  @objc func getOfferings(completion: @escaping (Offerings?, PublicError?) -> Void)
  func offerings() async throws -> Offerings
  ```
  Source: https://github.com/RevenueCat/purchases-ios/blob/main/Sources/Purchasing/Purchases/Purchases.swift, lines 1130, 1150

- Fact: Official docs example for fetching offerings
  Quote:
  ```swift
  Purchases.shared.getOfferings { (offerings, error) in
      if let packages = offerings?.current?.availablePackages {
          self.display(packages)
      }
  }
  ```
  Source: https://www.revenuecat.com/docs/getting-started/displaying-products [OFFICIAL]

- Fact: `purchase(package:)` signatures
  Quote:
  ```swift
  @objc(purchasePackage:withCompletion:)
  func purchase(package: Package, completion: @escaping PurchaseCompletedBlock) {
      purchasesOrchestrator.purchase(product: package.storeProduct,
                                     package: package,
                                     promotionalOffer: nil,
                                     metadata: nil,
                                     trackDiagnostics: true,
                                     completion: completion)
  }

  func purchase(package: Package) async throws -> PurchaseResultData {
      return try await purchaseAsync(package: package)
  }
  ```
  Source: https://github.com/RevenueCat/purchases-ios/blob/main/Sources/Purchasing/Purchases/Purchases.swift, lines 1485, 1494

- Fact: `customerInfo` property/method
  Quote:
  ```swift
  @objc func getCustomerInfo(completion: @escaping (CustomerInfo?, PublicError?) -> Void) {
      self.getCustomerInfo(fetchPolicy: .default, completion: completion)
  }

  func customerInfo() async throws -> CustomerInfo {
      return try await self.customerInfo(fetchPolicy: .default)
  }

  func customerInfo(fetchPolicy: CacheFetchPolicy) async throws -> CustomerInfo {
      return try await self.customerInfoAsync(fetchPolicy: fetchPolicy)
  }
  ```
  Source: https://github.com/RevenueCat/purchases-ios/blob/main/Sources/Purchasing/Purchases/Purchases.swift, lines 1428, 1443, 1447

- Fact: Anonymous app user ID format
  Quote: "a new random App User ID (prefixed with `$RCAnonymousID:`)"
  Source: https://www.revenuecat.com/docs/customers/identifying-customers [OFFICIAL]

- Fact: Anonymous ID persistence (paraphrase from fetch tool, not independently verified verbatim)
  This identifier is automatically created and cached on device when the SDK is configured without a custom App User ID; a reinstall clears the cached value and a fresh random ID with the same prefix is generated.
  Source: https://www.revenuecat.com/docs/customers/identifying-customers [OFFICIAL, paraphrase]

- Fact: App extension setup requirement
  Quote: "enable app groups for the containing app and its contained app extensions" via Xcode or the Developer portal, then register the app group.
  Source: https://www.revenuecat.com/docs/getting-started/configuring-sdk/ios-app-extensions [OFFICIAL]

- Fact: App extension configuration code sample
  Quote:
  ```swift
  Purchases.configure(
    with: Configuration.Builder(withAPIKey: <your_api_key)
      .with(appUserID: <app_user_id>)
      .with(userDefaults: .init(suiteName: <group.your.bundle.here>))
      .build()
  )
  ```
  Source: https://www.revenuecat.com/docs/getting-started/configuring-sdk/ios-app-extensions [OFFICIAL]

- Fact: App extension result/limitation
  Quote: "you will be able to access a user's active subscriptions in your App Extension" through this shared UserDefaults configuration; extensions operate "read-only" — "Purchasing will not work because extensions don't have access to the parent's app Bundle."
  Source: https://www.revenuecat.com/docs/getting-started/configuring-sdk/ios-app-extensions [OFFICIAL]

### 2.4 RevenueCatUI — PaywallView / presentPaywallIfNeeded

- Fact: Basic PaywallView usage
  Quote:
  ```swift
  import SwiftUI
  import RevenueCat
  import RevenueCatUI

  struct App: View {
      @State
      var displayPaywall = false

      var body: some View {
          ContentView()
              .sheet(isPresented: self.$displayPaywall) {
                  PaywallView()
              }
      }
  }
  ```
  Source: https://www.revenuecat.com/docs/tools/paywalls/displaying-paywalls [OFFICIAL]

- Fact: `presentPaywallIfNeeded` with required entitlement
  Quote:
  ```swift
  .presentPaywallIfNeeded(
      requiredEntitlementIdentifier: Constants.ENTITLEMENT_ID,
      purchaseCompleted: { customerInfo in
          print("Purchase completed: \(customerInfo.entitlements)")
      },
      restoreCompleted: { customerInfo in
          print("Purchases restored: \(customerInfo.entitlements)")
      }
  )
  ```
  Source: https://www.revenuecat.com/docs/tools/paywalls/displaying-paywalls [OFFICIAL]

- Fact: `presentPaywallIfNeeded` with custom display-logic closure
  Quote:
  ```swift
  .presentPaywallIfNeeded { customerInfo in
      return customerInfo.entitlements.active.keys.contains("pro")
  } purchaseCompleted: { customerInfo in
      print("Purchase completed: \(customerInfo.entitlements)")
  } restoreCompleted: { customerInfo in
      print("Purchases restored: \(customerInfo.entitlements)")
  }
  ```
  Source: https://www.revenuecat.com/docs/tools/paywalls/displaying-paywalls [OFFICIAL]

- Fact: iPad presentation behavior (paraphrase, not verbatim)
  On iPad, `presentPaywallIfNeeded` shows the paywall in a modal roughly iPhone-sized by default; `PaywallView` or `PaywallViewController` can be used instead for full-screen iPad presentation.
  Source: https://www.revenuecat.com/docs/tools/paywalls/displaying-paywalls [OFFICIAL, paraphrase]

### 2.5 Shipaton milestones

- Fact: Official milestone list
  Quote: "Entrants may unlock up to 25 sponsor perks across five progress milestones: registration complete, RevenueCat project created, first test purchase, first Store API call, and first real purchase."
  Source: https://revenuecat-shipaton-2026.devpost.com/rules [OFFICIAL Shipaton 2026 rules, hosted on Devpost]

- Fact: No further definition given for "first test purchase" or "first Store API call"
  The rules page does not specify whether a Test Store purchase counts as "first test purchase," nor what SDK/API interaction qualifies as "first Store API call." It only states RevenueCat's backend tracks progress and emails newly unlocked perks.
  Source: https://revenuecat-shipaton-2026.devpost.com/rules [OFFICIAL]

### 2.6 Gaps (RevenueCat)

- No official documentation or community post found stating whether Test Store entitlements are readable via REST API (v1 or v2).
- v2 exact endpoint path(s) and JSON response schema for Customer/Subscription entitlements were not retrieved — only the resource-group index page (`/docs/api-v2`) was fetched; dedicated pages were not.
- Some statements (anonymous ID persistence behavior, iPad paywall presentation behavior) are paraphrases returned by the fetch tool, not independently re-verified as verbatim text.
- No official definition found for what specifically counts as "first test purchase" vs. "first Store API call" in the Shipaton 2026 milestone list.

---

## 3. Cloudflare Workers + Hono

### 3.1 Hono on Cloudflare Workers quickstart

- Fact: `npm create hono` command
  Quote: `npm create hono@latest my-app`
  Source: https://hono.dev/docs/getting-started/cloudflare-workers [OFFICIAL]

- Fact: Template selection
  Quote: "Select `cloudflare-workers` template for this example"
  Source: https://hono.dev/docs/getting-started/cloudflare-workers [OFFICIAL]

- Fact: Resulting project structure
  Quote:
  ```
  .
  ├── package.json
  ├── public
  │   ├── favicon.ico
  │   └── static
  │       └── hello.txt
  ├── src
  │   └── index.ts
  └── wrangler.jsonc
  ```
  Source: https://hono.dev/docs/getting-started/cloudflare-workers [OFFICIAL]

- Fact: Default starter code (src/index.ts)
  Quote:
  ```ts
  import { Hono } from 'hono'
  const app = new Hono()

  app.get('/', (c) => c.text('Hello Cloudflare Workers!'))

  export default app
  ```
  Source: https://hono.dev/docs/getting-started/cloudflare-workers [OFFICIAL]

- Fact: Local dev command and default URL
  Quote: run `npm run dev`, access at `http://localhost:8787`
  Source: https://hono.dev/docs/getting-started/cloudflare-workers [OFFICIAL]

- Fact: wrangler.jsonc static assets fragment
  Quote: `"assets": { "directory": "public" }`
  Source: https://hono.dev/docs/getting-started/cloudflare-workers [OFFICIAL]

- Fact: wrangler.jsonc fields recommended for CI deploy
  Quote: `"main": "src/index.ts", "minify": true`
  Source: https://hono.dev/docs/getting-started/cloudflare-workers [OFFICIAL]

Note: No full `wrangler.toml` example was found on the fetched Hono quickstart page content — only `wrangler.jsonc` fragments and the project-tree listing (which itself names `wrangler.jsonc`, not `wrangler.toml`, as the config file). See Gaps.

### 3.2 Workers KV binding usage

- Fact: Binding declaration — wrangler.jsonc
  Quote:
  ```jsonc
  {
  	"kv_namespaces": [
  		{
  			"binding": "USERS_NOTIFICATION_CONFIG",
  			"id": "<BINDING_ID>"
  		}
  	]
  }
  ```
  Source: https://developers.cloudflare.com/kv/get-started/ [OFFICIAL]

- Fact: Binding declaration — wrangler.toml
  Quote:
  ```toml
  [[kv_namespaces]]
  binding = "USERS_NOTIFICATION_CONFIG"
  id = "<BINDING_ID>"
  ```
  Source: https://developers.cloudflare.com/kv/get-started/ [OFFICIAL]

- Fact: TypeScript Env interface
  Quote:
  ```ts
  interface Env {
  	USERS_NOTIFICATION_CONFIG: KVNamespace;
  }
  ```
  Source: https://developers.cloudflare.com/kv/get-started/ [OFFICIAL]

- Fact: Write / read examples (generic Workers, not Hono-specific)
  Quote: `await env.USERS_NOTIFICATION_CONFIG.put("user_2", "disabled");` / `const value = await env.USERS_NOTIFICATION_CONFIG.get("user_2");`
  Source: https://developers.cloudflare.com/kv/get-started/ [OFFICIAL]

- Fact: Accessing bindings inside a Hono handler via `c.env` (Hono's own docs show this pattern using R2 as the example; same mechanism documented for any binding including KV)
  Quote:
  ```ts
  type Bindings = {
    MY_BUCKET: R2Bucket
    USERNAME: string
    PASSWORD: string
  }

  const app = new Hono<{ Bindings: Bindings }>()

  app.put('/upload/:key', async (c, next) => {
    const key = c.req.param('key')
    await c.env.MY_BUCKET.put(key, c.req.body)
    return c.text(`Put ${key} successfully!`)
  })
  ```
  Quote: "In the Cloudflare Workers, we can bind the environment values, KV namespace, R2 bucket, or Durable Object. You can access them in `c.env`."
  Source: https://hono.dev/docs/getting-started/cloudflare-workers [OFFICIAL]

- Fact: `put()` method signature and `expirationTtl` option
  Quote: `env.NAMESPACE.put(key, value, options?);` — `options: { expiration?: number, expirationTtl?: number, metadata?: object }`; `expirationTtl` is a `number`, unit seconds, "the number that represents when to expire the key-value pair in seconds from now," minimum threshold 60 seconds (values "less than 60 seconds into the future" are rejected)
  Source: https://developers.cloudflare.com/kv/api/write-key-value-pairs/ [OFFICIAL]

### 3.3 Secrets

- Fact: `wrangler secret put` syntax and description
  Quote: `npx wrangler secret put <KEY>` — "Create or update a secret for a Worker" — example: `npx wrangler secret put FOO`
  Source: https://developers.cloudflare.com/workers/wrangler/commands/ [OFFICIAL]

- Fact: Related command reference
  Quote: "Secrets can be added through [`wrangler secret put`](https://developers.cloudflare.com/workers/wrangler/commands/general/#secret) or [`wrangler versions secret put`](https://developers.cloudflare.com/workers/wrangler/commands/general/#versions-secret-put) commands."
  Source: https://developers.cloudflare.com/workers/configuration/secrets/ [OFFICIAL]

- Fact: Accessing secrets via `env` parameter
  Quote:
  ```js
  export default {
  	async fetch(request, env, ctx) {
  		const sql = postgres(env.DB_CONNECTION_STRING);
  	},
  };
  ```
  "You can access secrets in your Worker code through: The `env` parameter passed to your Worker's `fetch` event handler."
  Source: https://developers.cloudflare.com/workers/configuration/secrets/ [OFFICIAL]

- Fact: Alternative access via global import
  Quote:
  ```js
  import { env } from "cloudflare:workers";

  const sql = postgres(env.DB_CONNECTION_STRING);
  ```
  Source: https://developers.cloudflare.com/workers/configuration/secrets/ [OFFICIAL]

- Fact: Local dev secrets file (Hono docs)
  Quote: "To configure the environment variables for local development, create a `.dev.vars` file or a `.env` file in the root directory of the project. These files should be formatted using the dotenv syntax."
  Example: `SECRET_KEY=value` / `API_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9`
  Source: https://hono.dev/docs/getting-started/cloudflare-workers [OFFICIAL]

- Note (flagged, not resolved): `wrangler secret put` is documented under the general Wrangler commands page, distinct from the newer "Secrets Store" product page (`/workers/wrangler/commands/secrets-store/`), which lists a different command set (`secrets-store secret create/update/duplicate/get/delete/list`) with no `put` subcommand. These are two separate secret systems in the docs.

### 3.4 `wrangler dev`

- Fact: Command syntax and description
  Quote: `wrangler dev [<SCRIPT>] [OPTIONS]` — "Start a local server for developing your Worker."
  Source: https://developers.cloudflare.com/workers/wrangler/commands/ [OFFICIAL]

- Fact: `--port` / `--ip` / `--local-protocol` flags
  Quote: `--port` (number, optional) — "Port to listen on"; `--ip` (string, optional) — "IP address to listen on," defaults to `localhost`; `--local-protocol` (`'http'|'https'`, default: http)
  Source: https://developers.cloudflare.com/workers/wrangler/commands/ [OFFICIAL]

- Fact: Default port (stated separately from the flag definition, as a usage instruction on the same page)
  Quote: "With `wrangler dev` running, send HTTP requests to `localhost:8787`"
  Source: https://developers.cloudflare.com/workers/wrangler/commands/ [OFFICIAL]

- Fact: Corroborating default port (Hono docs)
  Quote: after `npm run dev`, access the application at `http://localhost:8787`
  Source: https://hono.dev/docs/getting-started/cloudflare-workers [OFFICIAL]

### 3.5 Free plan limits

- Fact: Free plan daily request limit
  Quote: "Accounts on the Workers Free plan have a daily request limit of 100,000 requests" / pricing page: "100,000 per day"
  Source: https://developers.cloudflare.com/workers/platform/limits/ ; https://developers.cloudflare.com/workers/platform/pricing/ [OFFICIAL]

- Fact: Free plan CPU time
  Quote: table row "CPU time | 10 ms" (per HTTP request); pricing page: "10 milliseconds of CPU time per invocation"
  Source: https://developers.cloudflare.com/workers/platform/limits/ ; https://developers.cloudflare.com/workers/platform/pricing/ [OFFICIAL]
  Gap: not confirmed whether this 10ms figure differs for Durable Objects / cron triggers / other invocation types — the fetched limits table gave only the single figure.

- Fact: Paid plan requests/CPU time (different tier, quoted for contrast only)
  Quote: "10 million included per month" with "$0.30 per additional million" (requests); "30 million CPU milliseconds included per month" plus "$0.02 per additional million CPU milliseconds"
  Source: https://developers.cloudflare.com/workers/platform/pricing/ [OFFICIAL]

- Fact: Workers KV Free tier limits
  Quote: "Reads: 100,000 reads per day"; "Writes to different keys: 1,000 writes per day"; "Writes to same key: 1 per second"; "Storage/account: 1 GB"; "Storage/namespace: 1 GB"; "Key size: 512 bytes"; "Value size: 25 MiB"
  Source: https://developers.cloudflare.com/kv/platform/limits/ [OFFICIAL]

- Fact: Workers KV Free vs Paid (pricing page table, agrees with the limits page above)
  Quote: Free — "Keys read: 100,000 / day"; "Keys written: 1,000 / day"; "Keys deleted: 1,000 / day"; "Stored data: 1 GB". Paid — "Keys read: 10 million/month, + $0.50/million"; "Keys written: 1 million/month, + $5.00/million"; "Keys deleted: 1 million/month, + $5.00/million"; "Stored data: 1 GB, + $0.50/ GB-month"
  Source: https://developers.cloudflare.com/workers/platform/pricing/ [OFFICIAL]

- Fact: Reset cadence
  Quote: free tier limits reset daily at 00:00 UTC; paid tier limits are monthly.
  Source: https://developers.cloudflare.com/workers/platform/pricing/ [OFFICIAL]

### 3.6 Testing with vitest

- Fact: Package rename (current state at time of research)
  Quote: "Version 1 of the Workers Vitest integration is published as `@cloudflare/vitest-plugin`"; "The package was formerly named `@cloudflare/vitest-pool-workers`"
  Source: https://developers.cloudflare.com/changelog/post/2026-08-19-vitest-plugin/ [OFFICIAL]

- Fact: Install command (current package)
  Quote: `npm i -D vitest@^4.1.0 @cloudflare/vitest-plugin`
  Source: https://developers.cloudflare.com/workers/testing/vitest-integration/get-started/write-your-first-test/ [OFFICIAL]

- Fact: Basic config example (current package)
  Quote:
  ```ts
  import { cloudflareTest } from "@cloudflare/vitest-plugin";
  import { defineConfig } from "vitest/config";

  export default defineConfig({
  	plugins: [
  		cloudflareTest({
  			wrangler: { configPath: "./wrangler.jsonc" },
  		}),
  	],
  });
  ```
  Source: https://developers.cloudflare.com/workers/testing/vitest-integration/get-started/write-your-first-test/ [OFFICIAL]

- Fact: Migration mapping from old package
  Quote: Old: `"@cloudflare/vitest-pool-workers": "^0.16.0"` → New: `"@cloudflare/vitest-plugin": "^1.0.0"`; Old: `import { cloudflareTest } from "@cloudflare/vitest-pool-workers";` → New: `import { cloudflareTest } from "@cloudflare/vitest-plugin";`; Old types: `"types": ["@cloudflare/vitest-pool-workers/types"]` → New: `"types": ["@cloudflare/vitest-plugin/types"]`
  Source: https://developers.cloudflare.com/workers/testing/vitest-integration/migration-guides/migrate-to-vitest-plugin/ [OFFICIAL]

- Fact: Codemod for automated migration
  Quote: `npx @cloudflare/codemods vitest:pool-workers-to-vitest-plugin`
  Source: https://developers.cloudflare.com/changelog/post/2026-08-19-vitest-plugin/ [OFFICIAL]

- Fact: Hono's own docs still reference the old package name (cross-doc inconsistency, flagged not resolved)
  Quote: "For testing, we recommend using `@cloudflare/vitest-pool-workers`. Refer to examples for setting it up."
  Source: https://hono.dev/docs/getting-started/cloudflare-workers [OFFICIAL, but out of date relative to the Cloudflare changelog above]

- Fact: Sample test (Hono docs)
  Quote:
  ```ts
  describe('Test the application', () => {
    it('Should return 200 response', async () => {
      const res = await app.request('http://localhost/')
      expect(res.status).toBe(200)
    })
  })
  ```
  Source: https://hono.dev/docs/getting-started/cloudflare-workers [OFFICIAL]

### 3.7 Gaps (Cloudflare Workers / Hono)

- No full `wrangler.toml` example was located on the Hono quickstart page (only `wrangler.jsonc`); a toml variant could exist elsewhere on the page but was not surfaced by the fetch.
- `wrangler dev` default port (`8787`) comes from a separate usage sentence, not from the `--port` flag's own definition.
- `wrangler secret put` vs. the newer "Secrets Store" product's differently-named commands were not reconciled — flagged as two distinct systems in the docs.
- Free plan CPU-time limit (10ms) was not confirmed to be uniform across invocation types (HTTP request vs. Durable Objects vs. cron).
- Hono's official docs and Cloudflare's official changelog disagree on the current vitest testing package name (`@cloudflare/vitest-pool-workers` vs. `@cloudflare/vitest-plugin`) — both quoted, not resolved.

---

## 4. Sending demo email to a fixed Gmail inbox

### 4.1 Resend free tier / resend.dev sender

- Fact: Sending restriction using unverified domain / `onboarding@resend.dev`
  Quote: "You can only send testing emails to your own email address (your-email-address@domain.com)."
  Source: https://resend.com/docs/knowledge-base/403-error-resend-dev-domain [OFFICIAL]

- Fact: Nature of the resend.dev domain
  Quote: "The resend.dev domain is only available for testing purposes and can only send emails to the email address associated with your Resend account. Emails sent from unverified domains or default addresses are intended only for initial testing."
  Source: https://resend.com/docs/knowledge-base/403-error-resend-dev-domain [OFFICIAL]

- Fact: Free tier daily send limit
  Quote: "100 emails a day"
  Source: https://resend.com/pricing [OFFICIAL]

- Fact: Free tier monthly send limit
  Quote: "3,000" (emails/month, transactional email)
  Source: https://resend.com/pricing [OFFICIAL]

- Fact: Free tier domain allowance
  Quote: "3 domains"
  Source: https://resend.com/pricing [OFFICIAL]

- Fact: Free tier other quotas
  Quote: "10,000 automation runs" (monthly), "30-day data retention," "5" AI credits/month
  Source: https://resend.com/pricing [OFFICIAL]

- Gap: No explicit numeric per-minute/per-second rate limit figure was located on resend.com/pricing in this pass (only daily/monthly send counts confirmed).

### 4.2 Cloudflare Email Routing / Email Service `send_email` binding

- Fact: Current status split between two features
  Quote: "Email Sending Beta for outbound transactional emails Available on Workers Paid plan" and "Email Routing for handling incoming emails with Workers or routing to email addresses Available on Free and Paid plans"
  Source: https://developers.cloudflare.com/email-service/ [OFFICIAL]

- Fact: Free-tier note for sending to verified destinations
  Quote: "Sending to verified destination addresses in your account is free on all plans, even when only Email Routing is configured."
  Source: https://developers.cloudflare.com/email-service/ [OFFICIAL]

- Fact: DNS requirement
  Quote: "You must be using Cloudflare DNS to use Email Service."
  Source: https://developers.cloudflare.com/email-service/get-started/send-emails/ [OFFICIAL]

- Fact: Sender address domain requirement
  Quote: "The sender address must always belong to a domain you have onboarded to Email Service."
  Source: https://developers.cloudflare.com/email-service/configuration/send-bindings/ [OFFICIAL]

- Fact: Default destination behavior (no restriction attribute set)
  Quote: binding can send to "any verified destination address in your account" (when no restriction is applied)
  Source: https://developers.cloudflare.com/email-service/configuration/send-bindings/ [OFFICIAL]

- Fact: Binding restriction options
  Quote: three configurable restriction fields — `destination_address` (single recipient), `allowed_destination_addresses` (recipient allowlist), `allowed_sender_addresses` (sender allowlist)
  Source: https://developers.cloudflare.com/email-service/configuration/send-bindings/ [OFFICIAL]

- Fact: Documented per-message limits
  Quote: "50 per email" (recipients, combined across all recipient fields); message size "5 MiB" general use, "25 MiB" for verified destination addresses only; suppression-list bulk import rate "10 per minute"
  Source: https://developers.cloudflare.com/email-service/platform/limits/ [OFFICIAL]

- Fact: Daily quota — no fixed numeric free-tier figure disclosed
  Quote: "New accounts start with a conservative daily quota and scale up over time based on your sending behavior, deliverability rates, and account standing."
  Source: https://developers.cloudflare.com/email-service/platform/limits/ [OFFICIAL]

### 4.3 Gmail SMTP with an App Password

- Fact: App Password / 2-Step Verification requirement
  Quote: "App passwords can only be used with accounts that have 2-Step Verification turned on." / "To create an app password, you need 2-Step Verification on your Google Account."
  Source: https://support.google.com/mail/answer/185833 [OFFICIAL, Google Account Help]

- Fact: SMTP host/port (official Google Workspace instructions)
  Quote: "For TLS, enter port 587, and for authentication, enter your complete Google Workspace email address and an app password."
  Source: https://support.google.com/a/answer/176600 [OFFICIAL, "Send email from a printer, scanner, or app"]
  Gap: no equally exact quoted sentence for port 465 (SSL) was located on an official support.google.com page in this pass.

- Fact: Google Workspace daily sending limit
  Quote: "2,000" maximum messages per day per user account; "1,500 for mail merge (previously called multi-send)"
  Source: https://knowledge.workspace.google.com/admin/gmail/gmail-sending-limits-in-google-workspace [OFFICIAL] (redirect target of https://support.google.com/a/answer/166852)

- Fact: Recipient-based daily quota
  Quote: "10,000" total recipients per day; "3,000" external recipients per day; per-message cap "2,000 total per message" across To/Cc/Bcc, with "500 external recipients" max per message
  Source: https://knowledge.workspace.google.com/admin/gmail/gmail-sending-limits-in-google-workspace [OFFICIAL]

- Fact: Trial account reduced quota
  Quote: "500 for trial accounts" messages daily; "500 external for trial accounts" unique recipients daily
  Source: https://knowledge.workspace.google.com/admin/gmail/gmail-sending-limits-in-google-workspace [OFFICIAL]

- Fact: SMTP relay service has separate limits
  Quote: "Sending limits are different if your organization uses the SMTP relay service"
  Source: https://knowledge.workspace.google.com/admin/gmail/gmail-sending-limits-in-google-workspace [OFFICIAL]

### 4.4 Gaps (Email)

- Resend: no explicit numeric rate-limit (requests/second) figure found on the pricing page.
- Cloudflare Email Service: no fixed numeric daily/monthly send quota disclosed for the free or paid tier — docs describe a scaling, behavior-based quota with no starting number given.
- Cloudflare Email Service: no separate changelog entry found confirming expected GA date / duration of the "Beta" label beyond the phrase quoted above.
- Gmail: port 465 (SSL) was not confirmed via an exact quote from an official support.google.com page (only port 587/TLS was confirmed).
- Gmail: the confirmed 2,000/day (and related) limits are documented on the Google **Workspace** admin help page; no separately quoted, distinct numeric limit specifically for a plain free @gmail.com consumer account was found on an official support.google.com page in this session (third-party sources commonly cite "500 recipients/day" for consumer Gmail, but this was not verified against an official Google page here).

---

## Overall Gaps Summary

1. Jev free tier / trial credits — not found.
2. Jev JS SDK Cloudflare Workers / fetch-only compatibility — not stated anywhere found; only "Node.js 20+" is documented.
3. Jev JS SDK Noul-specific code example — not found (only Choice shown in JS docs; Noul shown only in Python docs).
4. RevenueCat: Test Store entitlement visibility via REST API — not found either way.
5. RevenueCat: v2 REST API exact endpoint paths/response schema for entitlements — not retrieved (index page only).
6. RevenueCat Shipaton: exact definition of "first test purchase" / "first Store API call" milestones — not found beyond the milestone name list.
7. Cloudflare: full `wrangler.toml` example on Hono's quickstart page — not located (only `wrangler.jsonc` shown).
8. Cloudflare Email Service: fixed numeric free-tier daily/monthly send limit — not disclosed (scaling quota only).
9. Gmail: official quote for port 465 and for a plain free-account (non-Workspace) daily limit — not found.
