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
import VKID
import XCTest
@testable import VKIDAllureReport

final class OneTapButtonSnapshotTests: XCTestCase, TestCaseInfra {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .ui,
        product: .VKIDSDK,
        feature: "OneTap",
        priority: .critical
    )
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

    func testIconState() {
        Allure.report(
            .init(
                id: 2334370,
                name: "OneTap иконка",
                meta: self.testCaseMeta
            )
        )
        given("Конфигурация OneTap") {
            self.oneTapButton = OneTapButton(
                layout: .logoOnly(),
                onCompleteAuth: nil
            )
        }
        when("Создание 'view'") {
            self.oneTapButtonView = self.vkid.ui(for: self.oneTapButton).uiView()
        }
        then("Проверка 'view'") {
            assertSnapshot(of: self.oneTapButtonView, as: .image)
        }
    }

    func testButtonState() {
        Allure.report(
            .init(
                id: 2334369,
                name: "OneTap кнопка",
                meta: self.testCaseMeta
            )
        )
        given("Конфигурация OneTap") {
            self.oneTapButton = OneTapButton(onCompleteAuth: nil)
        }
        when("Создание 'view' и установка размеров") {
            self.oneTapButtonView = self.vkid.ui(for: self.oneTapButton).uiView()
            self.oneTapButtonView.frame = .oneTapButtonFrame
        }
        then("Проверка 'view'") {
            assertSnapshot(of: self.oneTapButtonView, as: .image)
        }
    }

    func testOKAlternativeProvider() {
        Allure.report(
            .init(
                id: 2334368,
                name: "OneTap кнопка с провайдером ОК",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(with: [.ok], testName: #function)
    }

    func testMailAlternativeProvider() {
        Allure.report(
            .init(
                id: 2334366,
                name: "OneTap кнопка с провайдером Mail.ru",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(with: [.mail], testName: #function)
    }

    func testMailAndOKAlternativeProvider() {
        Allure.report(
            .init(
                id: 2334367,
                name: "OneTap кнопка с провайдерами Mail.ru и OK",
                meta: self.testCaseMeta
            )
        )
        self.snapshotTest(with: [.mail, .ok], testName: #function)
    }

    private func snapshotTest(with oAuthProviders: [OAuthProvider], testName: String) {
        given("Конфигурация OneTap c \(oAuthProviders.description)") {
            self.oneTapButton = OneTapButton(
                oAuthProviderConfiguration: .init(
                    alternativeProviders: oAuthProviders
                ),
                onCompleteAuth: nil
            )
        }
        when("Создание 'view' и установка размеров") {
            self.oneTapButtonView = self.vkid.ui(for: self.oneTapButton).uiView()
            self.oneTapButtonView.frame = .oneTapButtonWithProvidersFrame
        }
        then("Проверка 'view'") {
            assertSnapshot(of: self.oneTapButtonView, as: .image, testName: testName)
        }
    }
}
