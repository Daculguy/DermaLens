# DermaLens Analyzer Validation Model Card

Draft updated June 12, 2026. This document defines the evidence DermaLens needs before replacing the simulated analyzer with a vendor API or in-house model. It is intentionally stricter than a demo because the scan output influences product recommendations and user trust.

## Intended Use

- Cosmetic visible-skin guidance for routine planning.
- Concern prioritization for non-medical categories such as visible breakouts, redness appearance, dark-spot appearance, texture appearance, visible pores, under-eye tone, and barrier-looking stress.
- Scan-quality feedback and confidence labeling.
- Product and routine reasoning that stays tied to user profile context, ingredient data quality, and product trust disclosures.

## Not Intended For

- Diagnosis, disease detection, treatment selection, prescriptions, emergency triage, or lesion risk scoring.
- Melanoma, cancer, infection, rash diagnosis, acne severity diagnosis, or any medical-device claim.
- Identity verification, age estimation, ethnicity inference, or biometric enrollment.

## Required Evaluation Sets

Each candidate analyzer must be evaluated before beta expansion:

- Skin tone: balanced coverage across Fitzpatrick I-VI or an equivalent documented skin-tone scale.
- Device coverage: current iPhone front cameras, older supported iPhone front cameras, and at least one TrueDepth-capable device.
- Lighting: bright indoor, dim indoor, backlit, warm bathroom lighting, cool office lighting, outdoor shade, and glare/glasses cases.
- Pose and framing: centered, mild yaw/pitch, partial off-center, hair/hand obstruction, mask/occlusion, motion blur.
- Age range: teen/adult/older-adult representation only if allowed by product policy and consent.
- Sensitive exclusions: no minors or medical-condition images unless legal, consent, and regulatory review explicitly approve.

## Metrics

Use thresholds per concern and per subgroup, not only aggregate accuracy:

- Capture gating: low-quality scans should be blocked or labeled low confidence.
- Repeatability: three good scans in similar conditions should produce stable top concerns and routine direction.
- Calibration: confidence labels should match observed error rates.
- False reassurance: concerning, low-quality, obstructed, or out-of-scope scans must not produce high-confidence cosmetic recommendations.
- Fairness: quality scores and concern estimates should not systematically underperform by skin tone, age band, lighting condition, device class, or glasses/no-glasses status.
- Explainability: every concern output should include visible-region rationale and confidence strong enough to support the recommendation surface.

## Acceptance Gates

A candidate analyzer is not launch-ready until it passes:

- No high-confidence output for blocked or low-quality scans.
- Documented subgroup performance with known weaknesses and mitigations.
- Stable top-two concern ordering for repeat scans under similar quality.
- Region evidence mapping that distinguishes fresh guided capture from prompt-only hints, with anatomical verification reserved for a future validated verifier.
- Human review of false positives and false negatives for every supported concern.
- A rollback plan and clear fallback behavior when remote analysis fails.
- Privacy review for payload, retention, processor, deletion, and logging behavior.

## Runtime Transparency

Every saved report should expose:

- Analyzer kind: simulated local, remote, remote fallback, or local due to consent off.
- Provider/model name, model version, validation status, and request ID when available.
- Scan-quality score, confidence label, blocked issues, and guided-capture coverage.
- Whether remote upload was attempted.
- A plain-language limitation when the analyzer is simulated, unvalidated, fallback, or low confidence.

## Vendor Acceptance Criteria

Before signing a vendor or enabling a backend in production:

- Obtain model/version documentation and intended-use limits.
- Confirm retention defaults, deletion timelines, logging exclusions, and subprocessor list.
- Run the DermaLens evaluation set instead of accepting only vendor benchmark claims.
- Require per-request IDs and model versions in responses.
- Require low-quality rejection or uncertainty fields rather than forcing confident output.
- Validate that no face recognition, identity, biometric enrollment, age inference, or medical diagnosis is performed unless separately approved.

## Beta Evidence Checklist

For each TestFlight build using a non-simulated analyzer, archive:

- Build number, analyzer provider, model version, and endpoint host.
- Test device matrix and iOS versions.
- Lighting/device/skin-tone coverage summary.
- Repeatability results.
- Known failure modes and copy mitigations.
- Remote fallback/error logs without raw images.
- App Privacy label, Privacy Policy, consent copy, and data-retention review.
