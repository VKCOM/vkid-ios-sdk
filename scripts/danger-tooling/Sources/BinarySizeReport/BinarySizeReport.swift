import Foundation
import PluginInfrastructure

public final class SizeReportGenerator: MetricsReportGenerating {
    private let sourceCommit: GitCommit
    private let targetCommit: GitCommit
    private let sourceCommitMetricsCollector: BinarySizeMetricsCollector
    private let targetCommitMetricsCollector: BinarySizeMetricsCollector
    private let storedMetricsFile: BinarySizeMetricsFile?

    public init(
        sourceCommit: GitCommit,
        targetCommit: GitCommit,
        sourceCommitMetricsCollector: BinarySizeMetricsCollector,
        targetCommitMetricsCollector: BinarySizeMetricsCollector,
        storedMetricsFile: BinarySizeMetricsFile?
    ) {
        self.sourceCommit = sourceCommit
        self.targetCommit = targetCommit
        self.sourceCommitMetricsCollector = sourceCommitMetricsCollector
        self.targetCommitMetricsCollector = targetCommitMetricsCollector
        self.storedMetricsFile = storedMetricsFile
    }

    public func generateReport() throws -> String {
        let moduleName = "VKID"

        let sourceCommitMetrics = try self.sourceCommitMetricsCollector.collectMetrics()
        let sourceCommitBinarySize = sourceCommitMetrics.findCommit(
            moduleName: moduleName,
            commitHash: self.sourceCommit.shortSHA
        )?.metricsData.binarySizeInBytes ?? 0

        let targetCommitBinarySize: Int
        if
            let storedMetricsFile,
            let commit = storedMetricsFile.findCommit(
                moduleName: moduleName,
                commitHash: self.targetCommit.shortSHA
            )
        {
            targetCommitBinarySize = commit.metricsData.binarySizeInBytes
        } else {
            let metrics = try self.targetCommitMetricsCollector.collectMetrics()
            targetCommitBinarySize = metrics.findCommit(
                moduleName: moduleName,
                commitHash: self.targetCommit.shortSHA
            )?.metricsData.binarySizeInBytes ?? 0
        }

        return self.generateReportText(
            sourceCommitBinarySize: sourceCommitBinarySize,
            sourceCommitLink: self.sourceCommit.shortSHALink,
            targetCommitBinarySize: targetCommitBinarySize,
            targetCommitLink: self.targetCommit.shortSHALink,
            moduleName: moduleName
        )
    }

    private func generateReportText(
        sourceCommitBinarySize: Int,
        sourceCommitLink: String,
        targetCommitBinarySize: Int,
        targetCommitLink: String,
        moduleName: String
    ) -> String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useBytes, .useKB, .useMB]

        let sourceCommitSizeString = byteCountFormatter.string(fromByteCount: Int64(sourceCommitBinarySize))
        let targetCommitSizeString = byteCountFormatter.string(fromByteCount: Int64(targetCommitBinarySize))

        let diff = sourceCommitBinarySize - targetCommitBinarySize
        let diffSizeString = byteCountFormatter.string(fromByteCount: Int64(diff))
        let diffPercent = Double(diff) / Double(targetCommitBinarySize)
        let diffPercentString = NumberFormatter
            .diffPercentFormatter
            .string(from: NSNumber(value: diffPercent)) ?? ""

        let diffString: String
        if diff <= 0 {
            diffString = "\(diffSizeString)(\(diffPercentString) 📉)"
        } else {
            diffString = "+\(diffSizeString)(\(diffPercentString) 📈)"
        }

        return """
            # Binary Size Report
            |Module|Source branch(\(sourceCommitLink))|Target branch(\(targetCommitLink))|Diff|
            |:-:|:-:|:-:|:-:|
            |\(moduleName)|\(sourceCommitSizeString)|\(targetCommitSizeString)|\(diffString)|
            """
    }
}
