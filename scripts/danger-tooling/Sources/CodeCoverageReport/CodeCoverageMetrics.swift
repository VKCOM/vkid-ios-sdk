//
// Copyright (c) 2023 - present, LLC “V Kontakte”
//
// 1. Permission is hereby granted to any person obtaining a copy of this Software to
// use the Software without charge.
//
// 2. Restrictions
// You may not modify, merge, publish, distribute, sublicense, and/or sell copies,
// create derivative works based upon the Software or any part thereof.
//
// 3. Termination
// This License is effective until terminated. LLC “V Kontakte” may terminate this
// License at any time without any negative consequences to our rights.
// You may terminate this License at any time by deleting the Software and all copies
// thereof. Upon termination of this license for any reason, you shall continue to be
// bound by the provisions of Section 2 above.
// Termination will be without prejudice to any rights LLC “V Kontakte” may have as
// a result of this agreement.
//
// 4. Disclaimer of warranty and liability
// THE SOFTWARE IS MADE AVAILABLE ON THE “AS IS” BASIS. LLC “V KONTAKTE” DISCLAIMS
// ALL WARRANTIES THAT THE SOFTWARE MAY BE SUITABLE OR UNSUITABLE FOR ANY SPECIFIC
// PURPOSES OF USE. LLC “V KONTAKTE” CAN NOT GUARANTEE AND DOES NOT PROMISE ANY
// SPECIFIC RESULTS OF USE OF THE SOFTWARE.
// UNDER NO CIRCUMSTANCES LLC “V KONTAKTE” BEAR LIABILITY TO THE LICENSEE OR ANY
// THIRD PARTIES FOR ANY DAMAGE IN CONNECTION WITH USE OF THE SOFTWARE.
//

import Foundation
import PluginInfrastructure

public struct CodeCoverageMetricsData: Codable {
    public var coveredLines: Int
    public var executableLines: Int
    public var lineCoverage: Double
}

public typealias CodeCoverageMetricsFile = HealthMetricsFile<CodeCoverageMetricsData>

public final class CodeCoverageMetricsCollector {
    private let xcresultPath: URL
    private let modules: [String]
    private let commitHash: String

    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    public init(
        xcresultPath: URL,
        modules: [String],
        commitHash: String
    ) {
        self.xcresultPath = xcresultPath
        self.modules = modules
        self.commitHash = commitHash
    }

    public func collectMetrics() throws -> CodeCoverageMetricsFile {
        let coverageFilePath = URL.temporaryJSONFile
        defer {
            try? FileManager.default.removeItem(at: coverageFilePath)
        }

        try sh("""
            xcrun xccov view \
            --report "\(self.xcresultPath.path())" \
            --only-targets \(self.modules.joined(separator: " ")) \
            --json > "\(coverageFilePath.path())"
            """)

        let coverageJson = try Data(contentsOf: coverageFilePath)
        let xcodeReport = try self.jsonDecoder.decode(
            [XcodeCoverageReport.Target].self,
            from: coverageJson
        )

        return CodeCoverageMetricsFile(modules: xcodeReport.map { target in
            CodeCoverageMetricsFile.Module(
                name: target.name,
                commits: [
                    .init(
                        hash: self.commitHash,
                        metricsData: .init(
                            coveredLines: target.coveredLines,
                            executableLines: target.executableLines,
                            lineCoverage: target.lineCoverage
                        )
                    ),
                ]
            )
        })
    }
}
