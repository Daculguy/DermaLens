import XCTest
@testable import DermaLens

final class AppConfigurationTests: XCTestCase {
    func testDefaultsToSimulatedAnalyzerWithoutEndpoint() {
        let configuration = AppConfiguration.make(environment: [:])

        XCTAssertEqual(configuration.analyzerMode, .simulated)
        XCTAssertNil(configuration.remoteEndpoint)
        XCTAssertFalse(configuration.remoteFallbacksToLocal)
    }

    func testUsesRemoteAnalyzerWhenEndpointIsConfigured() {
        let configuration = AppConfiguration.make(environment: [
            AppConfiguration.endpointEnvironmentKey: "https://analysis.example.com/skin",
            AppConfiguration.apiKeyEnvironmentKey: "secret"
        ])

        XCTAssertEqual(configuration.analyzerMode, .remote)
        XCTAssertEqual(configuration.remoteEndpoint?.host, "analysis.example.com")
        XCTAssertTrue(configuration.remoteFallbacksToLocal)
    }

    func testInvalidEndpointFallsBackToSimulatedAnalyzer() {
        let configuration = AppConfiguration.make(environment: [
            AppConfiguration.endpointEnvironmentKey: "not a url"
        ])

        XCTAssertEqual(configuration.analyzerMode, .simulated)
        XCTAssertNil(configuration.remoteEndpoint)
    }

    func testNonHTTPSEndpointFallsBackToSimulatedAnalyzer() {
        let configuration = AppConfiguration.make(environment: [
            AppConfiguration.endpointEnvironmentKey: "http://analysis.example.com/skin"
        ])

        XCTAssertEqual(configuration.analyzerMode, .simulated)
        XCTAssertNil(configuration.remoteEndpoint)
    }
}
