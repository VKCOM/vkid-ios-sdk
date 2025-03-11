//
// Copyright (c) 2025 - present, LLC “V Kontakte”
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
@testable import VKIDCore

final class OneTapBottomSheetSnapshotAutoShowTests: XCTestCase, TestCaseInfra {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .ui,
        product: .VKIDSDK,
        feature: "Шторка авторизации",
        priority: .critical
    )
    var vkid: VKID!
    private let window = UIWindow()
    private var viewController: UIViewController!
    private var bottomSheetConfig: OneTapBottomSheet!

    override func setUpWithError() throws {
        let rootContainer = self.createRootContainer()
        rootContainer.authFlowBuilder = AuthFlowBuilderMock()
        self.vkid = self.createVKID(rootContainer: rootContainer)
        self.viewController = UIViewController()
        self.window.rootViewController = self.viewController
        self.window.isUserInteractionEnabled = true
        guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        if #available(iOS 13.0, *) {
            self.window.windowScene = keyWindow.windowScene
        }
        self.window.frame = keyWindow.frame
        self.window.isHidden = false
        self.window.makeKeyAndVisible()
    }

    override func tearDownWithError() throws {
        self.vkid = nil
        self.bottomSheetConfig = nil
    }

    func testBottomSheetUiViewControllerAutoShow() {
        Allure.report(
            .init(
                name: "Проверка автоматического открытия шторки на UIViewController",
                meta: self.testCaseMeta
            )
        )
        let bottomSheetOpened = expectation(description: "Шторка открыта")
        given("Создание конфигурации шторки") {
            self.bottomSheetConfig = OneTapBottomSheet(
                serviceName: "Test",
                targetActionText: .signIn,
                oneTapButton: .init(),
                onCompleteAuth: nil
            )
        }
        when("Показ шторки на UIViewController") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                // Snapshot testing workaround
                self.window.makeKeyAndVisible()
            }
            self.bottomSheetConfig.autoShow(
                .init(
                    presenter: .uiViewController(self.window.topmostViewController!),
                    delayMilliseconds: 500
                ),
                factory: self.vkid!,
                animated: false
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                let presentedViewController = self.window.topmostViewController
                then("Проверка открытой шторки") {
                    XCTAssert(presentedViewController!.isShown(on: self.window))
                    assertSnapshot(
                        of: presentedViewController!,
                        as: .image,
                        testName: "Auto show UIViewController"
                    )
                }
                bottomSheetOpened.fulfill()
            }
            self.wait(for: [bottomSheetOpened], timeout: 2)
        }
    }

    func testBottomSheetCustomAutoShow() {
        Allure.report(
            .init(
                name: "Проверка автоматического открытия шторки на custom presenter",
                meta: self.testCaseMeta
            )
        )
        let bottomSheetOpened = expectation(description: "Шторка открыта")
        given("Создание конфигурации шторки") {
            self.bottomSheetConfig = OneTapBottomSheet(
                serviceName: "Test Custom Presenter Auto Show",
                targetActionText: .signIn,
                oneTapButton: .init(),
                onCompleteAuth: nil
            )
        }
        when("Показ шторки на custom presenter") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                // Snapshot testing workaround
                self.window.makeKeyAndVisible()
            }
            self.bottomSheetConfig.autoShow(
                .init(
                    presenter: .custom(UIKitPresenter.uiViewController(self.viewController)),
                    delayMilliseconds: 500
                ),
                factory: self.vkid!,
                animated: false
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                let presentedViewController = self.window.topmostViewController
                then("Проверка открытой шторки") {
                    XCTAssert(presentedViewController!.isShown(on: self.window))
                    assertSnapshot(
                        of: presentedViewController!,
                        as: .image,
                        testName: "Auto show custom presenter"
                    )
                }
                bottomSheetOpened.fulfill()
            }
            self.wait(for: [bottomSheetOpened], timeout: 2)
        }
    }

    func testBottomSheetNewUIWindowAutoShow() {
        Allure.report(
            .init(
                name: "Проверка автоматического открытия шторки на новом UIWindow",
                meta: self.testCaseMeta
            )
        )
        let bottomSheetOpened = expectation(description: "Шторка открыта")
        given("Создание конфигурации шторки с newUIWindow") {
            self.bottomSheetConfig = OneTapBottomSheet(
                serviceName: "Test New UIWindow",
                targetActionText: .signIn,
                oneTapButton: .init(),
                onCompleteAuth: nil
            )
        }
        when("Показ шторки на новом UIWindow") {
            let presenter = UIKitPresenter.newUIWindow
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                // Snapshot testing workaround
                presenter.presentingWindow?.makeKeyAndVisible()
            }
            self.bottomSheetConfig.autoShow(
                .init(
                    presenter: presenter,
                    delayMilliseconds: 500
                ),
                factory: self.vkid!,
                animated: false
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                guard let newWindow = presenter.presentingWindow,
                      let presentedViewController = newWindow.topmostViewController,
                      presentedViewController is BottomSheetViewController
                else {
                    XCTFail("window or view controller not found")
                    return
                }
                then("Проверка открытой шторки") {
                    XCTAssert(presentedViewController.isShown(on: newWindow))
                    assertSnapshot(
                        of: presentedViewController,
                        as: .image,
                        testName: "Auto show NewUIWindow"
                    )
                }
                bottomSheetOpened.fulfill()
            }
            self.wait(for: [bottomSheetOpened], timeout: 2)
        }
    }

    func testBottomSheetUIWindowAutoShow() {
        Allure.report(
            .init(
                name: "Проверка автоматического открытия шторки на UIWindow",
                meta: self.testCaseMeta
            )
        )
        let bottomSheetOpened = expectation(description: "Шторка открыта")
        given("Создание конфигурации шторки с UIWindow") {
            self.bottomSheetConfig = OneTapBottomSheet(
                serviceName: "Test UIWindow",
                targetActionText: .signIn,
                oneTapButton: .init(),
                onCompleteAuth: nil
            )
        }
        when("Показ шторки на UIWindow") {
            let presenter = UIKitPresenter.uiWindow(self.window)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                // Snapshot testing workaround
                self.window.makeKeyAndVisible()
            }
            self.bottomSheetConfig.autoShow(
                .init(
                    presenter: presenter,
                    delayMilliseconds: 500
                ),
                factory: self.vkid!,
                animated: false
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                guard let newWindow = presenter.presentingWindow,
                      let presentedViewController = newWindow.topmostViewController,
                      presentedViewController is BottomSheetViewController
                else {
                    XCTFail("window or view controller not found")
                    return
                }
                then("Проверка открытой шторки") {
                    XCTAssert(presentedViewController.isShown(on: newWindow))
                    assertSnapshot(
                        of: presentedViewController,
                        as: .image,
                        testName: "Auto show UIWindow"
                    )
                }
                bottomSheetOpened.fulfill()
            }
            self.wait(for: [bottomSheetOpened], timeout: 2)
        }
    }
}
