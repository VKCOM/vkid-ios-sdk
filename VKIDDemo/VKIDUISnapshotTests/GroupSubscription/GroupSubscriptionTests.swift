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

@_spi(VKIDDebug)
@testable import VKID
@testable import VKIDCore

final class GroupSubscriptionSnapshotTests: XCTestCase, TestCaseInfra {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .ui,
        product: .VKIDSDK,
        feature: "Подписка на сообщество",
        priority: .critical
    )
    var vkid: VKID!
    private let window = UIWindow()
    private var authFlowBuilderMock: AuthFlowBuilderMock!
    private var viewController: UIViewController!
    private var bottomSheetViewController: UIViewController!
    private var groupSubscriptionConfig: GroupSubscriptionConfiguration!
    private var groupSubscriptionSheet: GroupSubscriptionSheet!
    private var groupSubscriptionServiceMock: GroupSubscriptionServiceMock!
    private var groupSubscriptionStorage: SubscriptionStorageService!
    private var defaultUserID = UserID(value: 0)

    private let limitOfSubscriptionsToShow: UInt = 2
    private let periodOfSubscriptionToShow: UInt = 30

    private let defaultGroupInfo = GroupInfo(
        id: 1,
        name: "Test Group",
        groupAvatar: nil,
        description: "Test Group Description",
        isVerified: true,
        isMember: false,
        isClosed: false
    )

    override func setUpWithError() throws {
        self.authFlowBuilderMock = AuthFlowBuilderMock()
        let rootContainer = self.createRootContainer()
        rootContainer.authFlowBuilder = self.authFlowBuilderMock
        self.groupSubscriptionStorage = rootContainer.subscriptionStorageService
        self.vkid = self.createVKID(
            rootContainer: rootContainer,
            groupSubscriptionsLimit: .init(
                maxSubsctiptionsToShow: self.limitOfSubscriptionsToShow,
                periodInDays: self.periodOfSubscriptionToShow
            )
        )
        self.viewController = UIViewController()
        self.window.makeKeyAndVisible()
        self.window.rootViewController = self.viewController
        self.groupSubscriptionServiceMock = .init()
        self.vkid.rootContainer.groupSubscriptionService = self.groupSubscriptionServiceMock
        GroupSubscriptionSheet.snackbarTime = .milliseconds(500)
        self.groupSubscriptionStorage.saveSubscriptionInfo(.init(
            subscriptionShownHistory: [],
            userId: self.defaultUserID
        ))
    }

    override func tearDownWithError() throws {
        self.vkid = nil
        self.viewController = nil
        self.bottomSheetViewController = nil
        self.groupSubscriptionConfig = nil
        self.authFlowBuilderMock = nil
    }

    func testSeparateSubscriptionSuccess() {
        Allure.report(
            .init(
                name: "Успешная подписка на сообщество",
                meta: self.testCaseMeta
            )
        )
        let subscriptionExpectation = expectation(description: #function)
        let accessTokenExpectation = expectation(description: "access token provided")
        var providedToken = false

        given("Создание конфигурации подписки") {
            let presenter = UIKitPresenter.uiWindow(self.window)
            self.groupSubscriptionSheet = GroupSubscriptionSheet(
                subscribeToGroupId: "1",
                presenter: presenter,
                onCompleteSubscription: { result in
                    switch result {
                    case .success:
                        subscriptionExpectation.fulfill()
                    case.failure:
                        XCTFail("Failed subscription")
                    }
                },
                accessTokenProvider: { needToRefresh, completion in
                    if !providedToken {
                        accessTokenExpectation.fulfill()
                        providedToken = true
                    }
                    completion(.success("accessToken"))
                }
            )
            self.groupSubscriptionServiceMock.handler = { _, _ in
                .success((
                    self.defaultGroupInfo,
                    [.init(avatarURL: nil)],
                    friendsCount: 2,
                    membersCount: 3,
                    isServiceAccount: false,
                    show: true
                ))
            }
            self.groupSubscriptionServiceMock.subscribeToGroupHandler = { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if let window = UIApplication.shared.windows
                        .first(where: { $0.isKeyWindow && $0.topmostViewController is BottomSheetViewController })
                    {
                        assertSnapshot(
                            of: window.topmostViewController!,
                            as: .image,
                            testName: "Snackbar"
                        )
                        // Snapshot testing workaround
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            presenter.presentingWindow?.makeKeyAndVisible()
                        }
                    } else {
                        XCTFail("Snackbar not found")
                    }
                }
                // Snapshot testing workaround
                presenter.presentingWindow?.makeKeyAndVisible()
                return .success(true)
            }
        }
        when("Показ подписки") {
            self.groupSubscriptionSheet.show(
                on: self.viewController,
                vkid: self.vkid
            ) { result in
                switch result {
                case.success(let newViewController):
                    then("Проверка снапшота шторки и результата") {
                        assertSnapshot(
                            of: newViewController,
                            as: .image,
                            testName: "Subscription view"
                        )
                        if let control: UIControl = newViewController.view.findElements({
                            $0.accessibilityIdentifier == AccessibilityIdentifier
                                .GroupSubscriptionSheet
                                .Button
                                .followCommunity
                                .id
                        }).first {
                            control.sendActions(for: .touchUpInside)
                        }
                    }
                case.failure(let error):
                    XCTFail("Ошибка создания подписки \(error)")
                }
            }
            self.wait(for: [subscriptionExpectation, accessTokenExpectation], timeout: 2)
        }
    }

    func testSeparateSubscriptionFailure() {
        Allure.report(
            .init(
                name: "Ошибка подписки на сообщество",
                meta: self.testCaseMeta
            )
        )
        let subscriptionExpectation = expectation(description: #function)
        let accessTokenExpectation = expectation(description: "access token provided")
        var providedToken = false

        given("Создание конфигурации подписки") {
            let presenter = UIKitPresenter.uiWindow(self.window)
            self.groupSubscriptionSheet = GroupSubscriptionSheet(
                subscribeToGroupId: "1",
                presenter: presenter,
                onCompleteSubscription: { result in
                    switch result {
                    case .success:
                        XCTFail("Success subscription")
                    default:
                        subscriptionExpectation.fulfill()
                    }
                },
                accessTokenProvider: { needToRefresh, completion in
                    if !providedToken {
                        accessTokenExpectation.fulfill()
                        providedToken = true
                    }
                    completion(.success("accessToken"))
                }
            )
            self.groupSubscriptionServiceMock.handler = { _, _ in
                .success((
                    GroupInfo(id: 1,
                              name: "Test Group",
                              groupAvatar: nil,
                              description: "Test Group Description",
                              isVerified: true,
                              isMember: false,
                              isClosed: false),
                    [.init(avatarURL: nil)],
                    friendsCount: 2,
                    membersCount: 3,
                    isServiceAccount: false,
                    show: true
                ))
            }
            self.groupSubscriptionServiceMock.subscribeToGroupHandler = { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if let failedViewController = self.window.topmostViewController as? BottomSheetViewController {
                        assertSnapshot(
                            of: failedViewController,
                            as: .image,
                            testName: "Failed subscription"
                        )
                        if let control: UIControl = failedViewController.view.findElements({
                            $0.accessibilityIdentifier == AccessibilityIdentifier
                                .GroupSubscriptionSheet
                                .Button
                                .cancel
                                .id
                        }).first {
                            control.sendActions(for: .touchUpInside)
                        }
                    }
                }
                // Snapshot testing workaround
                self.window.makeKeyAndVisible()
                return .success(false)
            }
        }
        when("Показ подписки") {
            self.groupSubscriptionSheet.show(
                on: self.viewController,
                vkid: self.vkid
            ) { result in
                switch result {
                case.success(let newViewController):
                    then("Проверка снапшота шторки и результата") {
                        assertSnapshot(
                            of: self.window.topmostViewController!,
                            as: .image,
                            testName: "Subscription view"
                        )
                        if let control: UIControl = newViewController.view.findElements({
                            $0.accessibilityIdentifier == AccessibilityIdentifier
                                .GroupSubscriptionSheet
                                .Button
                                .followCommunity
                                .id
                        }).first {
                            control.sendActions(for: .touchUpInside)
                        }
                    }
                case.failure(let error):
                    XCTFail("Ошибка создания подписки \(error)")
                }
            }
            self.wait(for: [subscriptionExpectation, accessTokenExpectation], timeout: 2)
        }
    }

    func testServiceAccountFailure() {
        Allure.report(
            .init(
                name: "Ошибка создания подписки на сообщество: сервисный аккаунт",
                meta: self.testCaseMeta
            )
        )
        self.applyTest(
            for: (
                GroupInfo(id: 1,
                          name: "Test Group",
                          groupAvatar: nil,
                          description: "Test Group Description",
                          isVerified: true,
                          isMember: false,
                          isClosed: false),
                [.init(avatarURL: nil)],
                friendsCount: 2,
                membersCount: 3,
                isServiceAccount: true,
                show: true
            )
        ) { error in
            XCTAssert(error == .isServiceAccount)
        }
    }

    func testIsMemberFailure() {
        Allure.report(
            .init(
                name: "Ошибка создания подписки на сообщество: участник сообщества",
                meta: self.testCaseMeta
            )
        )
        self.applyTest(
            for: (
                GroupInfo(id: 1,
                          name: "Test Group",
                          groupAvatar: nil,
                          description: "Test Group Description",
                          isVerified: true,
                          isMember: true,
                          isClosed: false),
                [.init(avatarURL: nil)],
                friendsCount: 2,
                membersCount: 3,
                isServiceAccount: true,
                show: true
            )
        ) { error in
            XCTAssert(error == .alreadyMember)
        }
    }

    func testScopeFailure() {
        Allure.report(
            .init(
                name: "Ошибка создания подписки на сообщество: отсутствие скоупа",
                meta: self.testCaseMeta
            )
        )
        self.applyTest(
            for: (
                GroupInfo(id: 1,
                          name: "Test Group",
                          groupAvatar: nil,
                          description: "Test Group Description",
                          isVerified: true,
                          isMember: nil,
                          isClosed: false),
                [.init(avatarURL: nil)],
                friendsCount: 2,
                membersCount: 3,
                isServiceAccount: true,
                show: true
            )
        ) { error in
            XCTAssert(error == .scopeMissing)
        }
    }

    func testInvalidAccessTokenFailure() {
        Allure.report(
            .init(
                name: "Ошибка создания подписки на сообщество: не валидный токен",
                meta: self.testCaseMeta
            )
        )
        self.applyTest(
            for: (
                GroupInfo(id: 1,
                          name: "Test Group",
                          groupAvatar: nil,
                          description: "Test Group Description",
                          isVerified: true,
                          isMember: false,
                          isClosed: false),
                [.init(avatarURL: nil)],
                friendsCount: 2,
                membersCount: 3,
                isServiceAccount: false,
                show: true
            ),
            invalidAccessToken: true
        ) { error in
            XCTAssert(error == .invalidAccessToken)
        }
    }

    func testGroupSubscriptionNotShow() {
        Allure.report(
            .init(
                name: "Ошибка создания подписки на сообщество: бекенд вернул флаг не показывать шторку",
                meta: self.testCaseMeta
            )
        )
        self.applyTest(
            for: (
                GroupInfo(id: 1,
                          name: "Test Group",
                          groupAvatar: nil,
                          description: "Test Group Description",
                          isVerified: true,
                          isMember: false,
                          isClosed: false),
                [.init(avatarURL: nil)],
                friendsCount: 2,
                membersCount: 3,
                isServiceAccount: false,
                show: false
            ),
            invalidAccessToken: false
        ) { error in
            XCTAssert(error == .subscriptionNotAllowed)
        }
    }

    func testSubscriptionAfterOneTap() {
        Allure.report(
            .init(
                name: "Показ подписки на сообщество после OneTap авторизации",
                meta: self.testCaseMeta
            )
        )
        let subscriptionExpectation = expectation(description: #function)
        let presenter = UIKitPresenter.uiWindow(self.window)
        let authConfig = AuthConfiguration(
            groupSubscriptionConfiguration: .init(subscribeToGroupId: "1") { result in
                switch result {
                case.success:
                    subscriptionExpectation.fulfill()
                case.failure:
                    XCTFail("Should not be failed")
                }
            }
        )
        let oneTapConfig = OneTapButton(
            authConfiguration: authConfig,
            oAuthProviderConfiguration: .init(),
            presenter: presenter,
            onCompleteAuth: nil
        )
        self.applyTest(for: authConfig) {
            let view = self.vkid.ui(for: oneTapConfig).uiView()
            self.viewController.view.addSubview(view)
            if let control: UIControl = view.findElements({
                $0.accessibilityIdentifier == AccessibilityIdentifier
                    .OneTapButton
                    .signIn
                    .id
            }).first {
                control.sendActions(for: .touchUpInside)
            }
        }
        self.wait(for: [subscriptionExpectation], timeout: 2)
    }

    func testSubscriptionAfterOneTapBottomSheet() {
        Allure.report(
            .init(
                name: "Показ подписки на сообщество после шторки авторизации",
                meta: self.testCaseMeta
            )
        )
        let subscriptionExpectation = expectation(description: #function)
        let groupSubscriptionConfiguration: GroupSubscriptionConfiguration = .init(subscribeToGroupId: "1") { result in
            switch result {
            case.success:
                subscriptionExpectation.fulfill()
            case.failure:
                XCTFail("Should not be failed")
            }
        }
        let authConfig = AuthConfiguration(
            groupSubscriptionConfiguration: groupSubscriptionConfiguration
        )
        let oneTapBottomSheet = OneTapBottomSheet(
            serviceName: "Test service",
            targetActionText: .applyFor,
            oneTapButton: .init(),
            authConfiguration: authConfig
        ) { _ in
        }
        self.applyTest(for: authConfig) {
            let bottomSheetViewController = self.vkid.ui(for: oneTapBottomSheet).uiViewController()
            self.viewController.present(bottomSheetViewController, animated: false) {
                if let control: UIControl = bottomSheetViewController.view.findElements({
                    $0.accessibilityIdentifier == AccessibilityIdentifier
                        .OneTapButton
                        .signIn
                        .id
                }).first {
                    control.sendActions(for: .touchUpInside)
                }
                self.window.makeKeyAndVisible()
            }
        }
        self.wait(for: [subscriptionExpectation], timeout: 2)
    }

    func testSubscriptionAfterWidget() {
        Allure.report(
            .init(
                name: "Показ подписки на сообщество после виджета авторизации",
                meta: self.testCaseMeta
            )
        )
        let subscriptionExpectation = expectation(description: #function)
        let groupSubscriptionConfiguration: GroupSubscriptionConfiguration = .init(subscribeToGroupId: "1") { result in
            switch result {
            case.success:
                subscriptionExpectation.fulfill()
            case.failure:
                XCTFail("Should not be failed")
            }
        }
        let presenter = UIKitPresenter.uiWindow(self.window)
        let authConfig = AuthConfiguration(
            groupSubscriptionConfiguration: groupSubscriptionConfiguration
        )
        let widget = OAuthListWidget(
            oAuthProviders: [.vkid],
            authConfiguration: authConfig,
            presenter: presenter
        ) { _ in
        }
        self.applyTest(for: authConfig) {
            let widgetView = self.vkid.ui(for: widget).uiView()
            self.viewController.view.addSubview(widgetView)
            if let control: UIControl = widgetView.findElements({
                $0.accessibilityIdentifier == AccessibilityIdentifier
                    .OneTapButton
                    .signIn
                    .id
            }).first {
                control.sendActions(for: .touchUpInside)
            }
        }
        self.wait(for: [subscriptionExpectation], timeout: 2)
    }

    func testSubscriptionAfterAuthorize() {
        Allure.report(
            .init(
                name: "Показ подписки на сообщество после вызова 'VKID.authorize'",
                meta: self.testCaseMeta
            )
        )
        let subscriptionExpectation = expectation(description: #function)
        let groupSubscriptionConfiguration: GroupSubscriptionConfiguration = .init(subscribeToGroupId: "1") { result in
            switch result {
            case.success:
                subscriptionExpectation.fulfill()
            case.failure:
                XCTFail("Should not be failed")
            }
        }
        let presenter = UIKitPresenter.uiWindow(self.window)
        let authConfig = AuthConfiguration(
            groupSubscriptionConfiguration: groupSubscriptionConfiguration
        )
        self.applyTest(for: authConfig) {
            self.vkid.authorize(with: authConfig, using: presenter) { _ in
            }
        }
        self.wait(for: [subscriptionExpectation], timeout: 2)
    }

    func testLimitSubscriptionShownCount() {
        Allure.report(
            .init(
                name: "Показ подписки на сообщество достиг лимита",
                meta: self.testCaseMeta
            )
        )
        self.groupSubscriptionStorage.saveSubscriptionInfo(.init(
            subscriptionShownHistory: [
                Date.addingOrSubtractingDaysFromNow(-1),
                Date.addingOrSubtractingDaysFromNow(-2),
            ],
            userId: self.defaultUserID
        ))
        let subscriptionFailureExpectation = expectation(description: #function)
        let groupSubscriptionConfiguration: GroupSubscriptionConfiguration = .init(subscribeToGroupId: "1") { result in
            switch result {
            case.success:
                XCTFail("Should not be shown")
            case.failure(.failedToCreate(.localLimitReached)):
                subscriptionFailureExpectation.fulfill()
            default:
                XCTFail("Should be limited")
            }
        }
        let authConfig = AuthConfiguration(
            groupSubscriptionConfiguration: groupSubscriptionConfiguration
        )
        self.applyTest(for: authConfig) {
            self.vkid.authorize(with: authConfig, using: .uiWindow(self.window)) { _ in
            }
        }
        self.wait(for: [subscriptionFailureExpectation], timeout: 2)
    }

    func testSubscriptionLimitPeriodRenewal() {
        Allure.report(
            .init(
                name: "Показ подписки на сообщество в новый период ограничения",
                meta: self.testCaseMeta
            )
        )
        self.groupSubscriptionStorage.saveSubscriptionInfo(.init(
            subscriptionShownHistory: [
                Date.addingOrSubtractingDaysFromNow(-31),
                Date.addingOrSubtractingDaysFromNow(-32),
            ],
            userId: self.defaultUserID
        ))
        let subscriptionExpectation = expectation(description: #function)
        let groupSubscriptionConfiguration: GroupSubscriptionConfiguration = .init(subscribeToGroupId: "1") { result in
            switch result {
            case.success:
                subscriptionExpectation.fulfill()
            default:
                XCTFail("Subscription should be shown")
            }
        }
        let authConfig = AuthConfiguration(
            groupSubscriptionConfiguration: groupSubscriptionConfiguration
        )
        self.applyTest(for: authConfig) {
            self.vkid.authorize(with: authConfig, using: .uiWindow(self.window)) { _ in
            }
        }
        self.wait(for: [subscriptionExpectation], timeout: 2)
    }

    func testSubscriptionLimitInitial() {
        Allure.report(
            .init(
                name: "Показ подписки на сообщество при инициализации приложения",
                meta: self.testCaseMeta
            )
        )
        UserDefaults.standard.groupSubscriptionInfo = []
        let subscriptionExpectation = expectation(description: #function)
        let groupSubscriptionConfiguration: GroupSubscriptionConfiguration = .init(subscribeToGroupId: "1") { result in
            switch result {
            case.success:
                let info = self.groupSubscriptionStorage.getSubscriptionInfo(forUserId: self.defaultUserID)
                XCTAssertEqual(info?.subscriptionShownHistory.count, 1)
                XCTAssertEqual(info?.userId.value, self.defaultUserID.value)
                subscriptionExpectation.fulfill()
            default:
                XCTFail("Subscription should be shown")
            }
        }
        let authConfig = AuthConfiguration(
            groupSubscriptionConfiguration: groupSubscriptionConfiguration
        )
        self.applyTest(for: authConfig) {
            self.vkid.authorize(with: authConfig, using: .uiWindow(self.window)) { _ in
            }
        }
        self.wait(for: [subscriptionExpectation], timeout: 2)
    }

    private func applyTest(for authConfig: AuthConfiguration, authorize: @escaping () -> Void) {
        given("Создание авторизации и подписки") {
            self.groupSubscriptionServiceMock.handler = { _, _ in
                .success((
                    self.defaultGroupInfo,
                    [.init(avatarURL: nil)],
                    friendsCount: 2,
                    membersCount: 3,
                    isServiceAccount: false,
                    show: true
                ))
            }
            self.groupSubscriptionServiceMock.subscribeToGroupHandler = { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let window = UIApplication.shared.windows
                        .first(where: { $0.isKeyWindow && $0.topmostViewController is BottomSheetViewController })
                    {
                        assertSnapshot(
                            of: window.topmostViewController!,
                            as: .image,
                            testName: "Snackbar"
                        )
                    } else {
                        XCTFail("Snackbar not found")
                    }
                }
                return .success(true)
            }
            self.vkid.rootContainer
                .authFlowBuilder = AuthFlowBuilderMock(serviceAuthFlowHandler: { authContext, authConfig, appearance in
                    let userId = UserID(value: 0)
                    let scope = Scope.random
                    return AuthFlowMock { presenter, completion in
                        // Snapshot testing workaround
                        presenter.presentingWindow?.makeKeyAndVisible()
                        completion(.success(.init(
                            accessToken: .init(
                                userId: userId,
                                value: "AccessToken",
                                expirationDate: Date() + 3600,
                                scope: scope
                            ),
                            refreshToken: .init(userId: userId, value: "RefreshToken", scope: scope),
                            idToken: .init(userId: userId, value: "IDToken"),
                            deviceId: "deviceId"
                        )))
                    }
                })
            when("Авторизация OneTap и подписка на сообщество") {
                authorize()
                // some flows awaiting for closing modal view controllers
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if let window = UIApplication.shared.windows.first(
                        where: { $0.topmostViewController is BottomSheetViewController }
                    ),
                        let control: UIControl = window.topmostViewController?.view.findElements({
                            $0.accessibilityIdentifier == AccessibilityIdentifier
                                .GroupSubscriptionSheet
                                .Button
                                .followCommunity
                                .id
                        }).first
                    {
                        // Snapshot testing workaround
                        window.makeKeyAndVisible()
                        control.sendActions(for: .touchUpInside)
                    } else {
                        XCTFail("Subscription not found")
                    }
                }
            }
        }
    }

    private func applyTest(
        for info: (
            GroupInfo,
            [GroupMemberInfo],
            friendsCount: Int,
            membersCount: Int,
            isServiceAccount: Bool,
            show: Bool
        ),
        invalidAccessToken: Bool = false,
        completion: @escaping (GroupSubscriptionSheetCreationError) -> Void
    ) {
        let subscriptionExpectation = expectation(description: "Bottom sheet creation error")
        let accessTokenExpectation = expectation(description: "access token provided")
        var providedToken = false

        given("Создание конфигурации шторки") {
            let presenter = UIKitPresenter.uiWindow(self.window)
            self.groupSubscriptionSheet = GroupSubscriptionSheet(
                subscribeToGroupId: "1",
                presenter: presenter,
                onCompleteSubscription: { result in
                    XCTFail("Вызов комлишена")
                },
                accessTokenProvider: { needToRefresh, completion in
                    if !providedToken {
                        accessTokenExpectation.fulfill()
                        providedToken = true
                    }
                    if invalidAccessToken {
                        completion(.failure(NSError.random))
                    } else {
                        completion(.success("accessToken"))
                    }
                }
            )
            self.groupSubscriptionServiceMock.handler = { _, _ in
                .success(info)
            }
        }
        when("Показ шторки") {
            self.groupSubscriptionSheet.show(
                on: self.viewController,
                vkid: self.vkid
            ) { result in
                switch result {
                case.success:
                    XCTFail("Ошибочное создание UIViewController")
                case.failure(let error):
                    completion(error)
                    subscriptionExpectation.fulfill()
                }
            }
            self.wait(for: [subscriptionExpectation, accessTokenExpectation], timeout: 2)
        }
    }
}

extension GroupSubscriptionSheet {
    internal func show(
        on viewController: UIViewController,
        vkid: VKID,
        autoDismiss: Bool = false,
        completion: @escaping (Result<UIViewController, GroupSubscriptionSheetCreationError>) -> Void
    ) {
        vkid.ui(
            for: self
        ).uiViewController { result in
            switch result {
            case.success(let bottomSheetViewController):
                viewController.present(bottomSheetViewController, animated: false) {
                    completion(.success(bottomSheetViewController))
                    if autoDismiss {
                        bottomSheetViewController.dismiss(animated: false)
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
