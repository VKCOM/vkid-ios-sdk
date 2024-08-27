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

@testable import VKID

final class OneTapButtonSnapshotTests: XCTestCase, TestCaseInfra {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .ui,
        product: .VKIDSDK,
        feature: "OneTap",
        priority: .critical
    )
    private let defaultConfig: OneTapButtonConfiguration = .init()
    var vkid: VKID!
    private var oneTapButton: OneTapButton!
    private var oneTapButtonView: UIView!

    override func setUpWithError() throws {
        self.vkid = self.createVKID()
    }

    override func tearDownWithError() throws {
        self.vkid = nil
        self.oneTapButton = nil
        self.oneTapButtonView = nil
    }

    func testDefaultState() {
        Allure.report(
            .init(
                id: 2334369,
                name: "OneTap кнопка",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            config: .init(),
            diffConfig: nil
        )
    }

    func testOKAlternativeProvider() {
        Allure.report(
            .init(
                id: 2334368,
                name: "OneTap кнопка с провайдером ОК",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            config: .init(alternativeProviders: [.ok]),
            diffConfig: self.defaultConfig
        )
    }

    func testMailAlternativeProvider() {
        Allure.report(
            .init(
                id: 2334366,
                name: "OneTap кнопка с провайдером Mail",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            config: .init(alternativeProviders: [.mail]),
            diffConfig: self.defaultConfig
        )
    }

    func testMailAndOKAlternativeProvider() {
        Allure.report(
            .init(
                id: 2334367,
                name: "OneTap кнопка с провайдерами Mail и OK",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            config: .init(alternativeProviders: [.mail, .ok]),
            diffConfig: self.defaultConfig
        )
    }

    func testTitle() {
        Allure.report(
            .init(
                id: 2341968,
                name: "Проверка тайтлов",
                meta: self.testCaseMeta
            )
        )

        OneTapButton.Appearance.Title.RawType.allCases.filter {
            $0 != self.defaultConfig.title?.rawType &&
                $0 != OneTapButton.Appearance.Title.RawType.custom
        }.forEach {
            self.snapshotTest(
                config: OneTapButtonConfiguration(title: try! $0.title),
                diffConfig: self.defaultConfig
            )
        }
    }

    func testStyle() {
        Allure.report(
            .init(
                id: 2341965,
                name: "Проверка стилей",
                meta: self.testCaseMeta
            )
        )
        OneTapButton.Appearance.Style.allCases.filter {
            $0 != self.defaultConfig.style
        }
        .forEach {
            self.snapshotTest(
                config: OneTapButtonConfiguration(style: $0),
                diffConfig: self.defaultConfig
            )
        }
    }

    func testKind() {
        Allure.report(
            .init(
                id: 2341963,
                name: "Проверка типа лейаута кнопки",
                meta: self.testCaseMeta
            )
        )

        OneTapButton.Layout.Kind.allCases.filter { $0 != self.defaultConfig.kind }.forEach {
            self.snapshotTest(
                config: OneTapButtonConfiguration(kind: $0),
                diffConfig: self.defaultConfig
            )
        }
    }

    func testHeight() {
        Allure.report(
            .init(
                id: 2341962,
                name: "Проверка высоты кнопки",
                meta: self.testCaseMeta
            )
        )
        OneTapButton.Layout.Height.allCases.filter {
            $0 != self.defaultConfig.buttonBaseConfiguration.height
        }
        .forEach {
            self.snapshotTest(
                config: OneTapButtonConfiguration(
                    buttonBaseConfiguration: .init(height: $0)
                ),
                diffConfig: self.defaultConfig
            )
        }
    }

    func testCornerRadius() {
        Allure.report(
            .init(
                id: 2341961,
                name: "Проверка радиуса скругления",
                meta: self.testCaseMeta
            )
        )
        [
            CGFloat(exactly: LayoutConstants.defaultCornerRadius + 2.0)!,
            CGFloat(exactly: LayoutConstants.defaultCornerRadius - 2.0)!,
        ].forEach {
            self.snapshotTest(
                config: OneTapButtonConfiguration(
                    buttonBaseConfiguration: .init(cornerRadius: $0)
                ),
                diffConfig: self.defaultConfig
            )
        }
    }

    func testTheme() {
        Allure.report(
            .init(
                id: 2341960,
                name: "Проверка темной темы",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(
            config: .init(
                theme: OneTapButton.Appearance.Theme.matchingColorScheme(.dark)
            ),
            diffConfig: self.defaultConfig
        )
    }

    private func snapshotTest(
        config: OneTapButtonConfiguration,
        diffConfig: OneTapButtonConfiguration?
    ) {
        let description = Descriptioner.diffDescription(
            config: config,
            withStandard: diffConfig
        )
        given(
            "Конфигурация OneTap c \(description)"
        ) {
            self.oneTapButton = config.createOneTapButton()
        }
        when("Создание 'view' и установка размеров") {
            self.oneTapButtonView = self.vkid.ui(for: self.oneTapButton).uiView()
            self.oneTapButtonView.frame = .oneTapButtonWithProvidersFrame
        }
        then("Проверка 'view'") {
            assertSnapshot(
                of: self.oneTapButtonView,
                as: .image,
                testName: "\(description)"
            )
        }
    }
}

extension OneTapButton.Appearance.Title.RawType {
    var title: OneTapButton.Appearance.Title {
        get throws {
            switch self {
            case .calculate: .calculate
            case .signUp: .signUp
            case .get: .get
            case .open: .open
            case .order: .order
            case .makeOrder: .makeOrder
            case .submitRequest: .submitRequest
            case .participate: .participate
            case .vkid: .vkid
            case .ok: .ok
            case .mail: .mail
            default: throw NSError(domain: "Not supported Title", code: 0)
            }
        }
    }
}
