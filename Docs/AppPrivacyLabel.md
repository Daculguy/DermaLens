# App Privacy Label Draft

Draft updated June 12, 2026. App Privacy answers must match the exact production build, backend, analytics, SDKs, and data retention policy at submission time.

## Current Local-Only Prototype

If the submitted build has no remote analyzer, no developer-operated account system, no analytics SDK, no crash reporter that sends user data, and no product-data backend that receives user context, the developer does not collect user data off device from DermaLens app features. Local-only storage should still be explained in the hosted privacy policy and in Privacy Center.

StoreKit purchase processing is handled by Apple. Do not claim DermaLens receives payment card details.

## If Remote Analysis Ships

If scan frames or derived scan data leave the device, complete App Privacy labels for the actual payload and backend behavior. Likely categories to review:

- Photos or Videos / User Content: scan frames if uploaded.
- Sensitive Info: skin images or skin-condition context if Apple classifies the payload as sensitive.
- Health and Fitness: avoid this category unless the product actually collects health data; keep positioning cosmetic.
- Purchases: subscription entitlement status if collected by developer infrastructure.
- Identifiers: user ID, device ID, installation ID, or request ID if sent to developer infrastructure.
- Diagnostics: crash logs or performance data if crash reporting is added.
- Usage Data: product taps, scan funnel, or paywall events if analytics is added.

For each category, answer whether data is linked to the user, used for tracking, shared with third parties, and used for app functionality, analytics, product personalization, or other purposes.

## Submission Checklist

- Match App Privacy answers to `Docs/PrivacyPolicy.md`, in-app Privacy Policy text, App Review notes, and remote-analysis consent copy.
- Recheck labels whenever analytics, crash reporting, remote analysis, product feeds, accounts, or support tooling changes.
- Keep raw scan images, biometric identifiers, and sensitive skin details out of analytics unless a reviewed privacy basis exists.
- Document retention, deletion, and processor names before public launch.
