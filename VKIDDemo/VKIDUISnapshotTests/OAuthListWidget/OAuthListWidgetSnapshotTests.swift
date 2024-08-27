//
// Copyright (c) 2024 - present, LLC “V Kontakte”
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

import SnapshotTesting
import VKIDAllureReport
import VKIDTestingInfra
import XCTest

@_spi(VKIDDebug)
@testable import VKID
@testable import VKIDCore

struct OAuthListWidgetConfiguration {
    var buttonBaseConfiguration: ButtonBaseConfiguration = .init()
    var theme: OAuthListWidget.Theme = .matchingColorScheme(.light)
    var providers: [OAuthProvider] = OAuthProvider.allCases
}

final class OAuthListWidgetSnapshotTests: XCTestCase, TestCaseInfra {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .ui,
        product: .VKIDSDK,
        feature: "Виджет авторизации",
        priority: .critical
    )
    private let defaultConfig: OAuthListWidgetConfiguration = .init()
    var vkid: VKID!
    var widget: OAuthListWidget!
    var widgetView: UIView!

    override func setUpWithError() throws {
        self.vkid = self.createVKID()
    }

    override func tearDownWithError() throws {
        self.vkid = nil
        self.widget = nil
        self.widgetView = nil
    }

    func testMailProvider() {
        Allure.report(
            .init(
                id: 2335339,
                name: "Конфигурация виджета Mail",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            config: .init(
                providers: [.mail]
            ),
            diffConfig: self.defaultConfig
        )
    }

    func testOKProvider() {
        Allure.report(
            .init(
                id: 2335338,
                name: "Конфигурация виджета OK",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            config: .init(
                providers: [.ok]
            ),
            diffConfig: self.defaultConfig
        )
    }

    func testVKIDProvider() {
        Allure.report(
            .init(
                id: 2335340,
                name: "Конфигурация виджета VKID",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            config: self.defaultConfig,
            diffConfig: nil
        )
    }

    func testMailOKProvider() {
        Allure.report(
            .init(
                id: 2335341,
                name: "Конфигурация виджета Mail, OK",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            config: .init(
                providers: [.mail, .ok]
            ),
            diffConfig: self.defaultConfig
        )
    }

    func testMailOKVKIDProvider() {
        Allure.report(
            .init(
                id: 2335336,
                name: "Конфигурация виджета Mail, OK, VKID",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            config: self.defaultConfig,
            diffConfig: nil
        )
    }

    func testButtonHeight() {
        Allure.report(
            .init(
                id: 2341959,
                name: "Конфигурация виджета c разной высотой",
                meta: self.testCaseMeta
            )
        )
        OneTapButton.Layout.Height.allCases.filter {
            $0 != self.defaultConfig.buttonBaseConfiguration.height
        }
        . forEach {
            self.snapshotTest(
                config: .init(
                    buttonBaseConfiguration: .init(height: $0)
                ),
                diffConfig: self.defaultConfig
            )
        }
    }

    func testButtonCornerRadius() {
        Allure.report(
            .init(
                id: 2341967,
                name: "Конфигурация виджета c разными радиусами закругления",
                meta: self.testCaseMeta
            )
        )
        [
            CGFloat(exactly: LayoutConstants.defaultCornerRadius + 2.0)!,
            CGFloat(exactly: LayoutConstants.defaultCornerRadius - 2.0)!,
        ].forEach {
            self.snapshotTest(
                config: .init(
                    buttonBaseConfiguration: .init(cornerRadius: $0)
                ),
                diffConfig: self.defaultConfig
            )
        }
    }

    func testTheme() {
        Allure.report(
            .init(
                id: 2341964,
                name: "Конфигурация виджета c темной темой",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            config: .init(
                theme: .matchingColorScheme(.dark)
            ),
            diffConfig: self.defaultConfig
        )
    }

    private func snapshotTest(
        config: OAuthListWidgetConfiguration,
        diffConfig: OAuthListWidgetConfiguration? = nil
    ) {
        let description: String = Descriptioner.diffDescription(
            config: config,
            withStandard: diffConfig
        )
        given("Создаем конфигурацию виджета c \(description)") {
            self.widget = OAuthListWidget(
                oAuthProviders: config.providers,
                buttonConfiguration: .init(
                    height: config.buttonBaseConfiguration.height,
                    cornerRadius: config.buttonBaseConfiguration.cornerRadius
                ),
                theme: config.theme,
                onCompleteAuth: nil
            )
        }
        when("Создаем виджет и задаем размеры") {
            self.widgetView = self.vkid.ui(for: self.widget).uiView()
            self.widgetView.frame = .widgetFrame
        }
        then("Проверка снапшота виджета c: \(description)") {
            assertSnapshot(of: self.widgetView, as: .image, testName: description)
        }
    }
}
