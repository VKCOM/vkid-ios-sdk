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
        case scope = "com.vkid.debug.scope"
        case authViewUI = "com.vkid.debug.authViewUI"
        case oAuthProviders = "com.vkid.debug.oAuthProviders"
        case deprecatedCodeExchangingEnabled = "com.vkid.debug.deprecatedCodeExchangingEnabled"
        case loggingEnabled = "com.vkid.debug.loggingEnabled"
        case forceWebBrowserFlow = "com.vkid.debug.forceWebBrowserFlow"
        case flutterFlagEnabled = "com.vkid.debug.flutterFlagEnabled"
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

    var authViewUI: Int {
        get {
            (self.userDefaults.value(
                forKey: Keys.authViewUI.rawValue
            ) as? Int) ?? 1
        }
        set {
            self.userDefaults.setValue(
                newValue,
                forKey: Keys.authViewUI.rawValue
            )
        }
    }

    var oAuthProviders: Int {
        get {
            (self.userDefaults.value(
                forKey: Keys.oAuthProviders.rawValue
            ) as? Int) ?? 0
        }
        set {
            self.userDefaults.setValue(
                newValue,
                forKey: Keys.oAuthProviders.rawValue
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

    var scope: String? {
        get {
            (self.userDefaults.value(
                forKey: Keys.scope.rawValue
            ) as? String)
        }
        set {
            self.userDefaults.setValue(
                newValue,
                forKey: Keys.scope.rawValue
            )
        }
    }

    var deprecatedCodeExchangingEnabled: Bool {
        get {
            (self.userDefaults.value(
                forKey: Keys.deprecatedCodeExchangingEnabled.rawValue
            ) as? Bool) ?? false
        }
        set {
            self.userDefaults.setValue(
                newValue,
                forKey: Keys.deprecatedCodeExchangingEnabled.rawValue
            )
        }
    }

    var loggingEnabled: Bool {
        get {
            (self.userDefaults.value(
                forKey: Keys.loggingEnabled.rawValue
            ) as? Bool) ?? true
        }
        set {
            self.userDefaults.setValue(
                newValue,
                forKey: Keys.loggingEnabled.rawValue
            )
        }
    }

    var forceWebBrowserFlow: Bool {
        get {
            (self.userDefaults.value(
                forKey: Keys.forceWebBrowserFlow.rawValue
            ) as? Bool) ?? false
        }
        set {
            self.userDefaults.setValue(
                newValue,
                forKey: Keys.forceWebBrowserFlow.rawValue
            )
        }
    }

    var flutterFlagEnabled: Bool {
        get {
            (self.userDefaults.value(
                forKey: Keys.flutterFlagEnabled.rawValue
            ) as? Bool) ?? false
        }
        set {
            self.userDefaults.setValue(
                newValue,
                forKey: Keys.flutterFlagEnabled.rawValue
            )
        }
    }
}
