# DermaLens

DermaLens is a SwiftUI prototype for a privacy-first skincare recommendation app. It uses a guided camera scan experience, local simulated analysis, transparent concern scores, product recommendations, routine tracking, and a StoreKit-ready premium paywall.

The current build intentionally avoids medical diagnosis claims. The scan language is framed around visible cosmetic concerns and repeatable capture quality. A production implementation should replace the simulated analyzer with a validated skin-analysis provider or a clinically validated in-house model.

## Open In Xcode

Open `DermaLens.xcodeproj`, choose the `DermaLens` scheme, and run on an iOS 17+ simulator. For device, TestFlight, or archive builds, first set a real Apple Developer Team in Xcode signing settings.

## Current Features

- SwiftUI app shell with Home, Scan, Routine, Shelf, and Insights tabs.
- Expanded onboarding profile for baseline skin feel, routine style, ingredient flags, and retinoid safety context, then routes directly into the first guided scan.
- First-run Today screen stays focused on the baseline scan and hides priorities, routine, and journal actions until a complete guided capture exists.
- Guided multi-region scan flow with camera preview, live quality gates, fresh guided-capture coverage, per-region evidence quality, and camera-framing wording that avoids Face ID scan claims.
- Local scan-quality estimation for lighting, clarity, face alignment, and stability.
- Unit-tested scan-quality estimator that keeps camera math separate from AVFoundation.
- In-memory scan capture bundle with short-lived guided JPEG frames, fresh guided-capture metadata, and region hints for future analyzer upload.
- Simulated skin report with confidence levels, per-region scan evidence, and explainable recommendations.
- Score and routine screens label prototype or fallback outputs as rule-generated so users do not mistake simulated analysis for validated diagnosis.
- Remote analyzer client seam for a backend or vendor API.
- Analyzer selection through launch environment configuration.
- Analyzer provenance on each report, including simulated local, remote, or local fallback status.
- Remote analyzer uploads are gated by explicit user consent scoped to the configured host and consent-copy version.
- Real app launches start without demo reports or demo routines; previews/tests can opt into seeded sample data.
- Product catalog and recommendation engine.
- Product recommendation disclosure chips for catalog source, evidence level, ingredient-list coverage, commercial status, source label, source check date, INCI verification date, and reviewer.
- Product recommendation readiness labels that distinguish prototype-only, user-entered, launch-review-needed, and launch-ready product metadata.
- Product trust summaries that grade data reliability and disclose commercial-bias or missing-provenance limitations before ranking feels like a black box.
- Searchable product shelf with owned, using, wishlist, and avoided product states plus local manual product entry with optional full INCI lists.
- Premium routine alternatives that rank compatible swaps, persist chosen overrides, and update the current routine.
- Routine steps include fit scores and selection-reason chips so product choices are explainable in context.
- Ingredient compatibility report with severity, related products, partial ingredient-data warnings, and next-step guidance for SPF gaps, duplicate actives, fragrance preference, retinoid/exfoliant caution, and sensitivity guardrails.
- Customizable morning/evening routine reminders using local notifications, with privacy-safe lock-screen copy that avoids scan findings.
- Persistent routine adherence tracking with today progress, completion streaks, and privacy reset support.
- Local progress journal with scan-linked notes, skin-feel tags, routine comfort ratings, and private reset support.
- Optional Face ID / Touch ID / passcode journal lock that persists the user's preference and auto-locks on launch or when the app leaves the foreground.
- Local scan-history persistence and a privacy center with structured local-data export, per-region non-image guided-capture metadata, reminder preferences, custom-product ingredient coverage, and delete-local-data reset.
- In-app Privacy Policy and Terms screens plus an app privacy manifest for local UserDefaults persistence.
- Beta diagnostics sheet for scan, recommendation, paywall, and persistence QA.
- Premium paywall scaffold using StoreKit 2 product loading.
- Injectable subscription store client for unit-testing product loading, purchase, pending, cancel, failure, and restore states without live App Store transactions.
- Freemium access policy for shelf limits, report-history previews, and ingredient-report previews.
- Draft local StoreKit configuration in `DermaLens/Configuration.storekit`.
- XCTest targets with recommendation, persistence, privacy-lock, privacy-export, premium-access, ingredient, scan-quality, analyzer-configuration, remote-client, reminder-planner, adherence-tracker, product-shelf, progress-journal, and first-run/paywall/privacy UI smoke coverage.
- Implementation docs in `Docs/`.
- Beta QA protocol in `Docs/BetaQAProtocol.md`.
- Ingredient rule rationale in `Docs/IngredientRules.md`.
- Analyzer validation/model-card requirements in `Docs/AnalyzerValidationModelCard.md`.

## Important Limitations

- This repository was created from a Windows Codex environment, so local iOS compilation was not available here.
- `xcodebuild` and `xcrun` are not installed in this environment, so build/test verification must be run on macOS with Xcode.
- The analyzer is simulated. It conforms to a service boundary that is ready to be swapped for a real vendor API or Core ML model.
- Do not ship a non-simulated analyzer until it satisfies the validation gates in `Docs/AnalyzerValidationModelCard.md`.
- Face ID biometric data is not used for skin analysis and cannot be accessed by third-party apps. Front-camera framing guidance can improve capture consistency, while Face ID / Touch ID / passcode authentication only returns success/failure for the optional journal lock.

## Remote Analyzer Configuration

By default DermaLens uses the simulated local analyzer. To point a beta build at a backend, add launch environment values in Xcode:

- `DERMALENS_ANALYSIS_ENDPOINT=https://your-service.example.com/skin-analysis`
- `DERMALENS_ANALYSIS_API_KEY=<optional sandbox key>`

The diagnostics sheet shows whether the app is using simulated or remote analysis.
