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

public struct BinarySizeMetricsData: Codable {
    public var binarySizeInBytes: Int
}

public typealias BinarySizeMetricsFile = HealthMetricsFile<BinarySizeMetricsData>

public struct MeasureBinarySizeSampleConfig {
    public var projectPath: URL
    public var emptyScheme: String
    public var integratedSDKScheme: String
    public var commitHash: String

    public init(
        projectPath: URL,
        emptyScheme: String = "SizeTestEmpty",
        integratedSDKScheme: String = "SizeTest",
        commitHash: String
    ) {
        self.projectPath = projectPath
        self.emptyScheme = emptyScheme
        self.integratedSDKScheme = integratedSDKScheme
        self.commitHash = commitHash
    }
}

public final class BinarySizeMetricsCollector {
    private let sampleConfig: MeasureBinarySizeSampleConfig

    public init(
        sampleConfig: MeasureBinarySizeSampleConfig
    ) {
        self.sampleConfig = sampleConfig
    }

    public func collectMetrics() throws -> BinarySizeMetricsFile {
        let archivePath = URL.temporaryFile(extension: "xcarchive")
        defer {
            try? FileManager.default.removeItem(at: archivePath)
        }
        let xcodebuild = XcodeBuild()

        let appWithSDKArchive = try xcodebuild.archive(
            project: self.sampleConfig.projectPath,
            scheme: self.sampleConfig.integratedSDKScheme,
            archivePath: archivePath
        )
        let appWithSDKSize = appWithSDKArchive.applicationSizeInBytes

        let emptyAppArchive = try xcodebuild.archive(
            project: self.sampleConfig.projectPath,
            scheme: self.sampleConfig.emptyScheme,
            archivePath: archivePath
        )
        let emptyAppSize = emptyAppArchive.applicationSizeInBytes
        let sdkBinarySize = appWithSDKSize - emptyAppSize
        return BinarySizeMetricsFile(modules: [
            .init(
                name: "VKID",
                commits: [
                    .init(
                        hash: self.sampleConfig.commitHash,
                        metricsData: .init(binarySizeInBytes: sdkBinarySize)
                    ),
                ]
            ),
        ])
    }
}
