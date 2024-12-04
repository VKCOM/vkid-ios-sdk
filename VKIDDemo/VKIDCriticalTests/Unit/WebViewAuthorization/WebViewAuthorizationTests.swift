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

import VKIDAllureReport
import XCTest
@testable import VKIDTestingInfra

@_spi(VKIDDebug)
@testable import VKID
@testable import VKIDCore

final class WebViewAuthorizationTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "Авторизация в WebView",
        priority: .critical
    )
    private let context = AuthContext(launchedBy: .service)
    private let appearance = Appearance(colorScheme: .dark, locale: .ru)
    private let secrets = PKCESecrets(codeChallenge: "testCodeChallenge", state: "testState")
    private var vkid: VKID!
    private var webViewAuthStrategyMock: WebViewAuthStrategyMock!
    private var isTopMostViewControllerSafariController = true

    override func setUpWithError() throws {
        self.webViewAuthStrategyMock = WebViewAuthStrategyMock()
        let rootContainer = RootContainer(
            appCredentials: Entity.appCredentials,
            networkConfiguration: .init(isSSLPinningEnabled: false),
            webViewStrategyFactory: WebViewAuthStrategyFactoryMock(
                webViewAuthStrategyMock: self.webViewAuthStrategyMock
            )
        )
        let mainTransport = URLSessionTransportMock()
        let anonymousTokenTransport = URLSessionTransportMock()
        rootContainer.mainTransport = mainTransport
        rootContainer.anonymousTokenTransport = anonymousTokenTransport

        self.vkid = try? VKID(
            config: .init(
                appCredentials: Entity.appCredentials,
                appearance: self.appearance
            ),
            rootContainer: rootContainer
        )
    }

    override func tearDownWithError() throws {
        self.webViewAuthStrategyMock = nil
        self.vkid = nil
    }

    func testWebViewOpensProperURL() throws {
        Allure.report(
            .init(
                id: 2315444,
                name: "Формирование и открытие корректного URL /authorize в WebView, использование scope , переданного в `AuthConfiguration`",
                meta: self.testCaseMeta
            )
        )
        let expectation = expectation(description: #function)
        var authConfig: AuthConfiguration!
        try given("Задаем конфигурацию и ожидаемый URL") {
            authConfig = AuthConfiguration(flow: .publicClientFlow(pkce: self.secrets))
            guard let expectedURL = try self.createExpectedURL() else {
                XCTFail("Failed creation of expected URL")
                return
            }
            self.webViewAuthStrategyMock.handler = { url, _, _, _ in
                then("Проверка url") {
                    XCTAssertEqual(expectedURL, url)
                    expectation.fulfill()
                }
            }
        }
        when("Запускаем авторизацию") {
            self.vkid.authorize(
                authContext: self.context,
                authConfig: authConfig,
                oAuthProviderConfig: .init(primaryProvider: .vkid),
                presenter: .newUIWindow
            ) { _ in
                // no need to handle in the test
            }
        }
        self.wait(for: [expectation], timeout: 1)
    }

    func testWebViewOpensProperURLWithScope() throws {
        Allure.report(
            .init(
                id: 2315445,
                name: "Использование scope, переданного в `AuthConfiguration`",
                meta: self.testCaseMeta
            )
        )
        let expectation = expectation(description: #function)
        var authConfig: AuthConfiguration!
        try given("Задаем конфигурацию c доступами и ожидаемый URL") {
            let scope: Scope = ["phone, email"]
            authConfig = AuthConfiguration(flow: .publicClientFlow(pkce: self.secrets), scope: scope)
            guard let expectedURL = try self.createExpectedURL(scope: scope) else {
                XCTFail("Failed creation of expected URL")
                return
            }
            self.webViewAuthStrategyMock.handler = { url, _, _, completion in
                then("Проверка url на наличие доступов в параметрах") {
                    XCTAssertEqual(expectedURL, url)
                    expectation.fulfill()
                }
            }
        }
        when("Запускаем авторизацию") {
            self.vkid.authorize(
                authContext: self.context,
                authConfig: authConfig,
                oAuthProviderConfig: .init(primaryProvider: .vkid),
                presenter: .newUIWindow
            ) { result in
                // no need to handle in the test
            }
        }
        self.wait(for: [expectation], timeout: 1)
    }

    func testCorrectErrorHandlingInWebView() {
        Allure.report(
            .init(
                id: 2315450,
                name: "Обработка ошибки авторизации в WebView",
                meta: self.testCaseMeta
            )
        )
        let expectation = expectation(description: #function)
        given("Задаем ошибку в вебвью") {
            self.webViewAuthStrategyMock.handler = { _, _, _, completion in
                let error = NSError(domain: "", code: 0)
                completion(.failure(.webViewAuthFailed(error)))
            }
        }
        when("Запускаем авторизацию") {
            self.vkid.authorize(using: .newUIWindow) { result in
                then("Проверка ошибки авторизации") {
                    guard case .failure(AuthError.unknown) = result else {
                        XCTFail("Authorization failed case error")
                        return
                    }
                    expectation.fulfill()
                }
            }
        }
        self.wait(for: [expectation], timeout: 1)
    }

    func testAuthResultWaitingForHidingViewController() {
        Allure.report(
            .init(
                name: "Результат авторизации получен после скрытия вью контроллера",
                meta: self.testCaseMeta
            )
        )
        let expectation = expectation(description: #function)
        let webViewResponse = AuthCodeResponse.random(state: self.secrets.state)
        let userId = UserID(value: 135)
        let scope = Scope("vkid.personal_info")
        let accessToken = AccessToken(
            userId: userId,
            value: UUID().uuidString,
            expirationDate: .defaultExpirationDate,
            scope: scope
        )
        let refreshToken = RefreshToken(
            userId: userId,
            value: UUID().uuidString,
            scope: scope
        )
        let idToken = IDToken(userId: userId, value: UUID().uuidString)
        let codeExchangerMock = AuthCodeExchangerMock()
        codeExchangerMock.handler = { code, completion in
            guard code.state == webViewResponse.state else {
                XCTFail("Wrong state")
                return
            }
            let authFlowData = AuthFlowData(
                accessToken: accessToken,
                refreshToken: refreshToken,
                idToken: idToken,
                deviceId: code.deviceId
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isTopMostViewControllerSafariController = false
            }
            completion(.success(authFlowData))
        }
        let authConfig = AuthConfiguration(
            flow:.confidentialClientFlow(codeExchanger: codeExchangerMock, pkce: self.secrets)
        )
        given("Задаем ответ в вебвью и мок проверки вью контроллера") {
            self.webViewAuthStrategyMock.handler = { _, _, _, completion in
                completion(.success(webViewResponse))
            }
            let applicationManagerMock = ApplicationManagerMock()
            applicationManagerMock.handler = {
                self.isTopMostViewControllerSafariController
            }
            self.vkid.rootContainer.applicationManager = applicationManagerMock
        }
        when("Запускаем авторизацию") {
            self.vkid.authorize(with: authConfig, using: .newUIWindow) { result in
                then("Проверка вью контроллера при зваершении авторизации") {
                    if self.isTopMostViewControllerSafariController {
                        XCTFail("Wrong top most view controller logic")
                    }
                    expectation.fulfill()
                }
            }
            self.wait(for: [expectation], timeout: 1)
        }
    }

    func testSuccessfulAuthCodeExchangeInWebView() {
        Allure.report(
            .init(
                id: 2315456,
                name: "Обработка успешного получения auth code и обмен кода через exchanger для получения токена",
                meta: self.testCaseMeta
            )
        )
        let expectation = expectation(description: #function)
        let webViewResponse = AuthCodeResponse.random(state: self.secrets.state)
        let userId = UserID(value: 135)
        let scope = Scope("vkid.personal_info")
        let accessToken = AccessToken(
            userId: userId,
            value: UUID().uuidString,
            expirationDate: .defaultExpirationDate,
            scope: scope
        )
        let refreshToken = RefreshToken(
            userId: userId,
            value: UUID().uuidString,
            scope: scope
        )
        let idToken = IDToken(userId: userId, value: UUID().uuidString)
        let codeExchangerMock = AuthCodeExchangerMock()
        codeExchangerMock.handler = { code, completion in
            guard code.state == webViewResponse.state else {
                XCTFail("Wrong state")
                return
            }
            let authFlowData = AuthFlowData(
                accessToken: accessToken,
                refreshToken: refreshToken,
                idToken: idToken,
                deviceId: code.deviceId
            )
            completion(.success(authFlowData))
        }
        let authConfig = AuthConfiguration(
            flow:.confidentialClientFlow(codeExchanger: codeExchangerMock, pkce: self.secrets)
        )
        given("Задаем успешный ответ в вебвью") {
            self.webViewAuthStrategyMock.handler = { _, _, _, completion in
                completion(.success(webViewResponse))
            }
        }
        when("Запускаем авторизацию") {
            self.vkid.authorize(with: authConfig, using: .newUIWindow) { result in
                then("Проверка успешной авторизации") {
                    guard
                        case .success(let session) = result,
                        session.userId == userId,
                        session.accessToken == accessToken,
                        session.refreshToken == refreshToken,
                        session.idToken == idToken,
                        session.sessionId == webViewResponse.serverProvidedDeviceId
                    else {
                        XCTFail("Authorization success case error")
                        return
                    }
                    expectation.fulfill()
                }
            }
            self.wait(for: [expectation], timeout: 1)
        }
    }

    private func createExpectedURL(scope: Scope? = nil) throws -> URL? {
        try XCTUnwrap(
            .webViewAuthorize(
                authContext: self.context,
                secrets: self.secrets,
                credentials: Entity.appCredentials,
                appearance: self.appearance,
                scope: scope
            )
        )
    }
}
