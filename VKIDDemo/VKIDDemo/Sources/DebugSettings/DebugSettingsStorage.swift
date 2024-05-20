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

final class DebugSettingsStorage {
    private enum Keys: String {
        case sslPinningEnabled = "com.vkid.debug.sslPinningEnabled"
        case customDomainTemplate = "com.vkid.debug.customDomainTemplate"
        case providedPKCESecretsEnabled = "com.vkid.debug.providedPKCESecretsEnabled"
        case confidentialFlowEnabled = "com.vkid.debug.confidentialFlowEnabled"
        case serviceToken = "com.vkid.debug.serviceToken"
        case scopes = "com.vkid.debug.scopes"
    }

    private let userDefaults = UserDefaults.standard

    var isSSLPinningEnabled: Bool {
        get {
            (self.userDefaults.value(
                forKey: Keys.sslPinningEnabled.rawValue
            ) as? Bool) ?? true
        }
        set {
            self.userDefaults.setValue(
                newValue,
                forKey: Keys.sslPinningEnabled.rawValue
            )
        }
    }

    var customDomainTemplate: String? {
        get {
            (self.userDefaults.value(
                forKey: Keys.customDomainTemplate.rawValue
            ) as? String)
        }
        set {
            self.userDefaults.setValue(
                newValue,
                forKey: Keys.customDomainTemplate.rawValue
            )
        }
    }

    var providedPKCESecretsEnabled: Bool {
        get {
            (self.userDefaults.value(
                forKey: Keys.providedPKCESecretsEnabled.rawValue
            ) as? Bool) ?? false
        }
        set {
            self.userDefaults.setValue(
                newValue,
                forKey: Keys.providedPKCESecretsEnabled.rawValue
            )
        }
    }

    var confidentialFlowEnabled: Bool {
        get {
            (self.userDefaults.value(
                forKey: Keys.confidentialFlowEnabled.rawValue
            ) as? Bool) ?? false
        }
        set {
            self.userDefaults.setValue(
                newValue,
                forKey: Keys.confidentialFlowEnabled.rawValue
            )
        }
    }

    var serviceToken: String? {
        get {
            (self.userDefaults.value(
                forKey: Keys.serviceToken.rawValue
            ) as? String)
        }
        set {
            self.userDefaults.setValue(
                newValue,
                forKey: Keys.serviceToken.rawValue
            )
        }
    }

    var scopes: String? {
        get {
            (self.userDefaults.value(
                forKey: Keys.scopes.rawValue
            ) as? String)
        }
        set {
            self.userDefaults.setValue(
                newValue,
                forKey: Keys.scopes.rawValue
            )
        }
    }
}
