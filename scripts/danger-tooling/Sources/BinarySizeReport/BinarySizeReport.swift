import Foundation
import PluginInfrastructure

public final class SizeReportGenerator: MetricReportGenerating {
    private let projectPath: URL
    private let emptyScheme: String
    private let integratedSDKScheme: String
    private let sourceCommit: GitCommit
    private let targetCommit: GitCommit

    public init(
        projectPath: URL,
        emptyScheme: String,
        integratedSDKScheme: String,
        sourceCommit: GitCommit,
        targetCommit: GitCommit
    ) {
        self.projectPath = projectPath
        self.emptyScheme = emptyScheme
        self.integratedSDKScheme = integratedSDKScheme
        self.sourceCommit = sourceCommit
        self.targetCommit = targetCommit
    }

    public func generateReport() throws -> String {
        let archivePath = URL.temporaryFile(extension: "xcarchive")
        defer {
            try? FileManager.default.removeItem(at: archivePath)
        }
        let xcodebuild = XcodeBuild()

        let appWithSDKArchive = try xcodebuild.archive(
            project: self.projectPath,
            scheme: self.integratedSDKScheme,
            archivePath: archivePath
        )
        let appWithSDKSize = appWithSDKArchive.applicationSizeInBytes

        let emptyAppArchive = try xcodebuild.archive(
            project: self.projectPath,
            scheme: self.emptyScheme,
            archivePath: archivePath
        )
        let emptyAppSize = emptyAppArchive.applicationSizeInBytes
        let sdkBinarySize = appWithSDKSize - emptyAppSize

        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useKB, .useMB]
        let sizeString = byteCountFormatter.string(fromByteCount: Int64(sdkBinarySize))

        return """
            # Binary Size Report
            |Module|Source branch(\(self.sourceCommit.shortSHALink))|Target branch(\(self.targetCommit
            .shortSHALink))|Diff|
            |:-:|:-:|:-:|:-:|
            |VKID|\(sizeString)|-|-|-|
            """
    }
}
