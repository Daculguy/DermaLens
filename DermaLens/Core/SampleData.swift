import Foundation

enum SampleData {
    static let products: [SkincareProduct] = [
        SkincareProduct(
            id: "cleanser-oat-gel",
            name: "Calm Oat Gel Cleanser",
            brand: "Avenance Lab",
            category: .cleanser,
            price: 16,
            budgetTier: .value,
            heroIngredients: ["oat amino acids", "glycerin", "panthenol"],
            concernFit: [.redness, .barrier, .texture],
            fragranceFree: true,
            sensitivityScore: 5,
            usageNote: "Massage for 30 seconds, then rinse with lukewarm water.",
            whyItMatches: "Keeps the cleanse gentle so treatment steps can do the heavy lifting.",
            sourceMetadata: .prototypeCatalog
        ),
        SkincareProduct(
            id: "cleanser-balanced-milk",
            name: "Barrier Milk Cleanser",
            brand: "Soft Circuit",
            category: .cleanser,
            price: 28,
            budgetTier: .balanced,
            heroIngredients: ["ceramides", "squalane", "betaine"],
            concernFit: [.redness, .barrier],
            fragranceFree: true,
            sensitivityScore: 5,
            usageNote: "Use one pump in the morning or two pumps after sunscreen.",
            whyItMatches: "Best for users with sensitivity flags and redness-heavy scans.",
            sourceMetadata: .prototypeCatalog
        ),
        SkincareProduct(
            id: "treatment-azelaic",
            name: "Azelaic Clarity Serum",
            brand: "Plain Theory",
            category: .treatment,
            price: 22,
            budgetTier: .balanced,
            heroIngredients: ["azelaic acid", "niacinamide", "allantoin"],
            concernFit: [.blemishes, .redness, .darkSpots, .texture],
            fragranceFree: true,
            sensitivityScore: 4,
            usageNote: "Apply a pea-sized amount at night, three times weekly to start.",
            whyItMatches: "Targets breakouts, post-blemish tone, and visible redness without stacking too many actives.",
            sourceMetadata: .prototypeCatalog
        ),
        SkincareProduct(
            id: "treatment-niacinamide",
            name: "Even Tone Niacinamide 5",
            brand: "Index Skin",
            category: .treatment,
            price: 14,
            budgetTier: .value,
            heroIngredients: ["niacinamide", "zinc PCA", "licorice root"],
            concernFit: [.pores, .redness, .darkSpots, .blemishes],
            fragranceFree: true,
            sensitivityScore: 4,
            usageNote: "Use after cleansing before moisturizer.",
            whyItMatches: "A low-irritation first active for oiliness, visible pores, and uneven tone.",
            sourceMetadata: .prototypeCatalog
        ),
        SkincareProduct(
            id: "treatment-retinal",
            name: "Retinal Repair Cream",
            brand: "Night Standard",
            category: .treatment,
            price: 44,
            budgetTier: .premium,
            heroIngredients: ["retinaldehyde", "peptides", "ceramides"],
            concernFit: [.texture, .pores, .darkSpots],
            fragranceFree: true,
            sensitivityScore: 3,
            usageNote: "Use only at night, twice weekly at first. Avoid on exfoliation nights.",
            whyItMatches: "Good for texture-heavy scans when the user can tolerate gradual active ramp-up.",
            sourceMetadata: .prototypeCatalog
        ),
        SkincareProduct(
            id: "moisturizer-gel-cream",
            name: "Cloud Water Gel Cream",
            brand: "Everyday Edit",
            category: .moisturizer,
            price: 18,
            budgetTier: .value,
            heroIngredients: ["glycerin", "green tea", "panthenol"],
            concernFit: [.barrier, .redness, .blemishes],
            fragranceFree: true,
            sensitivityScore: 5,
            usageNote: "Use one fingertip amount after treatments.",
            whyItMatches: "Hydrates without a heavy finish, which works well for combination skin.",
            sourceMetadata: .prototypeCatalog
        ),
        SkincareProduct(
            id: "moisturizer-ceramide",
            name: "Ceramide Recovery Cream",
            brand: "Kind Chemistry",
            category: .moisturizer,
            price: 32,
            budgetTier: .balanced,
            heroIngredients: ["ceramide NP", "cholesterol", "madecassoside"],
            concernFit: [.barrier, .redness, .texture],
            fragranceFree: true,
            sensitivityScore: 5,
            usageNote: "Press a thin layer over serum; add more on dry patches.",
            whyItMatches: "Supports the barrier when redness and texture appear together.",
            sourceMetadata: .prototypeCatalog
        ),
        SkincareProduct(
            id: "spf-mineral-fluid",
            name: "Mineral Veil SPF 50",
            brand: "Daylight Lab",
            category: .sunscreen,
            price: 26,
            budgetTier: .balanced,
            heroIngredients: ["zinc oxide", "iron oxides", "bisabolol"],
            concernFit: [.darkSpots, .redness, .barrier],
            fragranceFree: true,
            sensitivityScore: 5,
            usageNote: "Apply two finger lengths every morning as the final step.",
            whyItMatches: "Daily SPF is the non-negotiable step for dark spots and redness-prone skin.",
            sourceMetadata: .prototypeCatalog
        ),
        SkincareProduct(
            id: "spf-gel",
            name: "Invisible Gel SPF 45",
            brand: "Clear Day",
            category: .sunscreen,
            price: 17,
            budgetTier: .value,
            heroIngredients: ["modern UV filters", "silica", "green tea"],
            concernFit: [.darkSpots, .blemishes, .pores],
            fragranceFree: true,
            sensitivityScore: 4,
            usageNote: "Apply generously and reapply when outdoors.",
            whyItMatches: "Lightweight finish for users who skip sunscreen because it feels heavy.",
            sourceMetadata: .prototypeCatalog
        ),
        SkincareProduct(
            id: "exfoliant-pha",
            name: "PHA Polish Tonic",
            brand: "Slow Glow",
            category: .exfoliant,
            price: 24,
            budgetTier: .balanced,
            heroIngredients: ["gluconolactone", "aloe", "centella"],
            concernFit: [.texture, .pores, .darkSpots],
            fragranceFree: true,
            sensitivityScore: 4,
            usageNote: "Use one night weekly. Do not combine with retinal the same night.",
            whyItMatches: "A gentler exfoliation option when texture is visible but sensitivity matters.",
            sourceMetadata: .prototypeCatalog
        )
    ]

