# Skincare Recommendation App Product Plan

Last updated: 2026-06-12

## Positioning

Build a privacy-first iOS skincare coach that helps people understand their current routine, reduce product guesswork, and track visible progress over time. The app should feel more like a calm daily assistant than a medical evaluator: practical, evidence-literate, and careful about what it can and cannot know from a selfie.

Primary promise:

> Get a simpler, safer-feeling skincare routine based on your goals, products, skin history, and visible progress.

Do not position the MVP as diagnosing acne, rosacea, eczema, melasma, skin cancer, infection, allergy, or any disease. Keep the language in the cosmetic/wellness lane: "visible concerns," "routine suggestions," "ingredient compatibility," "progress tracking," "irritation risk," "hydration-supporting routine," and "breakout-prone skin support."

## Target User Jobs

- Beginner: "I bought products from social media and do not know what order to use them in."
- Sensitive-skin user: "I want to avoid combinations that might irritate me."
- Routine optimizer: "I want to know whether my products duplicate actives or conflict."
- Progress tracker: "I need consistent photos and notes to tell whether a routine is helping."
- Shopper: "I want to scan or search a product before adding it to my routine."

## MVP Scope

Core flows:

- Onboarding quiz: skin goals, skin feel, sensitivity, current routine style, ingredient flags/preferences, and retinoid safety context if the app will mention retinoids or acids.
- Product shelf: manual search first, with owned/using/wishlist/avoided statuses; barcode/OCR later if product database quality is ready.
- Routine builder: AM/PM schedule, product order, frequency, caution flags for common active conflicts.
- Routine adherence: optional customizable local AM/PM reminders with privacy-safe notification copy and no scan findings on the lock screen.
- Recommendation engine: rule-based baseline that explains why each suggestion appears.
- Progress journal: scan-linked notes, skin-feel notes, cycle/stress/sleep optional tags, routine comfort, and routine adherence context.
- Privacy center: photo storage choice, export/delete controls, app-lock toggle, plain-language data use.

Defer until after MVP:

- TrueDepth/ARKit face mesh, if not essential for photo alignment.
- Product purchasing marketplace or affiliate monetization.
- Human expert review.
- Medical triage, lesion detection, rash identification, or diagnosis.

## Trust And Face ID / TrueDepth Wording

Face ID and skin scanning must be described as separate features.

Use Face ID only for app lock:

- "Use Face ID to unlock your private skin journal."
- "This app only receives whether authentication succeeded. It does not receive or store your Face ID data."
- In implementation, use LocalAuthentication for biometric unlock. Apple says apps cannot access the enrolled Face ID data, and App Review says facial recognition for account authentication should use LocalAuthentication where possible.

Do not say:

- "Face ID skin scan"
- "Face ID analyzes your acne"
- "Biometric skin diagnosis"

For the current camera-guided scanner, use wording like:

- "Camera-guided skin check-in"
- "Selfie-based visible progress tracking"
- "TrueDepth-capable camera framing on supported devices"

If using actual TrueDepth/ARKit depth or face geometry later, make the privacy copy explicit:

- "Camera and depth data are used to align your check-in photos and estimate visible skin regions."
- "Processing should happen on device by default."
- "Photos, face geometry, and derived measurements stay on device unless you choose cloud backup or expert review."
- "You can delete scans and photos at any time."

Avoid storing raw face geometry unless there is a clear product need. If any face-derived data leaves the device, treat it as sensitive data, disclose it in App Store privacy details, and explain the retention period in-product before capture.

## Recommendation Strategy

Start with explainable rules, not a black-box "AI dermatologist."

Inputs:

- User goals: acne-prone appearance, redness-prone appearance, dryness, oiliness, uneven tone, texture, visible aging concerns.
- User context: baseline skin feel, routine complexity, ingredient flags/preferences, sensitivity, and retinoid safety context.
- Product metadata: category, ingredients, actives, fragrance/essential oils, exfoliating acids, retinoids, benzoyl peroxide, vitamin C, niacinamide, SPF.
- Routine context: time of day, frequency, recent irritation, user sensitivity.
- Optional environment: UV index, humidity, weather.

Recommendation outputs:

- Routine order and frequency.
- Missing basics: cleanser, moisturizer, sunscreen.
- Overlap warnings: duplicate exfoliants, multiple retinoids, stacked strong actives.
- Caution notes: "consider patch testing," "reduce frequency if irritation appears," "ask a clinician if symptoms are painful, spreading, bleeding, or persistent."
- Progress prompts: "keep this routine stable for 2-4 weeks before changing multiple products."

Every recommendation should include a short reason. Example:

> Use this exfoliant at night 1-2 times weekly because your routine already includes a retinoid, and stacking both daily can increase irritation.

## Competitor Takeaways

The market clusters into four lanes:

