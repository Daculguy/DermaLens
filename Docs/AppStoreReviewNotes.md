# App Store Review Notes

## Reviewer Access

- No separate account or demo credentials are required for the current build.
- Premium access is offered through Apple in-app purchase using these auto-renewable subscription product IDs:
  - `dermalens.premium.monthly`
  - `dermalens.premium.yearly`
- Reviewers can use the standard App Store sandbox purchase and restore flows to test premium behavior.
- The local StoreKit configuration at `DermaLens/Configuration.storekit` is a draft simulator/testing aid. Open and validate it in Xcode before TestFlight or App Store submission, make sure App Store Connect products match the same IDs, and record whether StoreKit configuration is available to UI tests or only manual simulator launch runs.
- If a remote skin-analysis service is enabled for review, set it through launch/backend configuration and disclose in the privacy policy whether scan frames leave the device. Remote uploads should require explicit in-app consent scoped to the configured analyzer host.

## Camera Use

- DermaLens requests camera access so the user can capture guided face-scan photos for cosmetic skincare recommendations.
- Camera capture is user initiated, and camera access is not used for background capture.
- The camera feature is intended for routine-building and skincare-product guidance, not identity verification or medical screening.

## Face ID App Lock

- If app lock is enabled, DermaLens uses Apple's system biometric authentication APIs to protect access to the app.
- The app-lock preference is user controlled in Privacy Center; when enabled, the app locks on launch and when it leaves the foreground.
- The app does not receive, store, transmit, or analyze Face ID biometric data.
- Authentication is handled by the operating system, with device passcode fallback where available.

## Medical And Safety Positioning

- DermaLens does not diagnose, treat, prevent, or cure medical conditions.
- Scan results and recommendations are cosmetic skincare guidance only.
- Users are told to contact a qualified medical professional for painful, bleeding, changing, suspicious, or urgent skin concerns.
- App metadata and screenshots should avoid claims related to disease detection, diagnosis, clinical accuracy, or treatment.

## Subscriptions

- DermaLens Premium is sold through Apple in-app purchase only.
- Monthly and yearly plans are auto-renewable subscriptions.
- The paywall shows pricing, renewal terms, restore purchases, Apple account cancellation language, and in-app Privacy Policy and Terms screens before purchase.
- Premium features should remain accessible while a verified subscription entitlement is active.

## Privacy

- Skin scan content may be sensitive, so privacy copy should be explicit about whether images remain on device or are uploaded for analysis.
- The current prototype includes a Privacy Center export for structured local state and a Delete local data reset.
- Privacy Center includes bundled Privacy Policy and Terms screens. The approved Privacy Policy must also be hosted and entered in App Store Connect before submission.
- The app target includes `PrivacyInfo.xcprivacy` with a UserDefaults required-reason API declaration for local app settings/state.
- Guided scan reports may store non-image evidence metadata such as frame count and covered face regions. Raw scan frames are short-lived and are not saved in local history in this prototype.
- Manually entered shelf products are stored locally, included in export, and deleted by Delete local data.
- Profile context can include retinoid safety context and ingredient flags; if a remote analyzer is enabled, disclose that those fields are sent for analysis/routine quality and avoid using them for analytics.
- Remote-analysis consent copy should mention scan frames, scan-quality metadata, device model, skin type, baseline feel, routine complexity, budget, goals, sensitivity, ingredient flags, irritants, and retinoid context. Changing the analyzer host, processor, payload, or consent copy should require fresh consent.
- Analytics should not include raw scan images, biometric identifiers, or sensitive health details.
- If any production analyzer uploads images or derived scan data, the privacy policy, App Privacy labels, and review notes must disclose what is collected, why, retention period, and deletion options.
- Product recommendations should disclose any paid placement, affiliate relationship, or brand partnership before launch. Product trust summaries should remain visible anywhere a recommended product or premium alternative appears.
