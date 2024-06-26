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

public struct XCArchive {
    public let path: URL

    public var applicationSizeInBytes: Int {
        (try? FileManager.default.sizeOfDirectoryInBytes(
            at: self.path.appending(component: "Products/Applications")
        )) ?? 0
    }
}

public enum XcodeSDK: String {
    case iphoneos
    case iphonesimulator
}

public final class XcodeBuild {
    public init() {}

    public func archive(
        project: URL,
        scheme: String,
        archivePath: URL
    ) throws -> XCArchive {
        try sh("""
                xcodebuild clean archive \
                -project "\(project.path())" \
                -scheme \(scheme) \
                -configuration "Release" \
                -archivePath "\(archivePath.path())" \
                ARCHS=arm64 \
                CODE_SIGN_IDENTITY="" \
                CODE_SIGNING_REQUIRED=NO \
                CODE_SIGNING_ALLOWED=NO \
                ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
            """)
        return XCArchive(path: archivePath)
    }

    public func build(
        project: URL,
        scheme: String,
        configuration: String,
        sdk: XcodeSDK
    ) throws {
        try sh("""
                xcodebuild clean build \
                -project \(project.path()) \
                -scheme \(scheme) \
                -configuration \(configuration) \
                -sdk \(sdk.rawValue)
            """)
    }

    public func getDerivedDataPath(
        project: URL,
        scheme: String,
        configuration: String,
        sdk: XcodeSDK
    ) throws -> URL {
        let output = Pipe()
        try sh("""
                xcodebuild -showBuildSettings \
                -project "\(project.path())" \
                -scheme \(scheme) \
                -configuration \(configuration) \
                -sdk \(sdk.rawValue) \
                | grep -m 1 "CONFIGURATION_BUILD_DIR" | grep -oEi "\\/.*"
            """,
               stdout: output)
        let data = output.fileHandleForReading.availableData
        return String(data: data, encoding: .utf8)?
            .components(separatedBy: .newlines)
            .first
            .flatMap { URL(filePath: $0) } ?? URL(filePath: "")
    }
}
