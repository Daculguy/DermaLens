# DermaLens Beta QA Protocol

Use this protocol for every TestFlight beta round. Each run should record build number, device model, iOS version, tester skin-tone range, lighting condition, analyzer mode, and whether the run used a fresh local data reset.

## Before Each Session

- Install a fresh build or use Privacy center > Delete local data before a clean run.
- Complete onboarding with a realistic profile: skin type, baseline skin feel, routine style, sensitivity, budget, ingredient flags, fragrance preference, retinoid safety context, and 2-4 goals.
- Expected: completing onboarding lands on Scan with the guided capture path visible.
- Before the first scan, visit Today, Insights, and Routine and confirm they show no-scan empty states rather than demo reports, demo scores, or demo products.
- Open DermaLens > menu > Beta diagnostics and capture the starting values for Reports, Evidence, Analyzer source, Analyzer fallback, Premium entitlement, StoreKit products loaded, Analyzer, Remote host, Fallback to local, and Raw photos persisted.
- Confirm the tester knows this is cosmetic skincare guidance, not diagnosis, treatment, or emergency advice.

## Scan-Quality Scenarios

Run at least one successful baseline scan before negative cases.

| Scenario | Steps | Expected result |
| --- | --- | --- |
| Good baseline | Face centered, even front lighting, steady device, clean lens; complete forehead, left cheek, right cheek, T-zone, and chin prompts. | Scan completes, Quality is high, Evidence is complete, the Insights scan-evidence table shows captured regions with quality values, Blocks is 0, recommendations have confidence labels and visible concern explanations. |
| Low light | Dim room or face mostly shadowed. | Capture guidance asks for better lighting or blocks analysis; app must not produce high-confidence results. |
| Backlight/glare | Strong light behind tester or reflective glare on face/glasses. | Quality drops or blocks; guidance mentions lighting/clarity without shaming the user. |
| Off-center face | Move face partially outside the guide. | Alignment guidance appears; capture should not silently accept a poor frame. |
| Motion blur | Move head or hand during capture. | Stability or clarity drops; analysis should wait or block until stable. |
| Obstruction | Mask, hand, hair, heavy shadow, or only partial face. | App blocks or lowers confidence; no disease or identity claims should appear. |
| Camera denied/unavailable | Deny camera permission or run in an environment without a front camera. | The scan screen may render, but Run complete scan must not create a saved report or routine. |
| Interrupted guided pass | Move away or cover the camera during one region prompt. | The app should ask for a retake and must not save a report or routine from incomplete guided coverage. |
| Repeatability | Three good scans in similar conditions. | Top concerns and routine direction should be broadly consistent; major swings need a bug note with diagnostics. |
| Diverse coverage | Repeat good and low-light cases across device models, skin tones, ages, and glasses/no-glasses users. | Guidance remains usable and respectful; no group should see systematic low quality in reasonable lighting. |

Record for each scan: Quality number, Confidence label, guided-capture evidence coverage, per-region evidence rows, Blocks count, top visible concerns, any confusing guidance, and whether the user understood what to change.

## Face ID And Privacy Checks

