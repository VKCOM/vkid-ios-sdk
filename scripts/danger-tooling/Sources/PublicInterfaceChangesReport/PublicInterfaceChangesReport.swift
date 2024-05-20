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
import TSCBasic

public final class PublicInterfaceChangesReportGenerator: MetricsReportGenerating {
    private let sourceRootPath: Foundation.URL
    private let targetBranchProjectPath: Foundation.URL
    private let moduleName: String

    public init(
        sourceRootPath: Foundation.URL,
        targetBranchProjectPath: Foundation.URL,
        moduleName: String
    ) {
        self.sourceRootPath = sourceRootPath
        self.targetBranchProjectPath = targetBranchProjectPath
        self.moduleName = moduleName
    }

    public func generateReport() throws -> String {
        let xcodebuild = XcodeBuild()
        let apiDigester = SwiftAPIDigester()

        let targetBranchAPIDump = TempFile()
        try self.dumpTargetBranchAPI(
            dumpFilePath: targetBranchAPIDump.path,
            xcodebuild: xcodebuild,
            apiDigester: apiDigester
        )

        let currentBranchAPIDump = TempFile()
        try self.dumpCurrentBranchAPI(
            dumpFilePath: currentBranchAPIDump.path,
            xcodebuild: xcodebuild,
            apiDigester: apiDigester
        )

        let diagnosticsFile = TempFile()
        let diff = try apiDigester.diagnoseDiff(
            module: self.moduleName,
            oldDumpPath: targetBranchAPIDump.path,
            newDumpPath: currentBranchAPIDump.path,
            sdk: .iphonesimulator,
            diagnosticsFilePath: diagnosticsFile.path
        )

        var reportMarkdown = "# Public Interface Changes Report"
        if diff.hasAnyChanges {
            if !diff.breakingChanges.isEmpty {
                reportMarkdown.append("""
                    \n\n### 💔 WARNING: Breaking changes detected! Don't forget to bump MAJOR version!\n\n
                    """)
                reportMarkdown.append("```swift\n")
                for change in diff.breakingChanges {
                    reportMarkdown.append("\(change)\n\n")
                }
                reportMarkdown.append("```")
            }
            if !diff.additiveChanges.isEmpty {
                if diff.breakingChanges.isEmpty {
                    reportMarkdown.append("""
                        \n\n### ⚠️ WARNING: Additive changes detected! Don't forget to bump MINOR version!\n\n
                        """)
                } else {
                    reportMarkdown.append("""
                        \n\n### ⚠️ Additive changes:\n\n
                        """)
                }
                reportMarkdown.append("```swift\n")
                for change in diff.additiveChanges {
                    reportMarkdown.append("\(change)\n")
                }
                reportMarkdown.append("```")
            }
        } else {
            reportMarkdown.append("\n\nThere are no changes in public interface")
        }
        return reportMarkdown
    }

    private func dumpTargetBranchAPI(
        dumpFilePath: URL,
        xcodebuild: borrowing XcodeBuild,
        apiDigester: borrowing SwiftAPIDigester
    ) throws {
        let configuration = "Debug"
        let sdk = XcodeSDK.iphonesimulator
        let scheme = "VKIDDemo"

        let projectPath = self.targetBranchProjectPath.appending(path: "VKIDDemo/VKIDDemo.xcodeproj")
        try xcodebuild.build(
            project: projectPath,
            scheme: scheme,
            configuration: configuration,
            sdk: sdk
        )
        let derivedDataPath = try xcodebuild.getDerivedDataPath(
            project: projectPath,
            scheme: scheme,
            configuration: configuration,
            sdk: sdk
        )

        try apiDigester.dumpPublicInterface(
            module: self.moduleName,
            sdk: sdk,
            outputJSONFile: dumpFilePath,
            target: "arm64-apple-ios17.2-simulator",
            importSearchPath: derivedDataPath
        )
    }

    private func dumpCurrentBranchAPI(
        dumpFilePath: URL,
        xcodebuild: borrowing XcodeBuild,
        apiDigester: borrowing SwiftAPIDigester
    ) throws {
        let projectPath = self.sourceRootPath.appending(path: "VKIDDemo/VKIDDemo.xcodeproj")
        let derivedDataPath = try xcodebuild.getDerivedDataPath(
            project: projectPath,
            scheme: "VKIDDemo",
            configuration: "Debug",
            sdk: .iphonesimulator
        )
        try apiDigester.dumpPublicInterface(
            module: self.moduleName,
            sdk: .iphonesimulator,
            outputJSONFile: dumpFilePath,
            target: "arm64-apple-ios17.2-simulator",
            importSearchPath: derivedDataPath
        )
    }
}
