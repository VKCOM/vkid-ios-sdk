import BinarySizeReport
import CodeCoverageReport
import Danger
import Foundation
import PluginInfrastructure

let danger = Danger()

guard let cwd = ProcessInfo.processInfo.environment["PWD"] else {
    fail("Failed to get current working directory from env")
    fatalError()
}

// assume we are at scripts/danger-tooling
let sizeTestProjectPath = URL(fileURLWithPath: cwd)
    .appending(path: "../health-metrics/SizeTest/SizeTest.xcodeproj")

let rootDir = URL(fileURLWithPath: cwd).appending(path: "../..")

let mr = danger.gitLab.mergeRequest
let sourceCommit = GitCommit.vkid(sha: mr.diffRefs.headSha)
let targetCommit = GitCommit.vkid(sha: mr.diffRefs.baseSha)

let modifiedFilesByModule: [String: CodeCoverageReportGenerator.ModuleInfo] =
    (danger.git.modifiedFiles + danger.git.createdFiles)
    .reduce(into: [:]) { result, file in
        let filePath = (file as NSString)
        guard
            file.fileType == .swift, // Grab only swift files
            filePath.pathComponents.count >= 2
        else {
            return
        }

        let moduleName = filePath.pathComponents.first!
        let fileName = filePath.pathComponents.last!

        var module =
            result[moduleName] ??
            CodeCoverageReportGenerator.ModuleInfo(
                module: moduleName,
                modifiedFileNames: []
            )
        module.modifiedFileNames.append(fileName)
        result[moduleName] = module
    }

let modulesToGatherCoverage: [CodeCoverageReportGenerator.ModuleInfo] = [
    modifiedFilesByModule["VKID"],
    modifiedFilesByModule["VKIDCore"],
].compactMap { $0 }

var reportGenerators: [MetricReportGenerating] = [
    SizeReportGenerator(
        projectPath: sizeTestProjectPath,
        emptyScheme: "SizeTestEmpty",
        integratedSDKScheme: "SizeTest",
        sourceCommit: sourceCommit,
        targetCommit: targetCommit
    )
    .measuredReport,
]
if !modulesToGatherCoverage.isEmpty {
    reportGenerators.append(
        CodeCoverageReportGenerator(
            xcresultPath: rootDir.appending(path: "build-artifacts/VKID.xcresult"),
            sourceCommit: sourceCommit,
            targetCommit: targetCommit,
            modules: modulesToGatherCoverage
        ).measuredReport
    )
}

do {
    try reportGenerators.forEach { generator in
        let report = try generator.generateReport()
        markdown(report)
    }
} catch {
    let msg = "Report generation failed: \(error)"
    fail(msg)
    fatalError(msg)
}