- From Privacy center, turn on Journal lock. Relaunch the app and confirm it opens locked.
- Background and foreground the app with Journal lock enabled. Expected: it returns to the lock overlay.
- From Home, open the menu and tap Lock journal now. Unlock using Face ID, Touch ID, or device passcode fallback.
- Expected: the lock overlay protects reports and routines, failed/canceled authentication keeps the app locked, and retry messaging is calm.
- Confirm copy says DermaLens only receives authentication success/failure and never receives enrolled Face ID data.
- Confirm Face ID is not described as scan analysis, identity verification, age estimation, skin measurement, or a source of biometric templates.
- Open Privacy center and confirm it says profile choices and reports are stored locally, photos are not saved in the prototype, raw frames are not persisted, and Delete local data resets reports/profile/routine history.
- Confirm Privacy center exposes Privacy Policy and Terms screens, and both repeat the cosmetic-guidance and clinician-escalation boundaries.
- If a remote analyzer is configured, confirm Scan and Privacy Center show an upload opt-in before any remote report. Consent copy must mention short-lived scan frames, scan-quality metadata, device model, skin type, baseline feel, routine complexity, budget, goals, sensitivity, ingredient flags, irritants, and retinoid context.
- Grant remote-analysis consent, relaunch, and confirm the consent stays on for the same analyzer host. Change the configured host in a test build and confirm consent returns to off.
- Use Privacy center > Export local data and confirm the share sheet opens with structured JSON text.
- Inspect the export for profile choices, report summaries, analyzer provenance, model version, validation status, request ID when present, remote upload attempted status, remote-analysis consent host/version/timestamp when granted, non-image scan evidence metadata, per-region guided-capture status, routine reminder times, product disclosure and provenance fields, product recommendation readiness, routine ingredient-list coverage, routine fit scores and selection reasons, premium swap overrides, shelf statuses, custom products, custom-product full ingredient lists when entered, and journal notes. Confirm it does not include `jpegData`, base64 image payloads, device payment details, or Face ID templates.
- After delete, reopen Beta diagnostics: Reports should reflect the reset state, Journal lock should be off in Privacy center, and Raw photos persisted should still read No.

## Progress Journal Checks

- From Today, add a check-in linked to the latest scan. Choose skin feel, routine comfort, one or more context tags, and a short note.
- From Insights, add a report-linked journal note and confirm the note appears in Progress journal and For this report.
- Relaunch the app and confirm the Today check-in, journal count, note text, tags, and routine comfort rating persist.
- Delete one journal entry from Insights and confirm it disappears without deleting the scan report.
- Use Privacy center > Delete local data and confirm Journal returns to 0 notes and Journal notes returns to 0 in Beta diagnostics.
- Confirm the journal copy says notes are private context, do not change scan scores, and are not medical diagnosis.

## Paywall Checks

- Before the baseline scan, confirm Home does not show a Premium button. After a completed scan, tap the Home premium button; from Scan/Insights/Shelf, trigger any premium upsell entry point.
- Expected: paywall opens without blocking core app navigation, Restore purchases is visible, and close works.
- If StoreKit products are loaded, verify the products match App Store Connect IDs: `dermalens.premium.monthly` and `dermalens.premium.yearly`.
- If StoreKit products are not loaded, verify fallback static plans match the local StoreKit draft prices: `$4.99` monthly and `$39.99` yearly, show as preview plans, expose a Retry StoreKit products action, and diagnostics show StoreKit products loaded: 0.
- Confirm paid features are framed as deeper ingredient reasoning, progress comparisons, and alternatives, not medical certainty.
- Confirm the paywall includes auto-renewal, Apple account cancellation copy, Privacy Policy, and Terms screens before purchase.
- During purchase, confirm the selected product shows progress, other purchase/restore actions are disabled, cancellation clears without an error, pending approval shows a non-error status, and failed verification appears as an error.
- During restore, confirm the restore action shows progress, restore success dismisses the paywall through active entitlement, and restore without an active subscription shows a calm no-entitlement status.
- As a free user, track five shelf products, then try adding a sixth as Owned/Using/Wishlist. Expected: the sixth routes to Premium, while changing/removing existing tracked products and marking a new product Avoided still work.
- As a free user with multiple reports, confirm Insights shows only the latest progress report plus a locked card for hidden history. Premium should show the saved report history.
- As a free user, confirm Ingredient report shows all warning/caution safety findings plus one non-safety preview when no safety findings exist. Premium should show the fuller ingredient list with severity, next-step guidance, ingredient-data coverage warnings, and related product rows with disclosure chips and trust summaries.
- As a free user, confirm Routine ingredient guardrails follow the same policy: safety warning/caution findings stay visible, deeper non-safety findings are locked, and the locked card opens Premium.
- As a free user, tap Premium alternatives from a routine step and confirm it opens the paywall without toggling step completion.
- As a premium user, tap View alternatives from a routine step, confirm ranked products explain why they fit, swap one into the routine, relaunch, and confirm the swap persists if the product still satisfies profile guardrails.
- Confirm each generated routine step shows a fit score or selection reasons plus product trust and recommendation-readiness labels. Sponsored, affiliate, owned-brand, partial-ingredient, user-entered, launch-review-needed, and prototype products should disclose limitations instead of looking equivalent to verified independent launch-ready products.
- Confirm swapped steps clearly say they are user-selected alternatives.
- Purchase, cancel, pending, failed, restore-success, and restore-without-entitlement flows should leave Premium entitlement accurate in Beta diagnostics.
- Do not ship paywall copy that omits renewal terms, price, restore path, or Apple account cancellation language.

