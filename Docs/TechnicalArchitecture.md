# DermaLens Technical Architecture

## App Shape

DermaLens is an iOS 17+ SwiftUI app with five primary surfaces:

- Today: summary, latest scan, top priorities, and trust messaging.
- Scan: AVFoundation camera preview, local frame-quality estimation, Vision face alignment checks, capture-quality gates, and simulated analysis.
- Insights: face-region map, scan evidence table, visible concern scores, confidence, and explanations.
- Routine: AM/PM product plan, premium product alternatives/swaps, completion tracking, guardrails, and goal tuning.
- Shelf: independent product catalog, manual local product entry, search, owned/using/wishlist/avoided states, filters, and recommendation rationale.

`UserProfile` captures visible-goal context plus baseline skin feel, routine complexity, ingredient flags, fragrance preference, and retinoid safety context. Its decoder is backwards-compatible with earlier saved snapshots, and app restore rebuilds the routine from the current profile so newly stricter safety settings apply immediately.

Production `AppState` starts without seeded reports or routines. SwiftUI previews and unit tests can opt into sample data, but real first-run users see an empty scan/routine state until they complete a guided capture. Completing onboarding persists profile context and routes directly to the Scan tab so the baseline job continues instead of dropping users into an unguided dashboard. If a user returns to Today before finishing the scan, Home collapses into a baseline-scan gate instead of showing priorities, routines, or journal actions that would imply analysis already exists.

`IngredientCompatibilityEngine` analyzes the full routine after products are selected. It generates structured findings for missing sunscreen, retinoid preference conflicts, exfoliant frequency, high-sensitivity guardrails, fragrance preference, duplicate active families, partial ingredient-data coverage, and positive concern fit. Each finding carries severity, related product IDs, plain-language rationale, and a next-step recommendation so the Premium ingredient report is actionable instead of just a warning list. Results resolve those related product IDs into product rows with source, evidence, ingredient-coverage, commercial, and trust-summary context so ingredient warnings are not detached from data quality.

`RoutineReminderPlanner` converts a generated `RoutinePlan` plus local reminder-time preferences into stable AM/PM reminder slots. `RoutineNotificationScheduler` is the only type that imports `UserNotifications`; it requests permission from a user action, schedules local repeating reminders, reschedules when the user changes reminder times, and cancels them during privacy reset.

`RoutineAdherenceTracker` stores local routine completion records by day and stable step key. The stable key uses moment, order, product category, and product ID so completion survives harmless routine regeneration while avoiding false matches when a product changes.

`ProductShelfManager` keeps one persisted status per product. `AppState` also stores a local custom-product catalog so users can add products they actually own without waiting for barcode/OCR integrations. Using and owned custom products can enter the recommendation catalog when they are otherwise compatible; avoided products are excluded from generated routines, and untracked custom products stay searchable on the Shelf without silently changing recommendations. Every `SkincareProduct` carries catalog source, evidence level, ingredient-list coverage, commercial status, and `ProductSourceMetadata` fields so product suggestions can disclose whether they are curated sample data, user-entered label data, verified retailer data, clinician-curated, complete INCI, key-ingredient-only, independent, affiliate, brand-partnered, source-dated, INCI-date verified, or reviewer-attributed. `ProductTrustSummary` rolls those fields into a data-reliability grade, score, strengths, and limitations so commercial bias, missing provenance, and incomplete ingredient data are visible wherever products are recommended. `ProductRecommendationReadiness` separately labels sample/prototype products, user-entered data, metadata requiring launch review, and launch-ready products; routine selection reasons include that readiness label so fit scores are not mistaken for purchase certainty. Safety matchers use full ingredient lists when available and fall back to key ingredients only with visible partial-data disclosure.

`RecommendationEngine` also ranks same-category product alternatives for a routine step. Generated `RoutineStep` values carry a fit score and short selection-reason list from the same ranking rules that chose the product, so the Routine screen can explain scan focus matches, profile goals, sensitivity, budget, shelf status, and product-disclosure signals in context. When the latest report is simulated, local fallback, consent-gated, legacy, or remote-but-unvalidated, Results and Routine label the output as prototype or rule-generated instead of implying validated detection. Premium users can swap an alternative into the current routine; the swap refreshes ingredient findings, reschedules reminders, clears completion records for the replaced step, marks custom products as using when a custom product is chosen, and labels the replacement as a user-selected alternative. Swaps are persisted as slot-level overrides, then replayed after each safety rebuild only if the product still matches the profile and routine guardrails.

`ProgressJournal` stores private, local context notes by day. Each entry can link to a scan report and keeps a small snapshot of that report's creation date and top visible concerns, so journal history remains understandable even though scan history is capped to the latest 12 reports. Journal entries also store skin-feel tags, optional routine comfort rating, and optional routine plan ID.

`PrivacyLockManager` owns the optional journal-lock state. The user's lock preference is persisted separately from scan/profile state, the app locks on launch and when it leaves the foreground if the preference is enabled, and authentication goes through an injectable `DeviceAuthenticationServicing` boundary backed by LocalAuthentication in production. Face ID, Touch ID, or passcode unlock returns only success/failure to the app; it is not used as scan evidence.

