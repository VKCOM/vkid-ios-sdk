import BinarySizeReport
import CodeCoverageReport
import Danger
import Foundation
import PluginInfrastructure
import PublicInterfaceChangesReport
import TSCUtility

let danger = Danger()

guard let cwd = Env.pwd else {
    fail("Failed to get current working directory from env")
    fatalError()
}

// assume we are at scripts/danger-tooling
let rootDir = URL(fileURLWithPath: cwd).appending(path: "../..")
let storedMetricsDir = rootDir.appending(path: ".health-metrics")

let mr = danger.gitLab.mergeRequest
let repoURL = URL(string: mr.webUrl.spm_dropSuffix("/-/merge_requests/\(mr.iid)"))!

let sourceCommit = GitCommit(sha: mr.diffRefs.headSha, repoURL: repoURL)
let targetCommit = GitCommit(sha: mr.diffRefs.baseSha, repoURL: repoURL)

let targetBranchLocalRepoPath = rootDir.appending(path: "target-branch-git")
try? FileManager.default.removeItem(at: targetBranchLocalRepoPath)

let targetBranchGit = PluginInfrastructure.Git(repoLocalPath: targetBranchLocalRepoPath)
do {
    try targetBranchGit.clone(from: repoURL.sshGitURL)
    try targetBranchGit.checkout(branch: mr.targetBranch)
    try targetBranchGit.reset(sha: targetCommit.shortSHA)
} catch {
    fail("Failed to prepare target branch git repo \(error)")
    fatalError()
}

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

var reportGenerators: [MetricsReportGenerating] = [
    SizeReportGenerator(
        sourceCommit: sourceCommit,
        targetCommit: targetCommit,
        sourceCommitMetricsCollector: BinarySizeMetricsCollector(
            sampleConfig: .init(
                projectPath: rootDir.appending(
                    path: "scripts/health-metrics/SizeTest/SizeTest.xcodeproj"
                ),
                commitHash: sourceCommit.shortSHA
            )
        ),
        targetCommitMetricsCollector: BinarySizeMetricsCollector(
            sampleConfig: .init(
                projectPath: targetBranchLocalRepoPath.appending(
                    path: "scripts/health-metrics/SizeTest/SizeTest.xcodeproj"
                ),
                commitHash: targetCommit.shortSHA
            )
        ),
        storedMetricsFile: try? .file(
            at: storedMetricsDir.appending(path: MetricsFileName.binarySize)
        )
    )
    .measuredReport,
]
if !modulesToGatherCoverage.isEmpty {
    reportGenerators.append(
        CodeCoverageReportGenerator(
            xcresultPath: rootDir.appending(path: "build-artifacts/VKID.xcresult"),
            sourceCommit: sourceCommit,
            targetCommit: targetCommit,
            modules: modulesToGatherCoverage,
            metricsCollector: CodeCoverageMetricsCollector(
                xcresultPath: rootDir.appending(path: "build-artifacts/VKID.xcresult"),
                modules: modulesToGatherCoverage.map(\.name),
                commitHash: sourceCommit.shortSHA
            ),
            storedMetricsFile: try? .file(
                at: storedMetricsDir.appending(path: MetricsFileName.codeCoverage)
            )
        ).measuredReport
    )
}

reportGenerators.append(
    PublicInterfaceChangesReportGenerator(
        sourceRootPath: rootDir,
        targetBranchProjectPath: targetBranchLocalRepoPath,
        moduleName: "VKID"
    ).measuredReport
)

do {
    try reportGenerators.forEach { generator in
        let report = try generator.generateReport()
        markdown(report)
    }
} catch {
    let msg = "Report generation failed: \(error)"
    fail(msg)
}