## Routine Reminder Checks

- From Routine, enable reminders from the reminder card and accept the system notification prompt.
- Expected: the reminder status reads Daily reminders on, and the toggle remains enabled after app relaunch.
- Change Morning and Evening reminder times. Expected: the selected times remain visible after app relaunch, are included in Privacy Center export, and existing reminders are rescheduled without adding duplicate notification identifiers.
- Disable reminders and confirm the status returns to Reminders off.
- Deny notification permission on a clean install and confirm the app shows Notifications blocked without repeatedly prompting.
- Use Privacy center > Delete local data and confirm reminders are disabled and canceled with the local reset.
- Confirm notification title/body copy is generic routine guidance. It must not mention visible concerns, scores, acne, redness, product conflicts, or scan results.

## Routine Adherence Checks

- From Routine, mark one morning step complete, switch tabs, return to Routine, and confirm the step remains complete.
- Relaunch the app and confirm Today and Routine show the same completion progress.
- Toggle the same step again and confirm the completion count decreases without duplicate records.
- Complete all steps and confirm the full-day streak increments.
- Trigger a profile/goal change that regenerates the routine. If the same product remains in the same slot, today's completion should still match; if a product changes, the old completion should not carry over.
- Swap a premium alternative into a completed step and confirm completion for the replaced product clears, ingredient guardrails refresh, reminders still show a valid state, and retinoid swaps remove any exfoliant completion records they make obsolete.
- Use Privacy center > Delete local data and confirm Today done returns to 0 and Adherence records returns to 0 in Beta diagnostics.

## Product Shelf Checks

- From Shelf, search by product name, brand, key ingredient, full-list-only ingredient, and concern, then clear search and confirm all products return.
- Tap Add product, enter a real product name, brand, category, price, key ingredients, optional full INCI list, concern fit, and initial status. Confirm the custom card appears in Shelf search and carries a Custom badge, user-entered source provenance, and ingredient-list coverage disclosure.
- Add one custom treatment whose full INCI contains a retinoid or flagged irritant that is not listed as a key ingredient. Confirm routine recommendations, swaps, and ingredient findings still apply the retinoid/irritant guardrail.
- Add one custom product with status None and confirm it appears on Shelf but does not enter the generated routine until marked Owned or Using.
- Mark a compatible custom product Using and confirm the routine can select it when it fits scan priorities; then remove the custom product and confirm its shelf status and routine usage disappear.
- Mark a product Using, Owned, Wishlist, then Avoided. Expected: each status replaces the prior status for that product.
- Mark a routine product Avoided and confirm the next generated routine no longer uses that product when an alternative exists.
- Confirm Wishlist products do not change the generated routine by themselves.
- Combine status filters with category filters and confirm empty states are clear.
- Use Privacy center > Delete local data and confirm Shelf items and Custom products return to 0 in Beta diagnostics.

## Diagnostics Sheet Usage

Open Home > menu > Beta diagnostics at the start and end of each run, and after every scan, purchase, restore, or data reset.

Capture these fields in the beta issue template:

