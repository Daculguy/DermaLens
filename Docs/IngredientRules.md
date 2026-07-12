# Ingredient Compatibility Rules

This app uses ingredient rules as product-matching heuristics, not medical advice. Copy and UI labels should say products may "support," "help with," or "be a good fit for" a concern. Avoid wording that promises to diagnose, treat, cure, prevent disease, or replace dermatologist guidance.

## Core Rules

### Duplicate Actives

- Treat strong ingredients as active families, not just exact ingredient-name matches.
- Avoid recommending multiple leave-on products with the same active family in one routine unless the product is intentionally a paired system.
- Key duplicate families:
  - Retinoids: retinol, retinal, retinyl esters, adapalene.
  - Exfoliating acids: glycolic, lactic, mandelic, salicylic, PHAs.
  - Benzoyl peroxide.
  - Strong brighteners: hydroquinone where applicable, high-strength vitamin C, high-strength tranexamic acid.
- If duplicates are unavoidable, prefer the gentler or lower-strength product and explain that the routine avoids stacking similar actives.

### Retinoid and Exfoliant Separation

- Do not recommend retinoids and exfoliating acids in the same evening routine step set.
- If both are relevant, separate them by usage schedule:
  - Retinoid nights.
  - Exfoliant nights.
  - Recovery nights with cleanser, moisturizer, and sunscreen the next morning.
- For new users or sensitive skin, prefer one active category first rather than starting both at once.

### High-Sensitivity Guardrails

- For high sensitivity, impaired barrier, stinging, peeling, eczema-prone, or rosacea-prone profiles:
  - Prefer fragrance-free, alcohol-low, simple-barrier products.
  - Prioritize ceramides, glycerin, panthenol, colloidal oatmeal, allantoin, squalane, and low-strength niacinamide.
  - Avoid routine starts that include multiple strong actives.
  - Avoid harsh scrubs, high-acid exfoliants, and high-frequency exfoliation.
- If the user reports irritation, recommend reducing active frequency and focusing on barrier-supporting products. Keep wording non-medical and suggest professional advice for persistent or severe symptoms.

### Fragrance Preference

- If the user selects fragrance-free or sensitive skin, exclude or down-rank products with fragrance, parfum, essential oils, limonene, linalool, citronellol, geraniol, eugenol, or similar fragrance allergens.
- If the user has no fragrance restriction, fragrance can remain eligible but should not be a positive scoring factor for concern matching.

### Profile Ingredient Flags

- Treat user-selected ingredient flags as conservative routine guardrails, not allergy diagnosis.
- Product metadata can be key-ingredient-only, user-entered partial, complete INCI, or verified INCI. The app may flag or down-rank matching products from any available ingredient signal, but should not promise that a product is free of a user's irritant unless complete or verified INCI data supports it.
- Pregnancy, nursing, or trying-to-conceive retinoid context should hard-exclude retinoid routine picks unless the product flow is explicitly clinician-guided.
- Minimal routine preference should skip optional exfoliation until cleanser, moisturizer, sunscreen, and any core treatment feel stable.

### Sunscreen Priority

- Always prioritize daily broad-spectrum sunscreen in morning routines, especially when recommending retinoids, exfoliants, vitamin C, dark spot products, or acne treatments that may increase photosensitivity or irritation risk.
- For dark spots and redness-prone profiles, sunscreen should rank as a foundation recommendation before optional treatment products.
- Do not recommend photosensitizing evening actives without also ensuring a morning sunscreen recommendation exists.

## Concern Rationale

### Acne-Prone

- Useful ingredient signals: salicylic acid, benzoyl peroxide, adapalene, azelaic acid, niacinamide, zinc PCA, non-comedogenic moisturizers.
- Rationale: prefer ingredients that help manage oil, clogged pores, and visible blemish patterns while preserving barrier support.
- Compatibility: avoid stacking benzoyl peroxide with multiple drying actives in high-sensitivity profiles.

### Redness-Prone

- Useful ingredient signals: azelaic acid, niacinamide, panthenol, allantoin, centella asiatica, colloidal oatmeal, ceramides, green tint where product metadata supports it.
- Rationale: prefer calming, barrier-supporting, and tone-evening ingredients with low irritation potential.
- Compatibility: down-rank fragrance, harsh exfoliants, and aggressive retinoid starts.

### Dark Spots and Uneven Tone

- Useful ingredient signals: sunscreen, vitamin C, niacinamide, azelaic acid, tranexamic acid, alpha arbutin, licorice root, retinoids where tolerated.
- Rationale: sunscreen helps prevent visible spots from worsening; brighteners and retinoids can support a more even-looking tone over time.
- Compatibility: avoid combining multiple strong brighteners with retinoids or exfoliants for sensitive users.

## Implementation Notes

- Score products by concern fit, sensitivity fit, routine slot, and conflict risk.
- Hard-block only clear conflicts such as retinoid safety-context violations, fragrance-free preference violations where metadata is reliable, duplicate strong actives, and same-routine retinoid plus exfoliant pairing.
- Use down-ranking for softer concerns such as mild fragrance presence when no restriction exists, partial ingredient-data confidence, or moderate active strength for normal-tolerance users.
- Prefer routine explanations that name the rule briefly: "avoids stacking exfoliants," "keeps retinoid nights separate," or "prioritizes sunscreen with tone-evening products."
