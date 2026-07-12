import XCTest

final class DermaLensUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = [
            "-dermalensUITesting",
            "-dermalensResetLocalData"
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testOnboardingRoutesToGuidedScanAndKeepsEmptyStates() throws {
        completeBaselineOnboarding()

        XCTAssertTrue(app.staticTexts["Complete scan pass"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Run complete scan"].exists)

        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.staticTexts["Start your baseline scan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Start guided scan"].exists)
        XCTAssertTrue(app.staticTexts["No demo report or routine is used before this capture."].exists)
        XCTAssertFalse(app.staticTexts["Top priorities"].exists)
        XCTAssertFalse(app.staticTexts["Tonight's plan"].exists)
        XCTAssertFalse(app.staticTexts["Today's check-in"].exists)
        XCTAssertFalse(app.buttons["Open premium"].exists)

        app.tabBars.buttons["Insights"].tap()
        XCTAssertTrue(app.staticTexts["No report yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No demo report is used for your real baseline."].exists)

        app.tabBars.buttons["Routine"].tap()
        XCTAssertTrue(app.staticTexts["Routine starts after your scan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No demo products are marked as your routine."].exists)
    }

    func testPaywallShowsSubscriptionTermsAndLegalLinks() throws {
        completeBaselineOnboarding()

        XCTAssertTrue(app.staticTexts["Complete scan pass"].waitForExistence(timeout: 5))
        app.buttons["Unlock ingredient-level report"].tap()

        XCTAssertTrue(app.staticTexts["DermaLens Premium"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Review before purchase."].exists)
        XCTAssertTrue(scrollUntilHittable(app.buttons["LegalLink.privacyPolicy"]))
        XCTAssertTrue(app.buttons["LegalLink.termsOfUse"].exists)
        XCTAssertTrue(app.staticTexts["Subscriptions renew automatically unless canceled in your Apple account settings."].exists)

        app.buttons["LegalLink.privacyPolicy"].tap()
        XCTAssertTrue(app.staticTexts["How DermaLens handles scan, routine, purchase, and account data."].waitForExistence(timeout: 5))
    }

    func testPrivacyCenterSurfacesPoliciesAndClinicalBoundary() throws {
        completeBaselineOnboarding()
        app.tabBars.buttons["Today"].tap()

        app.buttons["Open app menu"].tap()
        app.buttons["Privacy center"].tap()

        XCTAssertTrue(app.staticTexts["Your face data deserves boring honesty."].waitForExistence(timeout: 5))
        XCTAssertTrue(scrollUntilExists(app.staticTexts["Policies"]))
        XCTAssertTrue(app.buttons["LegalLink.privacyPolicy"].exists)
        XCTAssertTrue(app.buttons["LegalLink.termsOfUse"].exists)
        XCTAssertTrue(app.staticTexts["See a clinician for painful, changing, bleeding, suspicious, or urgent skin concerns."].exists)
    }

    private func completeBaselineOnboarding() {
        XCTAssertTrue(app.staticTexts["Set your skin context"].waitForExistence(timeout: 5))

        let continueToScanButton = app.buttons["Continue to guided scan"]
        for _ in 0..<6 where !continueToScanButton.isHittable {
            app.swipeUp()
        }

        XCTAssertTrue(continueToScanButton.waitForExistence(timeout: 3))
        continueToScanButton.tap()
    }

    private func scrollUntilExists(_ element: XCUIElement, maxSwipes: Int = 8) -> Bool {
        for _ in 0..<maxSwipes where !element.exists {
            app.swipeUp()
        }
        return element.exists
    }

    private func scrollUntilHittable(_ element: XCUIElement, maxSwipes: Int = 8) -> Bool {
        for _ in 0..<maxSwipes where !element.isHittable {
            app.swipeUp()
        }
        return element.isHittable
    }
}
