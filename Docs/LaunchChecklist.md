# DermaLens Launch Checklist

## Product

- Confirm launch positioning: cosmetic skin guidance, not medical diagnosis.
- Decide whether recommendations are independent, affiliate-funded, brand-partnered, or mixed.
- Create a public ingredient policy and conflict-of-interest policy.
- Recruit beta users across skin tones, ages, lighting conditions, and device models.

## Design

- Test onboarding copy for trust without overclaiming, and verify completion routes directly into the guided scan.
- Keep scan animation functional: progress should map to actual guided-region capture steps and fresh guided-capture evidence coverage.
- Show confidence and scan-quality warnings near every recommendation.
- Avoid shame-based language and alarming severity labels.

## Engineering

- Build on a Mac with Xcode 26 or later using the iOS 26 SDK or later for App Store uploads.
- Configure bundle ID, a real Apple Developer Team for device/archive signing, app icon, and StoreKit products.
- Add a production persistence layer.
- Verify local scan-history persistence and delete-data reset behavior.
- Verify fresh installs and privacy resets show no-scan empty states instead of seeded demo reports or routines.
- Verify Privacy Center export opens the share sheet, decodes as JSON, includes analyzer provenance, ingredient-list coverage, product source label/URL/check date/INCI verification date/reviewer, custom-product full ingredient lists when entered, and premium swap overrides when present, and excludes raw camera frames, saved face photos, Face ID templates, and payment details.
- Verify analyzer provenance: simulated local, remote success, and remote fallback reports are labeled correctly in Insights, Diagnostics, and export.
- Verify analyzer audit metadata: model version, validation status, and request ID appear when available.
- Verify denied/unavailable camera states cannot create saved scan reports or routines.
- Verify Insights scan evidence shows captured/missing guided regions, frame counts, and quality values without exposing raw photos.
- Verify incomplete guided-region coverage blocks report/routine creation and asks the user to retake the scan.
- Verify remote analyzer consent: upload defaults off, copy names frames/metadata/device/profile context, consent persists only for the same host and copy version, host changes invalidate consent, and remote fallback reports show upload attempted when applicable.
- Verify onboarding profile fields persist, route the user into Scan, and influence recommendations: baseline skin feel, routine style, ingredient flags, fragrance preference, and retinoid safety context.
- Verify progress journal persistence, report linking, note deletion, and delete-data reset behavior.
- Verify product shelf status persistence, manual product entry, full INCI entry, search, filters, recommendation inclusion/exclusion, custom-product export, and delete-data reset behavior.
- Verify freemium policy for shelf limit, report-history preview, ingredient preview, paywall routing, and premium unlock state.
- Verify paywall transaction states: StoreKit loading, StoreKit retry, purchase in progress, purchase canceled, purchase pending, purchase failure, restore in progress, restore success, and restore without entitlement.
- Verify safety paths are not paywalled: ingredient warning/caution findings remain visible to free users and marking products Avoided works at the free shelf limit.
- Verify premium routine alternatives: free users route to paywall, premium users see ranked swaps, and swaps persist after relaunch while refreshing ingredient findings, reminders, and adherence state.
- Verify premium ingredient report: free users see all safety warning/caution cards plus the free non-safety preview behavior, and premium users see all finding cards with severity, actionable next-step guidance, and related product rows that include disclosure chips plus trust summaries.
- Verify product disclosure chips, source provenance, recommendation readiness, trust summaries, and ranking behavior: catalog source, evidence level, ingredient-list coverage, commercial status, source label, source URL, source check date, INCI verification date, reviewer, trust grade, and trust limitations appear on product cards; launch-ready products outrank otherwise equivalent prototype data; commercial bias lowers recommendation rank; partial ingredient data and missing provenance are never presented as complete verification.
- Verify full-list-only retinoids, exfoliating acids, and known irritants are detected in recommendations, routine swaps, and ingredient findings.
- Verify routine rationale: generated steps show fit scores and selection reasons, and swapped steps are labeled as user-selected alternatives.
- Verify routine reminder permission, custom morning/evening times, rescheduling, cancellation, relaunch persistence, export fields, and privacy-reset cancellation.
- Verify `DermaLens/PrivacyInfo.xcprivacy` is included in the app target resources and declares the approved UserDefaults reason used by local persistence.
- Add secure image upload/delete path if using a cloud analyzer.
- Verify remote analyzer request/response contract against a real backend.
- Complete `Docs/AnalyzerValidationModelCard.md` evidence for any non-simulated analyzer, including subgroup performance, repeatability, low-quality rejection, and fallback policy.
- Run `DermaLensTests` and `DermaLensUITests` on an iOS simulator from Xcode. UI smoke tests cover fallback paywall/legal visibility; StoreKit product-loading assertions still require explicit Xcode StoreKit/App Store Connect QA.
- Review ingredient compatibility findings against `Docs/IngredientRules.md` before adding new product categories.
- Add analytics for funnel health without storing sensitive scan media in analytics tools.
- Add crash reporting.

## Legal And Privacy

- Review and host the approved privacy policy before App Store submission; App Store Connect requires a privacy policy URL for all apps.
- Review and host approved terms or configure Apple's standard EULA/custom EULA path before selling subscriptions.
- Complete App Privacy labels accurately from `Docs/AppPrivacyLabel.md`, even for a local-only build.
- Verify Paywall and Privacy Center expose Privacy Policy and Terms screens before purchase.
- Treat remote-analysis consent as processor-specific: changing analyzer host, processor, payload, or consent copy should invalidate old consent and require a fresh opt-in.
- Review FDA/medical-device risk if any feature claims diagnosis, treatment, or disease detection.
- Verify free-visible clinician-escalation copy appears for suspicious, painful, bleeding, changing, or urgent concerns.
- Add terms for affiliate/product recommendation monetization.

## Beta

- Test first scan completion rate.
- Test repeated scans in controlled lighting.
- Test low-quality scan blocking for dark rooms, off-center faces, motion, and glare.
- Test per-region evidence accuracy for clean, incomplete, interrupted, stale-frame, and duplicate-frame guided scans.
- Use the beta diagnostics sheet to capture scan quality, report count, StoreKit product count, and entitlement state during TestFlight sessions.
- Test routine reminders for allow, deny, time edits, disable, reinstall/relaunch, export, and privacy reset cases.
- Test progress journal check-ins after scans, app relaunch, note deletion, and privacy reset.
- Test manual product entry after relaunch, routine regeneration, removal, free shelf limit, and privacy reset.
- Test privacy export before and after local data reset.
- Test whether recommendations stay stable when capture quality is similar.
- Test false trust: users should understand confidence and limits.
- Test purchase conversion only after users see enough value.
- Test that fallback paywall prices match StoreKit/App Store Connect products.

## App Store

- Provide camera usage description.
- Provide Face ID usage description only if app lock ships.
- Use in-app purchase for digital premium features.
- Include privacy policy and terms links on the paywall before purchase.
- Include demo credentials or demo mode if review cannot access premium.
- Avoid screenshots or metadata that imply medical diagnosis.
