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

public enum ShellError: Error {
    case unknown
    case failed(terminationStatus: Int32)
    case crashed
    case generic(reason: String)
}

public func sh(
    _ cmd: String,
    stdout: Pipe? = nil,
    printCmd: Bool = true
) throws {
    let shell = Process()
    shell.executableURL = URL(filePath: "/bin/zsh")
    shell.arguments = ["-c", cmd]
    if let stdout {
        shell.standardOutput = stdout
    }

    if printCmd {
        print(cmd)
    }

    try shell.run()
    shell.waitUntilExit()

    switch shell.terminationReason {
    case .exit:
        if shell.terminationStatus != 0 {
            throw ShellError.failed(terminationStatus: shell.terminationStatus)
        }
    case .uncaughtSignal:
        throw ShellError.crashed
    @unknown default:
        throw ShellError.unknown
    }
}
