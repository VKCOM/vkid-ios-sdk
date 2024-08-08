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
import XCTest
@_spi(VKIDDebug) @testable import VKID
@testable import VKIDAllureReport
@testable import VKIDCore

final class AutoLogoutTests: XCTestCase, TestCaseInfra {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "Взаимодействие с авторизованной сессией пользователя (UserSession)",
        priority: .critical
    )
    var vkid: VKID!
    private var webViewAuthStrategyMock: WebViewAuthStrategyMock!
    private var urlSessionDataTaskMock: URLSessionDataTaskMock!

    override func setUpWithError() throws {
        self.webViewAuthStrategyMock = WebViewAuthStrategyMock()
        self.urlSessionDataTaskMock = URLSessionDataTaskMock()
        let urlSessionMock = URLSessionMock(
            urlSessionDataTaskMock: self.urlSessionDataTaskMock
        )
        let requestAuthorizationInterceptor = RequestAuthorizationInterceptor(
            deps:
            .init(anonymousTokenService: AnonymousTokenServiceMock())
        )
        self.vkid = self.createVKID(
            webViewAuthStrategyFactory: WebViewAuthStrategyFactoryMock(
                webViewAuthStrategyMock: self.webViewAuthStrategyMock
            ) ,
            requestInterceptors: [requestAuthorizationInterceptor],
            urlSessionMock: urlSessionMock
        )
        requestAuthorizationInterceptor.userSessionManager = self.vkid.rootContainer.userSessionManager
    }

    override func tearDownWithError() throws {
        self.webViewAuthStrategyMock = nil
        self.vkid = nil
        self.urlSessionDataTaskMock = nil
    }

    func testAutoLogoutOnSessionOverride() {
        Allure.report(
            .init(
                id: 2315464,
                name: "Автоматический логаут из предыдущей сессии, если пользователь залогинился в тот же аккаунт (костыль для предотвращения session pool overflow)",
                meta: self.testCaseMeta
            )
        )
        let autoLogoutExpectation = expectation(description: "Успешный автологаут")
        let authorizationExpectation = expectation(description: "Успешная авторизация")
        let secrets = try! PKCESecrets()
        let codeExchangerMock = AuthCodeExchangerMock()
        let authConfig = AuthConfiguration(
            flow: .confidentialClientFlow(
                codeExchanger: codeExchangerMock,
                pkce: secrets
            )
        )
        var updatedSessionData: UserSessionData!

        given("Создание сессии и данных для обновления сессии") {
            let (session, userSessionData) = self.createUserSession()
            updatedSessionData = UserSessionData.random(
                userId: session.userId.value
            )
            self.mockSuccessAuthViaWebViewResponse(
                codeExchangerMock: codeExchangerMock,
                updatedSessionData: updatedSessionData,
                state: secrets.state
            )
            self.mockSuccessLogoutResponse(
                for: userSessionData.accessToken.value,
                autoLogoutExpectation: autoLogoutExpectation
            )
        }
        when("Запускаем авторизацию") {
            self.vkid.authorize(with: authConfig, using: .newUIWindow) { result in
                then("Проверка успешной авторизации") {
                    guard
                        case .success(let session) = result,
                        session.userId == updatedSessionData.id,
                        session.accessToken.value == updatedSessionData.accessToken.value
                    else {
                        XCTFail("Authorization failed")
                        return
                    }
                    authorizationExpectation.fulfill()
                }
            }
            self.wait(for: [autoLogoutExpectation, authorizationExpectation], timeout: 10)
        }
    }

    private func mockSuccessAuthViaWebViewResponse(
        codeExchangerMock: AuthCodeExchangerMock,
        updatedSessionData: UserSessionData,
        state: String
    ) {
        let webViewResponse = AuthCodeResponse.random(state: state)
        codeExchangerMock.handler = { code, completion in
            guard code.state == webViewResponse.state else {
                XCTFail("Wrong state")
                return
            }
            let authFlowData = AuthFlowData(
                accessToken: updatedSessionData.accessToken,
                refreshToken: updatedSessionData.refreshToken,
                idToken: updatedSessionData.idToken,
                deviceId: code.deviceId
            )
            completion(.success(authFlowData))
        }
        self.webViewAuthStrategyMock.handler = { _, _, _, completion in
            completion(.success(webViewResponse))
        }
    }

    private func mockSuccessLogoutResponse(
        for accessToken: String,
        autoLogoutExpectation: XCTestExpectation
    ) {
        self.urlSessionDataTaskMock.responseProvider = { request in
            return switch request?.url?.path {
            case "/oauth2/logout": { request in
                    if "Bearer \(accessToken)" ==
                        request?.allHTTPHeaderFields?["Authorization"]
                    {
                        autoLogoutExpectation.fulfill()
                        let response = OAuth2.Logout.Response.init(response: 1)
                        return try! JSONEncoder().encode(response)
                    }
                    return nil
                }(request)
            default: nil
            }
        }
    }
}
