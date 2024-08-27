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

final class OneTapBottomSheetTests: XCTestCase, TestCaseInfra {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .ui,
        product: .VKIDSDK,
        feature: "Шторка авторизации",
        priority: .critical
    )
    var vkid: VKID!
    let authFlowBuilderMock = AuthFlowBuilderMock()

    override func setUpWithError() throws {
        let rootContainer = RootContainer(
            appCredentials: Entity.appCredentials,
            networkConfiguration: .init(isSSLPinningEnabled: false)
        )
        rootContainer.authFlowBuilder = self.authFlowBuilderMock
        self.vkid = self.createVKID(rootContainer: rootContainer)
    }

    override func tearDownWithError() throws {
        self.vkid = nil
    }

    func testConfiguration() {
        Allure.report(
            .init(
                id: 2315470,
                name: "По клику на OneTap кнопку вызываем VKID.authorize с соответствующими параметрами",
                meta: self.testCaseMeta
            )
        )
        var oneTapBottomSheet: OneTapBottomSheet!
        let expectation = XCTestExpectation()
        given("Конфигурация OneTap, имитация авторизации") {
            let secrets = try! PKCESecrets()
            let authConfiguration = AuthConfiguration(
                flow: .publicClientFlow(pkce: secrets),
                scope: Scope("testScope testScope2")
            )
            let oAuthProviderConfiguration = OAuthProviderConfiguration(primaryProvider: .vkid)
            oneTapBottomSheet = OneTapBottomSheet(
                serviceName: "Test",
                targetActionText: .applyFor,
                oneTapButton: .init(),
                authConfiguration: authConfiguration,
                onCompleteAuth: nil
            )
            self.authFlowBuilderMock.serviceAuthFlowHandler = { _, config, _ in
                then("Проверка полученной конфигурации") {
                    XCTAssertEqual(config.oAuthProvider, .vkid)
                    XCTAssertEqual(Scope(config.scope), authConfiguration.scope)
                    XCTAssert(try! config.pkceSecrets == secrets)
                    XCTAssert(try! config.equals(
                        authConfiguration: authConfiguration,
                        oAuthProviderConfiguration: oAuthProviderConfiguration
                    ))
                    expectation.fulfill()
                }
                return AuthFlowMock()
            }
        }
        when("Нажатие на кнопку OneTapBottomSheet") {
            let oneTapBottomSheetView = self.vkid.ui(for: oneTapBottomSheet).uiViewController()
            if let control: UIControl = oneTapBottomSheetView.view.findElements({
                $0.accessibilityIdentifier == AccessibilityIdentifier.OneTapButton.signIn.id
            }).first {
                control.sendActions(for: .touchUpInside)
            }
            self.wait(for: [expectation], timeout: 1)
        }
    }
}
