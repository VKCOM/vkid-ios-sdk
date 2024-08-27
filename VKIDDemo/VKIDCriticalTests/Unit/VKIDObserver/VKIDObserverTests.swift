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

import Foundation
import VKIDAllureReport
import VKIDTestingInfra
import XCTest

@_spi(VKIDDebug)
@testable import VKID
@testable import VKIDCore

final class VKIDObserverTests: XCTestCase, TestCaseInfra {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "Отслеживание состояния авторизации - VKIDObserver",
        priority: .critical
    )
    private let context = AuthContext(launchedBy: .service)
    private var webViewAuthStrategyMock: WebViewAuthStrategyMock!
    private var observerMock: VKIDObserverMock!
    private var urlSessionTransportMock: URLSessionTransportMock!
    private var secrets:PKCESecrets!
    private var session: UserSession!
    private var userSessionData: UserSessionData!
    var vkid: VKID!

    override func setUpWithError() throws {
        self.secrets = try! PKCESecrets()
        self.webViewAuthStrategyMock = WebViewAuthStrategyMock()
        let rootContainer = RootContainer(
            appCredentials: Entity.appCredentials,
            networkConfiguration: .init(isSSLPinningEnabled: false),
            webViewStrategyFactory: WebViewAuthStrategyFactoryMock(
                webViewAuthStrategyMock: self.webViewAuthStrategyMock
            )
        )
        self.urlSessionTransportMock = URLSessionTransportMock()
        self.vkid = self.createVKID(
            rootContainer: rootContainer,
            mainTransport: self.urlSessionTransportMock
        )
        self.observerMock = VKIDObserverMock()
        self.vkid.add(observer: self.observerMock)
    }

    override func tearDownWithError() throws {
        self.secrets = nil
        self.vkid = nil
        self.webViewAuthStrategyMock = nil
        self.observerMock = nil
        self.urlSessionTransportMock = nil
        self.session = nil
        self.userSessionData = nil
    }

    func testAuthStartWithProvider() {
        Allure.report(
            .init(
                id: 2315480,
                name: "Начало авторизации через указанный OAuthProvider",
                meta: self.testCaseMeta
            )
        )
        let expectation = expectation(description: #function)
        let oAuthProvider = OAuthProvider.ok
        let oAuthProviderConfig = OAuthProviderConfiguration(primaryProvider: oAuthProvider)
        var authConfig: AuthConfiguration!
        given("Задаем конфигурацию, подписываемся на старт авторизации") {
            authConfig = AuthConfiguration(flow: .publicClientFlow(pkce: self.secrets))
            self.observerMock.didStartAuthUsing = { _, provider in
                then("Проверяем, что указан правильный провайдер") {
                    XCTAssertEqual(provider, oAuthProvider)
                    expectation.fulfill()
                }
            }
        }
        when("Запускаем авторизацию") {
            self.vkid.authorize(
                authContext: self.context,
                authConfig: authConfig,
                oAuthProviderConfig: oAuthProviderConfig,
                presenter: .newUIWindow
            ) { _ in
                // no need to handle in the test
            }
            self.wait(for: [expectation], timeout: 1)
        }
    }

    func testAuthFinishWithProvider() {
        Allure.report(
            .init(
                id: 2315481,
                name: "Завершение авторизации через указанный OAuthProvider",
                meta: self.testCaseMeta
            )
        )
        let correctObserverResultExpectation = expectation(
            description: "Верный провайдер при завершении авторизации"
        )
        let successfulAuthorizationExpectation = expectation(
            description: "Успешная авторизация"
        )
        let oAuthProviderConfig = OAuthProviderConfiguration(primaryProvider: .ok)
        let userSessionData = UserSessionData.random()
        let codeExchangerMock = AuthCodeExchangerMock()
        let webViewResponse = AuthCodeResponse.random(
            state: self.secrets.state,
            serverProvidedDeviceId: userSessionData.serverProvidedDeviceId
        )
        let authConfig = AuthConfiguration(
            flow:.confidentialClientFlow(
                codeExchanger: codeExchangerMock,
                pkce: self.secrets
            )
        )
        given("Подписка на завершение авторизации, имитация авторизации") {
            self.observerMock.didCompleteAuthWith = { _, authResult, provider in
                then("Проверяем, что указан правильный провайдер и сессия") {
                    XCTAssertEqual(provider, oAuthProviderConfig.primaryProvider)
                    if case .success(let session) = authResult {
                        XCTAssertEqual(userSessionData.id, session.userId)
                        XCTAssertEqual(userSessionData.accessToken.value, session.accessToken.value)
                        XCTAssertEqual(userSessionData.refreshToken, session.refreshToken)
                        XCTAssertEqual(userSessionData.serverProvidedDeviceId, session.sessionId)
                        XCTAssertEqual(userSessionData.idToken, session.idToken)
                        correctObserverResultExpectation.fulfill()
                    }
                }
            }
            self.mockAuthorization(
                authCodeExchangerMock: codeExchangerMock,
                authCodeResponse: webViewResponse,
                userSessionData: userSessionData
            )
        }
        when("Запускаем авторизацию, проверка успешной авторизации") {
            self.vkid.authorize(
                authContext: self.context,
                authConfig: authConfig,
                oAuthProviderConfig: oAuthProviderConfig,
                presenter: .newUIWindow
            ) { result in
                guard
                    case .success(let session) = result,
                    session.oAuthProvider == oAuthProviderConfig.primaryProvider
                else {
                    XCTFail("Authorization failed")
                    return
                }
                successfulAuthorizationExpectation.fulfill()
            }
            self.wait(
                for: [
                    successfulAuthorizationExpectation,
                    correctObserverResultExpectation,
                ],
                timeout: 1
            )
        }
    }

    func testSessionLogout() {
        Allure.report(
            .init(
                id: 2315482,
                name: "Логаут из указанной сессии",
                meta: self.testCaseMeta
            )
        )

        let logoutExpectation = expectation(description: "Успешный логаут")
        let logoutObservingExpectation = expectation(description: "Наблюдение успешного логаута")

        given("Создание сессии, подписка на логаут, имитация успешного логаута") {
            (self.session, self.userSessionData) = self.createUserSession()
            self.observerMock.didLogoutFrom = { _, logoutSession, result in
                then("Проверяем, что указан правильный провайдер") {
                    guard
                        case .success = result,
                        logoutSession.userId == self.userSessionData.id
                    else {
                        XCTFail("Wrong logout result")
                        return
                    }
                    logoutObservingExpectation.fulfill()
                }
            }
            self.urlSessionTransportMock.responseProvider = { responseType, request in
                if responseType is OAuth2.Logout.Response.Type {
                    return .success(OAuth2.Logout.Response.init(response: 1))
                }
                return .failure(.unknown)
            }
        }
        when("Логаут") {
            self.session.logout { result in
                then("Проверка успешного логаута") {
                    do {
                        guard case .success = result else {
                            XCTFail("Failed logout result")
                            return
                        }
                        logoutExpectation.fulfill()
                    }
                }
            }
            self.wait(
                for: [
                    logoutExpectation,
                    logoutObservingExpectation,
                ],
                timeout: 1
            )
        }
    }

    func testRefreshAccessToken() {
        Allure.report(
            .init(
                id: 2315483,
                name: "Обновление AT в указанной сессии",
                meta: self.testCaseMeta
            )
        )
        let refreshExpectation = expectation(description: "Успешный рефреш токенов")
        let refreshObservingExpectation = expectation(description: "Наблюдение рефреша токенов")
        var updatedSessionData: UserSessionData!

        given("Создание сессии, подписка на рефреш, имитация успешного рефреша") {
            (self.session, self.userSessionData) = self.createUserSession()
            updatedSessionData = UserSessionData.random(
                userId: self.userSessionData.id.value
            )
            self.observerMock.didRefreshAccessTokenIn = { _, refreshedSession, result in
                then("Проверяем, что токены обновлены") {
                    guard
                        case .success((let accessToken, let refreshToken)) = result,
                        refreshedSession.userId == self.userSessionData.id,
                        updatedSessionData.accessToken.value == accessToken.value,
                        updatedSessionData.refreshToken == refreshToken
                    else {
                        XCTFail("Ошибка обновления токенов")
                        return
                    }
                    refreshObservingExpectation.fulfill()
                }
            }
            self.simulateRefresh(updatedSessionData: updatedSessionData)
        }
        when("Обновление AT") {
            self.session.getFreshAccessToken(forceRefresh: true) { result in
                then("Проверяем, что AT в хранилище соответствуем свежему токену сессии") {
                    guard
                        case .success((let accessToken, let refreshToken)) = result,
                        updatedSessionData.accessToken.value == accessToken.value,
                        updatedSessionData.refreshToken == refreshToken
                    else {
                        XCTFail("Storage has wrong AT")
                        return
                    }
                    refreshExpectation.fulfill()
                }
            }
            self.wait(for: [refreshExpectation, refreshObservingExpectation], timeout: 1)
        }
    }

    func testUserFetching() {
        Allure.report(
            .init(
                id: 2315483,
                name: "Обновление данных юзера в указанной сессии",
                meta: self.testCaseMeta
            )
        )
        var updatedUser: User!
        let userFetchingExpectation = expectation(
            description: "Успешное обновление данных пользователя"
        )
        let userFetchingObservingExpectation = expectation(
            description: "Наблюдение за успешным обновлением данных пользователя"
        )

        given("Создание сессии, подписка обновление юзера, обнолвение пользовательских данных") {
            (self.session, self.userSessionData) = self.createUserSession(
                userSessionData: .random(withUserData: false)
            )
            updatedUser = UserSessionData.random(userId: self.userSessionData.id.value).user
            self.observerMock.didUpdateUserIn = { _, fetchUserSession, result in
                XCTAssertEqual(fetchUserSession.user, updatedUser)
                userFetchingObservingExpectation.fulfill()
            }
            self.simulateUserFetching(user: updatedUser)
        }
        when("Получение пользовательских данных") {
            self.session.fetchUser { result in
                then("Проверка полученных данных") {
                    guard
                        case .success(let user) = result
                    else {
                        XCTFail("User data was not obtained")
                        return
                    }
                    XCTAssertEqual(user, updatedUser)
                    userFetchingExpectation.fulfill()
                }
            }
            self.wait(
                for: [
                    userFetchingExpectation,
                    userFetchingObservingExpectation,
                ],
                timeout: 1
            )
        }
    }

    private func simulateUserFetching(user: User) {
        self.urlSessionTransportMock.responseProvider = { responseType, request in
            if responseType.isUserInfoResponse,
               request.path == "/oauth2/user_info"
            {
                return .success(OAuth2.UserInfo.Response.init(
                    user: .init(
                        firstName: user.firstName,
                        lastName: user.lastName,
                        phone: user.phone,
                        avatar: user.avatarURL?.absoluteString,
                        email: user.email
                    )
                ))
            }
            return .failure(.unknown)
        }
    }

    private func simulateRefresh(updatedSessionData: UserSessionData) {
        self.urlSessionTransportMock.responseProvider = { responseType, request in
            if responseType.isRefreshTokenResponse {
                return .success(OAuth2.RefreshToken.Response.create(
                    userSessionData: updatedSessionData,
                    state: request.parameters["state"] as? String ?? "unknown"
                ))
            }
            return .failure(.unknown)
        }
    }

    private func mockAuthorization(
        authCodeExchangerMock: AuthCodeExchangerMock,
        authCodeResponse: AuthCodeResponse,
        userSessionData: UserSessionData
    ) {
        authCodeExchangerMock.handler = { code, completion in
            guard code.state == authCodeResponse.state else {
                XCTFail("Wrong state")
                return
            }
            let authFlowData = AuthFlowData(
                accessToken: userSessionData.accessToken,
                refreshToken: userSessionData.refreshToken,
                idToken: userSessionData.idToken,
                deviceId: code.deviceId
            )
            completion(.success(authFlowData))
        }
        self.webViewAuthStrategyMock.handler = { _, _, _, completion in
            completion(.success(authCodeResponse))
        }
    }
}
