# DermaLens Privacy Policy Draft

Draft updated June 12, 2026. This is product/legal drafting material, not legal advice. Review with counsel and host the approved policy at the App Store Connect privacy policy URL before TestFlight expansion or App Store submission.

## Summary

DermaLens is designed around local-first cosmetic skincare guidance. The current prototype stores profile choices, generated scan reports, routine state, shelf statuses, reminder preferences, progress journal entries, and optional remote-analysis consent on the user's device. It does not store raw camera frames, saved face photos, Face ID biometric templates, or payment card details.

## Data Stored On Device

- Profile choices: skin feel, routine style, goals, sensitivity, ingredient flags, irritants, fragrance preference, retinoid context, and budget.
- Scan reports: generated cosmetic concern scores, scan-quality metadata, analyzer provenance, and non-image guided-region evidence.
- Routine data: generated AM/PM steps, completion records, premium swap overrides, reminder settings, and ingredient findings.
- Shelf and product data: product statuses, custom products, full ingredient lists when manually entered, and product trust disclosures.
- Journal data: optional progress notes linked to scan reports.
- Privacy settings: journal-lock preference and remote-analysis consent record when granted.

## Camera And Face ID

The camera is used for guided cosmetic face scans. Raw camera frames are short-lived in the prototype and are not persisted in local report history. Face ID, Touch ID, or passcode can protect private reports and journal notes through Apple's system authentication APIs. DermaLens does not receive enrolled biometric templates and does not use Face ID as scan evidence.

## Remote Analysis

The current default build is local-only. If a production remote analyzer is configured, scan-frame upload must be opt-in before frames leave the device. Consent copy must identify the analyzer host, the data sent, and the retention policy. Changing the analyzer host, processor, payload, or consent copy should invalidate prior consent and require a fresh opt-in.

## Purchases

Subscriptions are processed by the App Store through StoreKit. DermaLens reads entitlement status to unlock premium features. The app does not receive full payment card details.

## Analytics And Third Parties

Production analytics should avoid raw scan images, biometric identifiers, and sensitive skin details. If crash reporting, analytics, product feeds, or remote analysis are added, update this policy, App Privacy labels, consent copy, and review notes before release.

## Export And Delete Controls

Users can export a structured copy of local app data from Privacy Center. Users can also delete local DermaLens data on the device, including reports, routine history, shelf statuses, custom products, journal notes, reminder settings, and lock preferences.

## Children And Medical Limits

DermaLens is cosmetic guidance only and is not intended for diagnosis, treatment, or emergency care. See a clinician promptly for painful, changing, bleeding, suspicious, infected, rapidly worsening, or urgent skin concerns.

## Hosted Policy Checklist

- Host the approved policy at a stable HTTPS URL before App Store submission.
- Enter that URL in App Store Connect for each platform.
- Keep the in-app Privacy Policy screen, App Privacy label answers, App Review notes, and hosted policy synchronized.
- Replace this draft if legal review changes collection, retention, deletion, or contact language.