    static let previewReport = SkinReport(
        createdAt: Date(),
        scanQuality: .preview,
        evidenceSummary: .previewComplete,
        scores: [
            ConcernScore(
                concern: .redness,
                score: 74,
                confidence: .high,
                primaryRegion: .leftCheek,
                explanation: "Diffuse cheek redness was visible across both cheek zones, strongest on the left side."
            ),
            ConcernScore(
                concern: .texture,
                score: 68,
                confidence: .medium,
                primaryRegion: .forehead,
                explanation: "Uneven texture appeared around the forehead and chin, with moderate image confidence."
            ),
            ConcernScore(
                concern: .blemishes,
                score: 61,
                confidence: .high,
                primaryRegion: .chin,
                explanation: "A few active-looking blemish clusters were detected near the lower face."
            ),
            ConcernScore(
                concern: .darkSpots,
                score: 45,
                confidence: .medium,
                primaryRegion: .rightCheek,
                explanation: "Small uneven-tone areas were visible, but lighting may affect this score."
            ),
            ConcernScore(
                concern: .pores,
                score: 39,
                confidence: .medium,
                primaryRegion: .nose,
                explanation: "Visible pore texture is mild and mostly concentrated through the T-zone."
            )
        ],
        visibleStrengths: [
            "Even overall facial symmetry in the scan",
            "No severe dryness pattern visible",
            "Strong capture quality for progress tracking"
        ],
        summary: "Your highest visible priorities are redness, texture, and lower-face breakouts. The safest first routine is barrier-supportive, fragrance-free, and light on actives."
    )

    static var previewRoutine: RoutinePlan {
        RecommendationEngine().buildRoutine(for: previewReport, profile: .default)
    }
}
