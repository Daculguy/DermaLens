import Foundation

struct AppConfiguration {
    enum AnalyzerMode: String, Hashable {
        case simulated
        case remote

        var title: String {
            switch self {
            case .simulated: "Simulated local"
            case .remote: "Remote API"
            }
        }
    }

    static let endpointEnvironmentKey = "DERMALENS_ANALYSIS_ENDPOINT"
    static let apiKeyEnvironmentKey = "DERMALENS_ANALYSIS_API_KEY"

    var analyzer: any SkinAnalysisServicing
    var analyzerMode: AnalyzerMode
    var remoteEndpoint: URL?
    var remoteFallbacksToLocal: Bool

    static var current: AppConfiguration {
        make(environment: ProcessInfo.processInfo.environment)
    }

    static func make(environment: [String: String]) -> AppConfiguration {
        if let endpointValue = environment[endpointEnvironmentKey],
           let endpoint = URL(string: endpointValue),
           endpoint.scheme == "https",
           endpoint.host != nil {
            return AppConfiguration(
                analyzer: RemoteSkinAnalysisClient(
                    configuration: .init(
                        endpoint: endpoint,
                        apiKey: environment[apiKeyEnvironmentKey]
                    )
                ),
                analyzerMode: .remote,
                remoteEndpoint: endpoint,
                remoteFallbacksToLocal: true
            )
        }

        return AppConfiguration(
            analyzer: ScanAnalyzer(),
            analyzerMode: .simulated,
            remoteEndpoint: nil,
            remoteFallbacksToLocal: false
        )
    }
}
