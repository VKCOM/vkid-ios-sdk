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

import BinarySizeReport
import CodeCoverageReport
import Foundation
import PluginInfrastructure

guard let cwd = Env.pwd else {
    fatalError("No PWD env")
}

do {
    // assume we are at scripts/danger-tooling
    let rootDir = URL(fileURLWithPath: cwd).appending(path: "../..")
    let git = Git(repoLocalPath: rootDir)
    let commitHash = try String(git.head().prefix(8))
    let storedMetricsDir = rootDir.appending(path: ".health-metrics")

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase

    func storeMetricsFile(_ file: Encodable, at path: URL) throws {
        let data = try encoder.encode(file)
        try data.write(to: path, options: .atomic)
    }

    let binarySizeCollector = BinarySizeMetricsCollector(sampleConfig:
        .init(
            projectPath: rootDir.appending(
                path: "scripts/health-metrics/SizeTest/SizeTest.xcodeproj"
            ),
            commitHash: commitHash
        ))
    print("Collecting binary size metrics...")
    let binarySizeMetrics = try binarySizeCollector.collectMetrics()
    let binarySizeFilePath = storedMetricsDir.appending(path: MetricsFileName.binarySize)
    try storeMetricsFile(
        binarySizeMetrics,
        at: binarySizeFilePath
    )
    print("Binary size metrics stored at \(binarySizeFilePath)")

    let codeCoverageCollector = CodeCoverageMetricsCollector(
        xcresultPath: rootDir.appending(path: "build-artifacts/VKID.xcresult"),
        modules: [
            "VKID",
            "VKIDCore",
        ],
        commitHash: commitHash
    )
    print("Collecting code coverage metrics...")
    let codeCoverageMetrics = try codeCoverageCollector.collectMetrics()
    let codeCoverageFilePath = storedMetricsDir.appending(path: MetricsFileName.codeCoverage)
    try storeMetricsFile(
        codeCoverageMetrics,
        at: codeCoverageFilePath
    )
    print("Code coverage metrics stored at \(codeCoverageFilePath)")
} catch {
    fatalError("\(error)")
}
