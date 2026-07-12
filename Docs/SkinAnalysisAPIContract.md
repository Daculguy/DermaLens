# Skin Analysis API Contract

DermaLens currently runs with a simulated local analyzer. `RemoteSkinAnalysisClient` defines the intended production contract for a vendor API or first-party backend.

## Request

`POST /skin-analysis`

Headers:

- `Content-Type: application/json`
- `Authorization: Bearer <api-key>` when configured

## iOS Configuration

Set these Xcode launch environment variables for a beta build:

- `DERMALENS_ANALYSIS_ENDPOINT`
- `DERMALENS_ANALYSIS_API_KEY` optional

If `DERMALENS_ANALYSIS_ENDPOINT` is absent or invalid, the app uses the simulated local analyzer.

Even when a valid remote endpoint is configured, iOS must not upload frames until the user grants remote-analysis consent in the scan or privacy flow. Consent is scoped to the configured host and consent-copy version; a host or copy change must require a fresh opt-in.

Body:

```json
{
  "createdAt": "2026-06-11T22:00:00Z",
  "deviceModel": "iPhone",
  "quality": {
    "lighting": 0.88,
    "alignment": 0.92,
    "stability": 0.86,
    "clarity": 0.9,
    "depthGuidanceAvailable": true
  },
  "evidenceSummary": {
    "capturedFrameCount": 5,
    "coveredRegions": ["forehead", "leftCheek", "rightCheek", "nose", "chin"],
    "requiredRegions": ["forehead", "leftCheek", "rightCheek", "nose", "chin"],
    "coverageScore": 1.0,
    "createdFromImageEvidence": true,
    "regionEvidence": [
      {
        "region": "forehead",
        "frameCount": 1,
        "freshGuidedFrameCount": 1,
        "verifiedFrameCount": 0,
        "averageQuality": 0.89,
        "confidence": "high"
      },
      {
        "region": "leftCheek",
        "frameCount": 1,
        "freshGuidedFrameCount": 1,
        "verifiedFrameCount": 0,
        "averageQuality": 0.88,
        "confidence": "high"
      },
      {
        "region": "rightCheek",
        "frameCount": 1,
        "freshGuidedFrameCount": 1,
        "verifiedFrameCount": 0,
        "averageQuality": 0.87,
        "confidence": "high"
      },
      {
        "region": "nose",
        "frameCount": 1,
        "freshGuidedFrameCount": 1,
        "verifiedFrameCount": 0,
        "averageQuality": 0.86,
        "confidence": "high"
      },
      {
        "region": "chin",
        "frameCount": 1,
        "freshGuidedFrameCount": 1,
        "verifiedFrameCount": 0,
        "averageQuality": 0.86,
        "confidence": "high"
      }
    ]
  },
  "profile": {
    "skinType": "Combination",
    "baselineSkinFeel": "balanced",
    "sensitivity": 3,
    "routineComplexity": "steady",
    "budget": "balanced",
    "avoidsFragrance": true,
    "avoidsRetinoids": false,
    "knownIrritants": ["fragrance"],
    "retinoidSafetyContext": "comfortable",
    "currentGoals": ["blemishes", "redness", "texture"]
  },
  "frames": [
    {
      "capturedAt": "2026-06-11T22:00:00Z",
      "regionHint": "forehead",
      "sourceFrameID": 42,
      "verificationStatus": "freshGuidedCapture",
      "qualitySnapshot": {
        "lighting": 0.88,
        "alignment": 0.92,
        "stability": 0.86,
        "clarity": 0.9,
        "depthGuidanceAvailable": true
      },
      "jpegBase64": "<base64-jpeg>"
    },
    {
      "capturedAt": "2026-06-11T22:00:01Z",
      "regionHint": "leftCheek",
      "sourceFrameID": 43,
      "verificationStatus": "freshGuidedCapture",
      "qualitySnapshot": {
        "lighting": 0.88,
        "alignment": 0.9,
        "stability": 0.86,
        "clarity": 0.88,
        "depthGuidanceAvailable": true
      },
      "jpegBase64": "<base64-jpeg>"
    },
    {
      "capturedAt": "2026-06-11T22:00:02Z",
      "regionHint": "rightCheek",
      "sourceFrameID": 44,
      "verificationStatus": "freshGuidedCapture",
      "qualitySnapshot": {
        "lighting": 0.87,
        "alignment": 0.91,
        "stability": 0.85,
        "clarity": 0.87,
        "depthGuidanceAvailable": true
      },
      "jpegBase64": "<base64-jpeg>"
    },
    {
      "capturedAt": "2026-06-11T22:00:03Z",
      "regionHint": "nose",
      "sourceFrameID": 45,
      "verificationStatus": "freshGuidedCapture",
      "qualitySnapshot": {
        "lighting": 0.87,
        "alignment": 0.9,
        "stability": 0.84,
        "clarity": 0.86,
        "depthGuidanceAvailable": true
      },
      "jpegBase64": "<base64-jpeg>"
    },
    {
      "capturedAt": "2026-06-11T22:00:04Z",
      "regionHint": "chin",
      "sourceFrameID": 46,
      "verificationStatus": "freshGuidedCapture",
      "qualitySnapshot": {
        "lighting": 0.86,
        "alignment": 0.9,
        "stability": 0.84,
        "clarity": 0.86,
        "depthGuidanceAvailable": true
      },
      "jpegBase64": "<base64-jpeg>"
    }
  ]
}
```

## Response

```json
{
  "modelVersion": "vendor-model-2026-06",
  "requestID": "req_123",
  "validationStatus": "vendorProvided",
  "summary": "Your main visible priorities are redness and texture.",
  "visibleStrengths": [
    "Strong enough image quality for a baseline"
  ],
  "scores": [
    {
      "concern": "redness",
      "score": 72,
      "confidence": "high",
      "primaryRegion": "leftCheek",
      "explanation": "Diffuse cheek redness was visible across both cheek zones."
    }
  ]
}
```

## Required Backend Behavior

- Reject low-quality frames before producing confident recommendations.
- Reject incomplete `evidenceSummary` guided-capture coverage before producing a remote report. The iOS client also blocks report and routine creation until it has fresh, unique, usable guided frames for the forehead, cheeks, T-zone, and chin regions. Do not treat `freshGuidedCapture` as anatomical region verification unless a future landmark/depth verifier explicitly returns `regionVerified`.
- Use each frame's `qualitySnapshot` and `verificationStatus` to explain weak per-region evidence rather than hiding every limitation behind one global score.
- Return confidence per concern, not only a global score. The iOS client caps concern confidence by local evidence confidence before saving the report.
- Return `modelVersion`, `requestID`, and `validationStatus` so the iOS app can show analyzer provenance in Diagnostics and privacy export. If `validationStatus` is omitted, the client labels the report `unvalidatedRemote` and surfaces a visible caution.
- Avoid disease diagnosis labels unless the product intentionally enters medical-device/telehealth scope.
- Delete raw frames after analysis by default unless the user has separately opted into image history.
- Treat profile fields such as retinoid safety context and ingredient flags as sensitive. Send them only for analysis/routine quality, avoid logging them in analytics, and disclose the transfer in privacy copy before remote beta expansion.
- If the iOS client falls back locally after a failed remote request, preserve metadata showing that remote upload was attempted. Incomplete local evidence should fail before upload and should not be recorded as a remote upload attempt.
- Log model/version metadata internally for auditability and fairness testing.