- Reports: should increase by 1 after each completed scan and reset after Delete local data.
- Confidence: should track the latest scan and never show high confidence for blocked/weak capture.
- Analyzer source and Analyzer fallback: should state whether the latest report came from simulated local analysis, remote analysis, or local fallback after a remote failure.
- Model version, validation, and request ID: should reflect the analyzer metadata for saved reports.
- Evidence: should show guided-capture coverage, usually `5/5 guided captures` for a clean physical-device scan. Interrupted or stale captures should show hint-only rows instead of guided coverage.
- Insights scan evidence: should list each guided region with captured/missing state, frame count, and quality value without showing raw photos.
- Quality: use the number to compare scan repeatability across lighting and devices.
- Blocks: should be 0 for clean scans and greater than 0 for known bad scans.
- Reminders: should match Routine reminder state and selected times after enabling, time edits, disabling, permission denial, app relaunch, and Delete local data.
- Today done and Adherence records: should change when routine steps are toggled, survive relaunch, and reset after Delete local data.
- Shelf items, Custom products, Owned/using products, and Avoided products: should update when shelf statuses or manual entries change, survive relaunch, and reset after Delete local data.
- Journal notes and Recent notes: should update after check-ins, survive relaunch, and reset after Delete local data.
- Routine steps and Goals: should match onboarding/profile changes.
- Skin feel, Routine style, Ingredient flags, and Retinoids: should match onboarding choices and influence routine guardrails.
- Avoids fragrance and Avoids retinoids: should match profile choices and influence recommendations.
- Premium entitlement: should change only after verified purchase/restore or sandbox entitlement changes.
- StoreKit products loaded: should be 2 when StoreKit/App Store Connect is configured for beta.
- Analyzer: should be Simulated local for offline/prototype runs or Remote API for configured analyzer runs.
- Remote host: should show the expected host in remote runs and Not configured in simulated runs.
- Fallback to local: note any Yes values in remote runs; production beta should surface service failure decisions deliberately.
- Raw photos persisted: must remain No unless a future build intentionally adds opt-in image history and updates privacy docs.

## Remote Analyzer Configuration Expectations

- Simulated beta: `DERMALENS_ANALYSIS_ENDPOINT` is unset, Analyzer reads Simulated local, Remote host reads Not configured, and Fallback to local reads No.
- Remote beta: `DERMALENS_ANALYSIS_ENDPOINT` is a valid HTTPS URL with scheme and host, Analyzer reads Remote API, Remote host matches the expected backend, and `DERMALENS_ANALYSIS_API_KEY` is present only in secure build/test configuration.
- The remote service must accept the documented `POST /skin-analysis` payload, reject low-quality frames before confident output, and return per-concern confidence plus region rationale.
- Before consent is granted, a remote-configured build must keep scans local and label the report as upload off. After consent is granted, a successful remote report should show remote upload attempted. A remote failure after attempted upload should show local fallback without claiming the scan stayed purely on device.
- Raw scan frames should be short-lived: upload only when needed, delete after analysis by default, and avoid analytics/logging of image data or sensitive skin details. Persist and export only non-image coverage metadata unless a future opt-in image-history feature is intentionally shipped.
- If the remote request fails, record whether the app falls back to local analysis and confirm Results shows a prominent fallback notice with reason. Before production release, decide whether fallback is acceptable or whether users should see a clear service-unavailable state.
- Any change that sends images or derived skin data off device must update privacy policy, App Privacy labels, App Review notes, and tester consent copy before beta expansion.

## App Store-Safe Language Watch

Prefer:

- "visible concern", "cosmetic appearance", "routine suggestion", "ingredient reasoning", "scan quality", "confidence", "may help", "consider", "see a qualified clinician for painful, bleeding, changing, suspicious, or urgent concerns".

Avoid unless the company is ready for medical/regulatory scope:

- "diagnose", "treat", "cure", "prevent", "detect disease", "medical grade", "clinical diagnosis", "dermatologist replacement", "acne severity diagnosis", "melanoma", "cancer check", "risk score", "guaranteed results", "Face ID skin analysis", "biometric skin profile".

Review every paywall, screenshot, onboarding screen, push/email draft, App Store subtitle, and App Review note for these terms before submission. When in doubt, describe what the app actually observes from the scan, show confidence, and point users to a qualified clinician for concerning symptoms.
