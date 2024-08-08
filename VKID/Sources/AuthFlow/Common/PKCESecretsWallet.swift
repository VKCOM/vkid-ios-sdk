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

internal enum PKCEWalletError: Error {
    case secretsExpired
    case noSecrets
}

internal class PKCESecretsWallet: Expiring {
    internal private(set) var expirationDate: Date
    private var secrets: PKCESecrets?

    var codeVerifier: String? {
        get throws {
            try self.validateSecrets().codeVerifier
        }
    }

    var codeChallenge: String {
        get throws {
            try self.validateSecrets().codeChallenge
        }
    }

    var codeChallengeMethod: PKCESecrets.CodeChallengeMethod {
        get throws {
            try self.validateSecrets().codeChallengeMethod
        }
    }

    var state: String {
        get throws {
            try self.validateSecrets().state
        }
    }

    internal init(
        secrets: PKCESecrets
    ) {
        self.secrets = secrets
        self.expirationDate = Date().addingTimeInterval(15 * 60)
    }

    private func validateSecrets() throws -> PKCESecrets {
        guard !self.isExpired else {
            self.secrets = nil
            throw PKCEWalletError.secretsExpired
        }
        guard let secrets = self.secrets else {
            throw PKCEWalletError.noSecrets
        }
        return secrets
    }

    internal func invalidate() {
        self.secrets = nil
    }
}

extension PKCESecretsWallet: Equatable {
    static func == (lhs: PKCESecretsWallet, rhs: PKCESecretsWallet) -> Bool {
        lhs.secrets == rhs.secrets
    }

    static func ==(lhs: PKCESecretsWallet, rhs: PKCESecrets) throws -> Bool {
        try lhs.validateSecrets() == rhs
    }
}
