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

public final class CodeCoverageReportGenerator: MetricsReportGenerating {
    public struct ModuleInfo {
        public var name: String
        public var modifiedFileNames: [String]

        public init(module: String, modifiedFileNames: [String]) {
            self.name = module
            self.modifiedFileNames = modifiedFileNames
        }
    }

    private let xcresultPath: URL
    private let sourceCommit: GitCommit
    private let targetCommit: GitCommit
    private let modules: [ModuleInfo]
    private let metricsCollector: CodeCoverageMetricsCollector
    private let storedMetricsFile: CodeCoverageMetricsFile?

    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    public init(
        xcresultPath: URL,
        sourceCommit: GitCommit,
        targetCommit: GitCommit,
        modules: [ModuleInfo],
        metricsCollector: CodeCoverageMetricsCollector,
        storedMetricsFile: CodeCoverageMetricsFile?
    ) {
        self.xcresultPath = xcresultPath
        self.sourceCommit = sourceCommit
        self.targetCommit = targetCommit
        self.modules = modules
        self.metricsCollector = metricsCollector
        self.storedMetricsFile = storedMetricsFile
    }

    public func generateReport() throws -> String {
        let modulesCoverageMapping = try self.metricsCollector.collectMetrics()

        print("Modules coverage mapping: \(modulesCoverageMapping)")
        print("Modules for report: \(self.modules)")

        let metricsFile: CodeCoverageMetricsFile = self.storedMetricsFile ?? CodeCoverageMetricsFile(modules: [])

        var modulesCoverage = ""
        var filesCoverage = ""

        for module in self.modules {
            if let moduleReport = modulesCoverageMapping.findCommit(
                moduleName: module.name,
                commitHash: self.sourceCommit.shortSHA
            )?.metricsData {
                var targetCommitCoverage = "-"
                var diff = "-"

                if let commit = metricsFile.findCommit(
                    moduleName: module.name,
                    commitHash: self.targetCommit.shortSHA
                ) {
                    targetCommitCoverage = self.coverageDetailsString(
                        executableLines: commit.metricsData.executableLines,
                        coveredLines: commit.metricsData.coveredLines,
                        lineCoverage: commit.metricsData.lineCoverage
                    )
                    diff = NumberFormatter
                        .diffPercentFormatter
                        .string(from: .init(
                            value: moduleReport.lineCoverage - commit.metricsData.lineCoverage
                        )) ?? "-"
                }
                let sourceCommitCoverage = self.coverageDetailsString(
                    executableLines: moduleReport.executableLines,
                    coveredLines: moduleReport.coveredLines,
                    lineCoverage: moduleReport.lineCoverage
                )
                modulesCoverage.append(
                    """
                    |\(module.name)|\(sourceCommitCoverage)|\(targetCommitCoverage)|\(diff)|\n
                    """
                )
            }

            let filesCoverageMapping = try self.gatherFilesCoverage(
                for: module.name
            )
            .reportByFileNameMapping
            module.modifiedFileNames
                .compactMap { filesCoverageMapping[$0] }
                .forEach { file in
                    let coverage = self.coverageDetailsString(
                        executableLines: file.executableLines,
                        coveredLines: file.coveredLines,
                        lineCoverage: file.lineCoverage
                    )
                    filesCoverage.append(
                        """
                        |\(module.name)|\(file.name)|\(coverage)|\n
                        """
                    )
                }
        }

        var reportMarkdown = "# Code Coverage Report"
        if modulesCoverage.isEmpty {
            reportMarkdown.append("""
                \n\nNo code coverage info.
                """)
        } else {
            reportMarkdown.append("""
                \n\n|Module|Source branch(\(self.sourceCommit.shortSHALink))|Target branch(\(self.targetCommit
                .shortSHALink))|Diff|
                |:-:|:-:|:-:|:-:|
                \(modulesCoverage)\n\n
                <details>
                    <summary>Coverage of modified files</summary>\n\n

                |Module|File|Source branch(\(self.sourceCommit.shortSHALink))|
                |:-:|:-:|:-:|
                \(filesCoverage)\n\n
                </details>
                """)
        }
        return reportMarkdown
    }

    private func gatherFilesCoverage(for module: String) throws -> [XcodeCoverageReport.File] {
        let coverageFilePath = URL.temporaryJSONFile
        defer {
            try? FileManager.default.removeItem(at: coverageFilePath)
        }

        try sh("""
            xcrun xccov view \
            --report "\(self.xcresultPath.path())" \
            --files-for-target \(module) \
            --json > "\(coverageFilePath.path())"
            """)

        let coverageJson = try Data(contentsOf: coverageFilePath)
        return try self.jsonDecoder.decode(
            [XcodeCoverageReport.FilesForTarget].self,
            from: coverageJson
        ).first?.files ?? []
    }

    private func coverageDetailsString(
        executableLines: Int,
        coveredLines: Int,
        lineCoverage: Double
    ) -> String {
        let coveragePercent = NumberFormatter.percentFormatter.string(from: .init(value: lineCoverage)) ?? "-"
        return "(\(coveredLines)/\(executableLines)) \(coveragePercent)"
    }
}
