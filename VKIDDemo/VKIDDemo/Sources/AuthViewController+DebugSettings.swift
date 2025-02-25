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
import VKID

extension AuthViewController {
    func buildDebugSettings() -> DebugSettingsViewModel {
        DebugSettingsViewModel(
            title: "DebugSettings",
            sections: [
                .init(
                    title: "Color Scheme",
                    cells: self.colorSchemeCells()
                ),
                .init(
                    title: "Locale",
                    cells: self.localeCells()
                ),
                .init(
                    title: "Network",
                    cells: self.networkConfigurationCells()
                ),
                .init(
                    title: "Auth configuration",
                    cells: self.authConfigurationCells()
                ),
                .init(
                    title: "Scope",
                    cells: self.scopeCells()
                ),
                .init(
                    title: "SDK Configuration",
                    cells: self.sdkConfigurationCells()
                ),
                .init(
                    title: "Group Subscription",
                    cells: self.groupSubscriptionCells()
                ),
            ]
        )
    }

    private func colorSchemeCells() -> [any DebugSettingsCellViewModel] {
        Appearance
            .ColorScheme
            .allCases
            .map { theme in
                DebugSettingsCheckboxCellViewModel(
                    title: "\(theme)",
                    checked: self.appearance.colorScheme == theme
                ) { [weak self] in
                    self?.appearance.colorScheme = theme
                    self?.updateSettings()
                }
            }
    }

    private func localeCells() -> [any DebugSettingsCellViewModel] {
        Appearance
            .Locale
            .allCases
            .map { locale in
                DebugSettingsCheckboxCellViewModel(
                    title: "\(locale)",
                    checked: self.appearance.locale == locale
                ) { [weak self] in
                    self?.appearance.locale = locale
                    self?.updateSettings()
                }
            }
    }

    private func networkConfigurationCells() -> [any DebugSettingsCellViewModel] {
        [
            DebugSettingsToggleCellViewModel(
                title: "SSL Pinning Enabled",
                isOn: self.debugSettings.isSSLPinningEnabled
            ) { [weak self] in
                self?.debugSettings.isSSLPinningEnabled.toggle()
                self?.updateSettings()
            },
            DebugSettingsTextFieldViewModel(
                title: "Custom domain",
                placeholder: "Please, use %@ to place host",
                text: self.debugSettings.customDomainTemplate
            ) { [weak self] text in
                self?.debugSettings.customDomainTemplate = text
            },
        ]
    }

    private func authConfigurationCells() -> [any DebugSettingsCellViewModel] {
        [
            DebugSettingsToggleCellViewModel(
                title: "Confidential flow Enabled",
                isOn: self.debugSettings.confidentialFlowEnabled
            ) { [weak self] in
                self?.debugSettings.confidentialFlowEnabled.toggle()
                self?.updateSettings()
            },
            DebugSettingsToggleCellViewModel(
                title: "PKCE Secrets providing Enabled",
                isOn: self.debugSettings.providedPKCESecretsEnabled
            ) { [weak self] in
                self?.debugSettings.providedPKCESecretsEnabled.toggle()
                self?.updateSettings()
            },
            DebugSettingsTextFieldViewModel(
                title: "Service token",
                placeholder: "Service token",
                text: self.debugSettings.serviceToken
            ) { [weak self] text in
                self?.debugSettings.serviceToken = text
            },
            DebugSettingsToggleCellViewModel(
                title: "Deprecated code exchanging Enabled",
                isOn: self.debugSettings.deprecatedCodeExchangingEnabled
            ) { [weak self] in
                self?.debugSettings.deprecatedCodeExchangingEnabled.toggle()
                self?.updateSettings()
            },
            DebugSettingsToggleCellViewModel(
                title: "Force Web browser flow",
                isOn: self.debugSettings.forceWebBrowserFlow
            ) { [weak self] in
                self?.debugSettings.forceWebBrowserFlow.toggle()
                self?.updateSettings()
            },
        ]
    }

    private func scopeCells() -> [any DebugSettingsCellViewModel] {
        [
            DebugSettingsTextFieldViewModel(
                title: "Scope",
                placeholder: "email phone ...",
                text: self.debugSettings.scope
            ) { [weak self] text in
                self?.debugSettings.scope = text
            },
            DebugSettingsToggleCellViewModel(
                title: "Logging Enabled",
                isOn: self.debugSettings.loggingEnabled
            ) { [weak self] in
                self?.debugSettings.loggingEnabled.toggle()
                self?.updateSettings()
            },
        ]
    }

    private func sdkConfigurationCells() -> [any DebugSettingsCellViewModel] {
        [
            DebugSettingsToggleCellViewModel(
                title: "Flutter flag",
                isOn: self.debugSettings.flutterFlagEnabled
            ) { [weak self] in
                self?.debugSettings.flutterFlagEnabled.toggle()
                self?.updateSettings()
            },
        ]
    }

    private func groupSubscriptionCells() -> [any DebugSettingsCellViewModel] {
        [
            DebugSettingsToggleCellViewModel(
                title: "Group Subscription",
                isOn: self.debugSettings.subscriptionEnabled
            ) { [weak self] in
                self?.debugSettings.subscriptionEnabled.toggle()
                self?.updateSettings()
            },

            DebugSettingsToggleCellViewModel(
                title: "Subscription with external AT",
                isOn: self.debugSettings.subscriptionExternalATEnabled
            ) { [weak self] in
                self?.debugSettings.subscriptionExternalATEnabled.toggle()
                self?.updateSettings()
            },
            DebugSettingsTextFieldViewModel(
                title: "Group Id",
                placeholder: "Should be Integer",
                text: self.debugSettings.groupId
            ) { [weak self] text in
                self?.debugSettings.groupId = text ?? ""
            },
        ]
    }

    func updateSettings() {
        self.debugSettingsVC?.render(viewModel: self.buildDebugSettings())
    }
}
