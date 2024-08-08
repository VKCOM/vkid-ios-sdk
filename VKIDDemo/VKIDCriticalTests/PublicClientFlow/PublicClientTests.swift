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

final class PublicClientFlowTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "Авторизация public client flow",
        priority: .critical
    )

    private var vkid: VKID!
    private var webViewAuthStrategyMock: WebViewAuthStrategyMock!
    private var authFlowBuilderMock: AuthFlowBuilderMock!
    private var mainTransportMock: URLSessionTransportMock!
    private var pkceSecrets: PKCESecrets!
    private var rootContainer: RootContainer!

    override func setUpWithError() throws {
        self.webViewAuthStrategyMock = WebViewAuthStrategyMock()
        self.pkceSecrets = PKCESecrets(
            codeVerifier: "codeVerifier_\(UUID().uuidString)",
            codeChallenge: "codeChallenge_\(UUID().uuidString)",
            codeChallengeMethod: .s256,
            state: UUID().uuidString
        )
        self.rootContainer = RootContainer(
            appCredentials: Entity.appCredentials,
            networkConfiguration: .init(isSSLPinningEnabled: false),
            webViewStrategyFactory: WebViewAuthStrategyFactoryMock(
                webViewAuthStrategyMock: self.webViewAuthStrategyMock
            )
        )
        self.mainTransportMock = URLSessionTransportMock()
        self.mainTransportMock.responseProvider = { _, request in
            .failure(.unknown)
        }
        let anonymousTokenTransport = URLSessionTransportMock()
        anonymousTokenTransport.responseProvider = { _, request in
            .failure(.unknown)
        }
        self.rootContainer.mainTransport = self.mainTransportMock
        self.rootContainer.anonymousTokenTransport = anonymousTokenTransport

        self.authFlowBuilderMock = AuthFlowBuilderMock()

        self.vkid = try? VKID(
            config: .init(appCredentials: Entity.appCredentials),
            rootContainer: self.rootContainer
        )
    }

    override func tearDownWithError() throws {
        self.webViewAuthStrategyMock = nil
        self.authFlowBuilderMock = nil
        self.vkid = nil
    }

    func testProvidedPKCE() {
        Allure.report(
            .init(
                id: 2315432,
                name: "Авторизация public client flow (PKCE сервиса)",
                meta: self.testCaseMeta
            )
        )
        let expectation = expectation(description: #function)
        var authConfig: AuthConfiguration!

        given("Задаем PKCE сервиса") {
            self.rootContainer.authFlowBuilder = self.authFlowBuilderMock
            authConfig = .init(flow: .publicClientFlow(pkce: self.pkceSecrets))
            self.authFlowBuilderMock.serviceAuthFlowHandler = { (
                authContext: AuthContext,
                authConfig: ExtendedAuthConfiguration,
                appearance: Appearance
            ) -> AuthFlow in
                try? then("Проверяем, что во флоу авторизации передан правильный PKCE") {
                    let secrets = authConfig.pkceSecrets
                    guard
                        try secrets == self.pkceSecrets
                    else {
                        XCTFail("Failed PKCE secrets")
                        return
                    }
                    expectation.fulfill()
                }
                return AuthFlowMock()
            }
        }
        when("Запускаем авторизацию") {
            self.vkid.authorize(
                authContext: .init(launchedBy: .service),
                authConfig: authConfig,
                oAuthProviderConfig: .init(primaryProvider: .vkid),
                presenter: .newUIWindow
            ) { _ in
                // no need to handle in the test
            }
            self.wait(for: [expectation], timeout: 1)
        }
    }

    func testGeneratedPKCE() {
        Allure.report(
            .init(
                id: 2315435,
                name: "Авторизация public client flow (PKCE свой)",
                meta: self.testCaseMeta
            )
        )

        let expectation = expectation(description: #function)

        var authConfig: AuthConfiguration!
        self.vkid.rootContainer.pkceSecretsGenerator = PKCESecretsGeneratorMock {
            self.pkceSecrets
        }

        self.authFlowBuilderMock.serviceAuthFlowHandler = { (
            authContext: AuthContext,
            authConfig: ExtendedAuthConfiguration,
            appearance: Appearance
        ) -> AuthFlow in
            try? then("Проверяем, что во флоу авторизации сгенерериван PKCE") {
                guard
                    try authConfig.pkceSecrets == self.pkceSecrets
                else {
                    XCTFail("Failed PKCE secrets")
                    return
                }
                expectation.fulfill()
            }
            return AuthFlowMock()
        }
        given("Задаем PKCE") {
            self.rootContainer.authFlowBuilder = self.authFlowBuilderMock
            authConfig = .init(flow: .publicClientFlow(pkce: self.pkceSecrets))
        }
        when("Запускаем авторизацию") {
            self.vkid.authorize(
                authContext: .init(launchedBy: .service),
                authConfig: authConfig,
                oAuthProviderConfig: .init(primaryProvider: .vkid),
                presenter: .newUIWindow
            ) { _ in
                // no need to handle in the test
            }
            self.wait(for: [expectation], timeout: 1)
        }
    }

    func testPublicClientCodeExchanger() {
        Allure.report(
            .init(
                id: 2315437,
                name: "Для обмена auth code на AT используем свой exchanger из SDK (сами дергаем /oauth2/auth)",
                meta: self.testCaseMeta
            )
        )
        let expectation = expectation(description: #function)
        var authConfig: AuthConfiguration!
        given("Задаем PKCE, обработку запросов в вебвью и на транспортном уровне") {
            let webViewResponse = AuthCodeResponse.random(state: self.pkceSecrets.state)
            authConfig = .init(flow: .publicClientFlow(pkce: self.pkceSecrets))
            self.mainTransportMock.responseProvider = { _, request -> Result<
                VKIDCore.VKAPIResponse,
                VKIDCore.VKAPIError
            > in
                guard
                    request.path == "/oauth2/auth",
                    request.parameters["code"] as? String == webViewResponse.code
                else {
                    return .failure(.unknown)
                }
                expectation.fulfill()
                return .failure(.unknown)
            }
            self.webViewAuthStrategyMock.handler = { _, _, _, completion in
                completion(.success(webViewResponse))
            }
        }
        when("Запускаем авторизацию") {
            self.vkid.authorize(
                authContext: .init(launchedBy: .service),
                authConfig: authConfig,
                oAuthProviderConfig: .init(primaryProvider: .vkid),
                presenter: .newUIWindow
            ) { _ in
                // no need to handle in the test
            }
            self.wait(for: [expectation], timeout: 1)
        }
    }
}