`ProgressComparisonEngine` compares the latest scan with the prior saved scan. It ranks visible-score deltas by magnitude and labels changes as less visible, stable, or more visible, keeping the copy in the cosmetic-progress lane instead of clinical outcome language. Insights shows this as a Premium comparison card when at least two local reports exist.

`PrivacyExportBuilder` creates a structured JSON text export for the Privacy Center. The export includes profile choices, generated report summaries, per-region non-image scan evidence and guided-capture status, routine state, reminder-time preferences, fit scores, selection reasons, product source/evidence/ingredient-coverage/commercial/readiness disclosures, concrete product provenance fields, product trust grades and limitations, custom-product full ingredient lists when entered, remote-analysis consent host/version/timestamp when granted, premium routine swap overrides, adherence records, shelf statuses, and progress journal entries. It also carries an explicit excluded-data list for raw camera frames, saved face photos, Face ID templates, payment details, and analytics identifiers.

`PremiumAccessPolicy` is a pure Swift policy layer for freemium decisions. It keeps entitlement logic out of view bodies where possible and currently defines the free shelf limit, report-history visibility, ingredient-report preview depth, and premium routine alternatives access. Views pass `SubscriptionManager.isPremium` into the policy, so StoreKit remains the source of entitlement while policy decisions stay unit-testable.

`SubscriptionManager` owns StoreKit 2 product loading, purchases, restores, transaction-update listening, and entitlement refresh through an injectable `SubscriptionStoreClient` boundary. The production client wraps StoreKit 2, while unit tests can drive product loading, purchase success, cancellation, pending approval, failures, restore success, and restore-without-entitlement states without live App Store transactions. The manager exposes loading, purchasing, restoring, active-product, status-message, and error state so the paywall can distinguish real App Store products from simulator preview plans and avoid double-submitting transactions.

## Current Implementation

The app currently runs without external services. `ScanAnalyzer` simulates a skin report from scan quality and user goals. `RecommendationEngine` ranks local product catalog entries by:

- match against top visible concerns,
- match against stated user goals,
- baseline skin feel and desired routine complexity,
- ingredient flags from the user's profile,
- ingredient-list coverage and full INCI safety signals when available,
- fragrance preference,
- sensitivity fit,
- budget tier,
- routine compatibility.

This makes the prototype usable before vendor credentials, but the code keeps the production seam clear.

`CameraSessionController` estimates lighting, clarity, face alignment, and stability from live camera frames. The pure `ScanQualityEstimator` owns the scoring math so it can be unit-tested without a camera. `ScanQuality` blocks clearly weak captures before analysis and returns concrete user guidance for lighting, alignment, stability, or clarity issues. `GuidedScanView` requires camera authorization and a buffered camera frame before creating a report, so denied/unavailable camera states cannot become saved "real" scans. The guided scan pass captures short-lived frames for forehead, left cheek, right cheek, T-zone, and chin; a region counts toward guided-capture coverage only when the camera provides a fresh, unique, usable frame after that region's prompt begins. Incomplete guided coverage shows a retry message and `AppState.runScan` refuses to persist a report or build a routine. This is not anatomical region verification, and the model reserves separate `regionVerified` semantics for a future landmark/depth verifier. Generated reports persist only the non-image `ScanEvidenceSummary`, including per-region frame counts, fresh guided frame counts, verification status, and quality snapshots, so users and beta testers can audit coverage without saving raw photos. `AppState` persists the user's profile, onboarding completion, generated routine, routine swap overrides, routine completion history, product shelf state, progress journal entries, and the latest local scan reports through `PersistenceStore`. The app keeps the latest 12 generated reports as structured data, can export that structured state from the Privacy Center, and does not persist raw camera frames in the prototype.

`DiagnosticsView` gives beta testers a quick in-app readout of latest scan confidence, local report count, journal note count, routine state, StoreKit product loading, and current analyzer mode.

`SkinAnalysisServicing` is the analyzer boundary. The default implementation is the simulated local `ScanAnalyzer`; a production implementation should conform to the same protocol and return calibrated `SkinReport` values. Each report carries `AnalysisMetadata` with provider, kind, image-retention posture, fallback state, model version, optional request ID, and validation status. `Docs/AnalyzerValidationModelCard.md` defines the subgroup coverage, confidence calibration, vendor acceptance criteria, low-quality rejection, and fallback evidence required before any non-simulated analyzer is launch-ready.

