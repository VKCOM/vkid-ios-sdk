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
import TSCBasic
import TSCUtility

public struct SwiftAPIDigester {
    public init() {}

    public func dumpPublicInterface(
        module: String,
        sdk: XcodeSDK,
        outputJSONFile: Foundation.URL,
        target: String,
        importSearchPath: Foundation.URL
    ) throws {
        try sh("""
            xcrun -sdk \(sdk.rawValue) swift-api-digester -dump-sdk \
            -sdk $(xcrun --sdk \(sdk.rawValue) --show-sdk-path) \
            -module \(module) \
            -o \(outputJSONFile.path()) \
            -target \(target) \
            -I \(importSearchPath.path())
            """)
    }

    public func diagnoseDiff(
        module: String,
        oldDumpPath: Foundation.URL,
        newDumpPath: Foundation.URL,
        sdk: XcodeSDK,
        diagnosticsFilePath: Foundation.URL
    ) throws -> APIDiff {
        try? sh("""
            xcrun -sdk \(sdk.rawValue) swift-api-digester -diagnose-sdk \
            --input-paths \(oldDumpPath.path()) \
            --input-paths \(newDumpPath.path()) \
            -serialize-diagnostics-path \(diagnosticsFilePath.path()) \
            -print-module -abi
            """)

        let diffFilePath = try AbsolutePath(validating: diagnosticsFilePath.path())
        let contents = try localFileSystem.readFileContents(diffFilePath)
        let serializedDiagnostics = try SerializedDiagnostics(bytes: contents)
        return APIDiff(
            module: module,
            breakingChanges: serializedDiagnostics
                .diagnostics
                .filter { $0.level == .error || $0.level == .fatal }
                .map(\.formattedText),
            additiveChanges: serializedDiagnostics
                .diagnostics
                .filter { $0.level == .warning }
                .map(\.formattedText)
        )
    }
}

public struct APIDiff {
    public let module: String
    public let breakingChanges: [String]
    public let additiveChanges: [String]

    public var hasAnyChanges: Bool {
        !self.breakingChanges.isEmpty || !self.additiveChanges.isEmpty
    }
}

extension SerializedDiagnostics.Diagnostic {
    var formattedText: String {
        self.text.replacingOccurrences(
            of: "ABI breakage: ",
            with: ""
        )
    }
}
