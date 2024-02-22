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

public final class CodeCoverageReportGenerator: MetricReportGenerating {
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

    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    public init(
        xcresultPath: URL,
        sourceCommit: GitCommit,
        targetCommit: GitCommit,
        modules: [ModuleInfo]
    ) {
        self.xcresultPath = xcresultPath
        self.sourceCommit = sourceCommit
        self.targetCommit = targetCommit
        self.modules = modules
    }

    public func generateReport() throws -> String {
        let modulesCoverageMapping = try self.gatherModulesCoverage()
            .reportByTargetNameMapping

        print("Modules coverage mapping: \(modulesCoverageMapping)")
        print("Modules for report: \(self.modules)")

        var reportMarkdown = "# Code Coverage Report"

        for module in self.modules {
            if let moduleReport = modulesCoverageMapping[module.name] {
                reportMarkdown.append(
                    """
                    \n\n## \(module.name)
                    Overall module coverage - (\(moduleReport.coveredLines)/\(moduleReport.executableLines), \
                    \(String(format: "%.2f", moduleReport.lineCoverage * 100))%)
                    """
                )
            }
            reportMarkdown.append(
                """
                \n\n|File|Source branch(\(self.sourceCommit.shortSHALink))|Target branch(\(self.targetCommit
                    .shortSHALink))|Diff|
                |:-:|:-:|:-:|:-:|
                """
            )
            let filesCoverageMapping = try self.gatherFilesCoverage(
                for: module.name
            )
            .reportByFileNameMapping
            for file in module.modifiedFileNames {
                let report = filesCoverageMapping[file]
                reportMarkdown.append(
                    """
                    \n|\(file)|\(String(format: "%.2f", (report?.lineCoverage ?? 0) * 100))%|||
                    """
                )
            }
        }

        return reportMarkdown
    }

    private func gatherModulesCoverage() throws -> [XcodeCoverageReport.Target] {
        let coverageFilePath = URL.temporaryJSONFile
        defer {
            try? FileManager.default.removeItem(at: coverageFilePath)
        }

        try sh("""
            xcrun xccov view \
            --report "\(self.xcresultPath.path())" \
            --only-targets \(self.modules.map(\.name).joined(separator: " ")) \
            --json > "\(coverageFilePath.path())"
            """)

        let coverageJson = try Data(contentsOf: coverageFilePath)
        return try self.jsonDecoder.decode(
            [XcodeCoverageReport.Target].self,
            from: coverageJson
        )
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
}

private enum XcodeCoverageReport {
    struct File: Decodable {
        let name: String
        let path: String
        let coveredLines: Int
        let executableLines: Int
        let lineCoverage: Double
    }

    struct FilesForTarget: Decodable {
        let files: [XcodeCoverageReport.File]
    }

    struct Target: Decodable {
        let name: String
        let buildProductPath: String
        let coveredLines: Int
        let executableLines: Int
        let lineCoverage: Double
    }
}

extension Array where Element == XcodeCoverageReport.File {
    fileprivate var reportByFileNameMapping: [String: XcodeCoverageReport.File] {
        self.reduce(into: [:]) { partialResult, item in
            partialResult[item.name] = item
        }
    }
}

extension Array where Element == XcodeCoverageReport.Target {
    fileprivate var reportByTargetNameMapping: [String: XcodeCoverageReport.Target] {
        self.reduce(into: [:]) { partialResult, item in
            partialResult[item.name] = item
        }
    }
}