`RemoteSkinAnalysisClient` shows the intended API contract: send global quality metrics, per-frame quality snapshots, device model, profile context, and short-lived base64 JPEG scan frames to a backend, then map the response into `ConcernScore` values plus analyzer audit metadata. It refuses incomplete guided evidence before upload, matching `AppState.runScan` and the guided scan UI. Remote requests use an explicit timeout so a dead endpoint falls back locally without leaving the scan spinner at the default session timeout. `AppState` gates remote analysis behind a persisted `RemoteAnalysisConsentRecord` scoped to the configured host and consent-copy version; if the remote endpoint changes or consent copy changes, upload consent is treated as off until the user opts in again. When remote analysis is configured but consent is off, the scan uses the local prototype analyzer and report metadata records `remoteConsentNotGranted`. When a remote request fails after upload is attempted, report metadata records `remoteUploadAttempted` plus local fallback status, so privacy copy does not imply the scan stayed purely on device. Production should decide whether fallback remains acceptable or whether service failures should block report creation.

`AppConfiguration` chooses the analyzer at launch. Without environment configuration the app uses the simulated local analyzer. With `DERMALENS_ANALYSIS_ENDPOINT` set to a valid HTTPS endpoint, it creates a `RemoteSkinAnalysisClient`; `DERMALENS_ANALYSIS_API_KEY` is optional for sandbox authorization. The diagnostics sheet shows the active analyzer mode and remote host.

## Production Analyzer Options

### Fastest Path

Use a vendor skin-analysis API for the first public version. Candidate categories:

- AI skin-analysis API: visible concerns, confidence scores, region data.
- Product intelligence API: ingredient parsing, safety flags, product metadata.
- Optional teledermatology partner: paid human review for high-concern cases.

Expected replacement point:

- Replace the default `SkinAnalysisServicing` implementation with a service that uploads selected scan frames, receives normalized metrics, maps them into `ConcernScore`, and returns a `SkinReport`.
- Keep capture-quality gates local so poor images can be rejected before upload.
- Return confidence and region-level rationale for every concern score.

### Stronger Long-Term Path

Build an owned model only after collecting opt-in, consented, diverse, labeled data. Requirements:

- dermatologist/esthetician label protocol,
- skin-tone coverage and fairness testing,
- repeatability tests under different lighting,
- calibration against known clinical or cosmetic assessment rubrics,
- model cards and internal evaluation reports.

## Privacy

Recommended production defaults:

- Analyze images, then delete raw images by default.
- Save only numeric report summaries unless the user opts into visual progress history.
- Separate identity, billing, and scan media storage.
- Encrypt any retained media.
- Provide export/delete-account flows.
- Use Face ID only for app lock via LocalAuthentication, never as a skin-data source.
- Keep notification text behavioral and generic. Do not show scan scores, visible concerns, product conflicts, or embarrassing skin details on the lock screen.

## Monetization

`SubscriptionManager` is wired for StoreKit 2 product IDs:

- `dermalens.premium.monthly`
- `dermalens.premium.yearly`

Free users can keep a useful preview: one visible report in progress history, safety-relevant ingredient warnings, a first non-safety ingredient finding when there are no safety findings, and up to five tracked shelf products. Results and Routine both use `PremiumAccessPolicy` for ingredient-finding visibility so safety warnings are not paywalled while deeper non-safety findings remain premium. Marking a product as avoided remains free even at the shelf limit so safety/preferences are not paywalled. Premium unlocks fuller progress history, full ingredient reasoning, routine product alternatives/swaps, and unlimited shelf tracking. The Home toolbar does not show the Premium entry before a baseline scan; first-run monetization is routed through concrete premium feature attempts such as ingredient depth, progress history, shelf limits, or alternatives.

`PaywallView` shows StoreKit plan prices, renewal language, restore purchase state, in-app Privacy Policy and Terms screens, and non-diagnostic safety copy before purchase. `DermaLens/Configuration.storekit` is a draft local StoreKit configuration and the shared Xcode launch scheme references it for simulator paywall testing.

Before launch:

- create products in App Store Connect,
- add subscription group metadata,
- create local StoreKit config for simulator testing,
- add restore-purchases QA,
- verify product-loading, pending purchase, canceled purchase, failed purchase, restore success, and restore-without-entitlement paywall states,
- verify introductory offer and trial copy with App Review.

## Regulatory Guardrails

The app should remain a cosmetic recommendation product unless the company commits to medical-device work. Avoid:

- diagnose,
- treat,
- cure,
- detect disease,
- acne severity diagnosis,
- melanoma or cancer checks,
- hydration/oil claims that are not validated by the input data.

Use:

- visible concern,
- cosmetic appearance,
- routine suggestion,
- confidence,
- scan quality,
- clinician escalation copy for suspicious or changing lesions.

## Next Engineering Steps

1. Validate the StoreKit configuration in Xcode and sync App Store Connect products.
2. Validate multi-region frame capture and ephemeral buffer clearing on physical devices.
3. Add richer product metadata import paths such as barcode lookup, OCR label capture, or curated product feeds.
4. Replace the simulated analyzer with a vendor or in-house `SkinAnalysisServicing` implementation.
5. Expand unit tests for persistence migration and remote-analyzer failure states.
6. Expand `DermaLensUITests` beyond first-run/paywall/privacy smoke coverage to scan-to-report, privacy reset, custom product entry, and paywall purchase/restore flow.
7. Add weekly adherence insights after the core routine flow is validated in beta.