- All-in-one skincare operating system: Skin Bliss combines AI face scanning, routine planning, ingredient checks, tracking, product comparison, and shelf analysis.
- Community/product discovery: Picky emphasizes K-beauty reviews, discussions, ingredient analysis, and creator/product testing loops.
- Scanner/ratings trust brand: Yuka wins on speed, simple scores, independence, and label scanning for food and cosmetics.
- Treatment/subscription: Curology and MDacne sell customized treatment plans or products with stronger medical/acne framing.

Position between scanner utility and treatment subscription:

- More personal and routine-aware than Yuka.
- More private and focused than community-first apps.
- Less medically risky than acne-treatment apps.
- More explainable than generic AI-scan apps.

## Paywall

Recommended model: freemium with a premium subscription.

Free:

- Onboarding quiz.
- Product shelf up to a small limit.
- Basic AM/PM routine builder.
- Basic ingredient conflict warnings.
- One baseline scan/photo check-in.
- Privacy controls, delete/export, safety cautions.

Premium:

- Unlimited products and routines.
- Unlimited progress check-ins and photo comparison.
- Advanced ingredient compatibility and duplicate-active analysis.
- Routine timeline and adherence insights.
- Weather/UV/humidity-based nudges.
- Consistency insights from reminder and adherence history.
- Product alternatives and wishlist.
- PDF/shareable routine summary.
- Optional cloud sync, if privacy posture is clear.

Do not put privacy, deletion, safety warnings, or "seek medical care" guidance behind the paywall. Use StoreKit subscriptions for digital features consumed in the app. If the app sells physical skincare products, those payments can use non-IAP commerce, but digital analysis, premium recommendations, and subscriptions should use in-app purchase unless a valid regional entitlement applies.

## Regulatory And Privacy Cautions

Product claims:

- Use wellness/cosmetic language unless the team intentionally pursues medical-device, telehealth, or clinician-supervised workflows.
- Avoid "diagnose," "treat," "cure," "prevent disease," "prescribe," "clinically proven" unless legally reviewed and substantiated.
- Make visible-skin analysis caveats unavoidable: lighting, camera quality, makeup, skin tone, facial hair, and angle can affect results.
- Include escalation language for painful, severe, spreading, bleeding, infected, or persistent symptoms.

FDA / medical-device boundary:

- General education, wellness tracking, and routine organization are lower risk.
- Disease diagnosis, treatment selection for disease, prescription-like recommendations, or lesion/rash assessment can move the app toward regulated medical software.

Apple / App Store:

- Provide accurate App Privacy Details for photos, health/fitness data, sensitive data, identifiers, analytics, purchases, and third-party SDKs.
- Keep account creation optional until needed for sync, subscription, or cross-device functionality.
- For app-lock Face ID, use LocalAuthentication and provide an alternate auth path where required.
- Make non-obvious AI, camera, subscription, and data-retention behavior clear in App Review notes.

Privacy defaults:

- On-device first for photos and analysis.
- No ads or cross-app tracking in MVP.
- No sale of skin, photo, or face-derived data.
- Short retention by default for uploaded images if cloud processing is added.
- Separate consent for research/model improvement, expert review, marketing, and cloud backup.

## Launch Roadmap

Phase 0: Product and data design, 1 week

- Define ingredient taxonomy and rule set.
- Decide no-medical-claims copy rules.
- Write privacy/data inventory before implementation.
- Draft App Store privacy answers from intended data flows.

Phase 1: MVP, 4-6 weeks

- Onboarding quiz.
- Product shelf and manual product entry.
- Routine builder with explainable warnings.
- Local progress journal with scan-linked notes and no raw-photo history by default.
- Face ID app lock.
- Local routine reminders.
- Subscription shell/paywall copy, even if premium is disabled in TestFlight.

Phase 2: TestFlight beta, 2-3 weeks

- Recruit 25-50 users across skin types and routines.
- Validate recommendation clarity, not just feature usage.
- Track false confidence moments: where users think the app diagnosed them.
- Add onboarding caveats where confusion appears.

Phase 3: v1 App Store launch

- Free routine builder plus premium progress and advanced analysis.
- App Store screenshots should show routine clarity, privacy controls, and explainable recommendations.
- Avoid before/after medical-style claims in launch creative.

Phase 4: v1.1-v1.3

- Barcode scan and larger product database.
- OCR ingredient import.
- Weather/UV nudges.
- Better photo alignment.
- Shareable routine summary.

Phase 5: Expansion

- Optional expert review with explicit consent and separate legal/privacy review.
- Brand partnerships only if recommendations remain clearly labeled and not pay-to-rank.
- Clinical or dermatologist-backed claims only after evidence, review, and regulatory strategy.

## Working Sources

- Apple Face ID & Privacy: https://www.apple.com/legal/privacy/data/en/face-id/
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- FDA device software functions and mobile medical apps: https://www.fda.gov/medical-devices/digital-health-center-excellence/device-software-functions-including-mobile-medical-applications
- FDA examples of software functions that are not medical devices: https://www.fda.gov/medical-devices/device-software-functions-including-mobile-medical-applications/examples-software-functions-are-not-medical-devices
- Competitor notes: See `Docs/CompetitorNotes.md`.
