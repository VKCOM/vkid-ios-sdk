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
import VKIDTestingInfra
import XCTest

@_spi(VKIDDebug)
@testable import VKID
@testable import VKIDCore

final class ProviderAuthorizationTests: XCTestCase, TestCaseInfra {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "Авторизация через провайдер",
        priority: .critical
    )

    private let authContext: AuthContext = .init(launchedBy: .service)
    private let oAuthProviderConfig: OAuthProviderConfiguration = .init(primaryProvider: .vkid)

    private var pkceSecrets: PKCESecrets!
    private var authConfig: AuthConfiguration!

    private var appInteropOpenerMock: AppInteropOpenerMock!
    private var mainTransportMock: URLSessionTransportMock!
    private var anonymousTokenTransportMock: URLSessionTransportMock!
    private var webViewAuthStrategyMock: WebViewAuthStrategyMock!

    internal var vkid: VKID!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.pkceSecrets = .random
        self.authConfig = .init(
            flow: .publicClientFlow(
                pkce: self.pkceSecrets
            )
        )

        self.appInteropOpenerMock = AppInteropOpenerMock()
        self.mainTransportMock = URLSessionTransportMock()
        self.anonymousTokenTransportMock = URLSessionTransportMock()
        self.webViewAuthStrategyMock = WebViewAuthStrategyMock()

        self.vkid = self.createVKID(
            rootContainer: self.createRootContainer(
                webViewAuthStrategyFactory: WebViewAuthStrategyFactoryMock(
                    webViewAuthStrategyMock: self.webViewAuthStrategyMock
                )
            ),
            appInteropOpener: self.appInteropOpenerMock,
            mainTransport: self.mainTransportMock,
            anonymousTokenTransport: self.anonymousTokenTransportMock
        )
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        self.pkceSecrets = nil
        self.authConfig = nil

        self.appInteropOpenerMock = nil
        self.mainTransportMock = nil
        self.anonymousTokenTransportMock = nil
        self.webViewAuthStrategyMock = nil

        self.vkid = nil
    }

    func testSuccessfulAuthorizationViaProvider() throws {
        Allure.report(
            .init(
                id: 2334363,
                name: "Попытка авторизоваться через прыжок в провайдер",
                meta: self.testCaseMeta
            )
        )

        let didEnterToProviderExpectation = XCTestExpectation(
            description: "Ожидание открытия провайдера"
        )
        let didEndAuthorizationExpectation = XCTestExpectation(
            description: "Ожидание конца авторизации"
        )

        given("При запросе провайдеров - получен один провайдер") {
            let scope: Scope = .random
            let oAuth2Params = oAuth2Parameters(
                from: self.authContext,
                with: scope.description
            )

            self.authConfig = .init(
                flow: .publicClientFlow(pkce: self.pkceSecrets),
                scope: scope
            )

            self.setupMainTransportResponse(
                authProvidersRequestInterceptor: {
                    didEnterToProviderExpectation.fulfill()

                    return self.getAuthProvidersResponse(count: 1)
                }
            )

            self.appInteropOpenerMock.didOpenApplication = { universalLink in
                XCTAssertEqual(
                    oAuth2Params,
                    universalLink.oAuth2Params
                )

                return true
            }
        }

        when("Запускается авторизация, происходит попытка открыть провайдер") {
            self.vkid.authorize(
                authContext: self.authContext,
                authConfig: self.authConfig,
                oAuthProviderConfig: .init(primaryProvider: .vkid),
                presenter: .newUIWindow
            ) { result in
                guard case .success = result else {
                    XCTFail("Получена ошибка авторизации")
                    return
                }

                didEndAuthorizationExpectation.fulfill()
            }

            wait(for: [didEnterToProviderExpectation])
        }

        try then("Провайдер возвращает обратно в приложение, срабатывает AppInteropOpening") {
            _ = self.vkid.open(
                url: try self.getURLFromProvider()
            )

            wait(for: [didEndAuthorizationExpectation])
        }
    }

    func testOpenEachProviderFromTheList() throws {
        Allure.report(
            .init(
                id: 2315448,
                name: "Попытка открыть каждый провайдер из списка в проходе по циклу",
                meta: self.testCaseMeta
            )
        )

        let count = Int.random(in: 2...10)

        let didEnterToProviderExpectation = XCTestExpectation(
            description: "Ожидание открытия провайдера"
        )
        let didEndAuthorizationExpectation = XCTestExpectation(
            description: "Ожидание конца авторизации"
        )

        didEnterToProviderExpectation.expectedFulfillmentCount = count

        try given(
            "При запросе провайдеров - получено несколько провайдеров, все они перебираются и открывается последний"
        ) {
            let authProvidersResponse = self.getAuthProvidersResponse(count: count)
            let lastProviderUniversalLink = try self.getExpectedProviderAuthURL(
                universalLink: try authProvidersResponse.providerWithMinimalWeight().universalLink
            )

            var previousProvider = try authProvidersResponse.providerWithMaximumWeight()

            self.setupMainTransportResponse(
                authProvidersRequestInterceptor: {
                    didEnterToProviderExpectation.fulfill()

                    return authProvidersResponse
                }
            )

            self.appInteropOpenerMock.didOpenApplication = { universalLink in
                defer { didEnterToProviderExpectation.fulfill() }

                do {
                    let openingProvider = try authProvidersResponse.getProvider(with: universalLink)

                    XCTAssertLessThanOrEqual(
                        openingProvider.weight,
                        previousProvider.weight,
                        "Получен провайдер, у которого вес больше предыдущего"
                    )

                    previousProvider = openingProvider
                } catch {
                    XCTFail("Получен несуществующий universalLink")
                    return false
                }

                // Вернем true только для последнего по счету провайдера и если полученный url совпадает с ожидаемым
                return universalLink == lastProviderUniversalLink
            }
        }

        when("Запускается авторизация, происходит попытка открыть провайдер") {
            self.vkid.authorize(
                authContext: self.authContext,
                authConfig: self.authConfig,
                oAuthProviderConfig: .init(primaryProvider: .vkid),
                presenter: .newUIWindow
            ) { result in
                guard case .success = result else {
                    XCTFail("Получена ошибка авторизации")
                    return
                }

                didEndAuthorizationExpectation.fulfill()
            }

            wait(for: [didEnterToProviderExpectation])
        }

        try then("Провайдер возвращает обратно в приложение, срабатывает AppInteropOpening") {
            _ = self.vkid.open(
                url: try self.getURLFromProvider()
            )

            wait(for: [didEndAuthorizationExpectation])
        }
    }

    func testStartAuthorizationViaWebViewAfterProviderHasNotOpened() throws {
        Allure.report(
            .init(
                id: 2315440,
                name: "Фолбэк на авторизацию через вебвью (провайдер не найден/не открыался)",
                meta: self.testCaseMeta
            )
        )

        let didEnterToWebViewExpectation = XCTestExpectation(
            description: "Ожидание открытия авторизации через WebView"
        )
        let didEndAuthorizationExpectation = XCTestExpectation(
            description: "Ожидание конца авторизации"
        )

        given("При запросе провайдеров - получен один провайдер") {
            self.setupMainTransportResponse(
                authProvidersRequestInterceptor: {
                    self.getAuthProvidersResponse(count: 1)
                }
            )

            self.appInteropOpenerMock.didOpenApplication = { _ in false }

            self.webViewAuthStrategyMock.handler = { _, _, _, completion in
                didEnterToWebViewExpectation.fulfill()

                completion(
                    .success(.random())
                )
            }
        }

        when("Запускается авторизация, происходит попытка открыть провайдер") {
            self.vkid.authorize(
                authContext: self.authContext,
                authConfig: self.authConfig,
                oAuthProviderConfig: self.oAuthProviderConfig,
                presenter: .newUIWindow
            ) { _ in
                didEndAuthorizationExpectation.fulfill()
            }
        }

        then("Провайдер не найден / не открылся, начинается авторизация через WebView") {
            wait(for: [didEnterToWebViewExpectation, didEndAuthorizationExpectation])
        }
    }

    func testStartAuthorizationViaWebViewAfterProviderError() throws {
        Allure.report(
            .init(
                id: 2315441,
                name: "Фолбэк на авторизацию через вебвью (провайдер вернул ошибку)",
                meta: self.testCaseMeta
            )
        )

        let didEnterToProviderExpectation = XCTestExpectation(
            description: "Ожидание открытия авторизации через провайдер"
        )
        let didEnterToWebViewExpectation = XCTestExpectation(
            description: "Ожидание открытия авторизации через WebView"
        )
        let didEndAuthorizationExpectation = XCTestExpectation(
            description: "Ожидание конца авторизации"
        )

        given("При запросе провайдеров - получен один провайдер") {
            self.setupMainTransportResponse(
                authProvidersRequestInterceptor: {
                    didEnterToProviderExpectation.fulfill()

                    return self.getAuthProvidersResponse(count: 1)
                }
            )

            self.appInteropOpenerMock.didOpenApplication = { _ in true }

            self.webViewAuthStrategyMock.handler = { _, _, _, completion in
                didEnterToWebViewExpectation.fulfill()

                completion(
                    .success(.random())
                )
            }
        }

        when("Запускается авторизация, происходит попытка открыть провайдер") {
            self.vkid.authorize(
                authContext: self.authContext,
                authConfig: self.authConfig,
                oAuthProviderConfig: self.oAuthProviderConfig,
                presenter: .newUIWindow
            ) { _ in
                didEndAuthorizationExpectation.fulfill()
            }

            wait(for: [didEnterToProviderExpectation])
        }

        try then("Провайдер вернул ошибку, начинается авторизация через WebView") {
            _ = self.vkid.open(
                url: try self.getURLFromProviderWithError()
            )

            wait(for: [didEnterToWebViewExpectation, didEndAuthorizationExpectation])
        }
    }

    func testStartAuthorizationViaWebViewAfterManuallyOpeningApplication() throws {
        Allure.report(
            .init(
                id: 2315442,
                name: "Фолбэк на авторизацию через вебвью (сами вернулись из провайдера)",
                meta: self.testCaseMeta
            )
        )

        let didEnterToProviderExpectation = XCTestExpectation(
            description: "Ожидание открытия авторизации через провайдер"
        )
        let didEnterToWebViewExpectation = XCTestExpectation(
            description: "Ожидание открытия авторизации через WebView"
        )
        let didEndAuthorizationExpectation = XCTestExpectation(
            description: "Ожидание конца авторизации"
        )

        given("При запросе провайдеров - получен один провайдер") {
            self.setupMainTransportResponse(
                authProvidersRequestInterceptor: {
                    didEnterToProviderExpectation.fulfill()

                    return self.getAuthProvidersResponse(count: 1)
                }
            )

            self.appInteropOpenerMock.didOpenApplication = { _ in true }

            self.webViewAuthStrategyMock.handler = { _, _, _, completion in
                didEnterToWebViewExpectation.fulfill()

                completion(
                    .success(.random())
                )
            }
        }

        when("Запускается авторизация, происходит попытка открыть провайдер") {
            self.vkid.authorize(
                authContext: self.authContext,
                authConfig: self.authConfig,
                oAuthProviderConfig: self.oAuthProviderConfig,
                presenter: .newUIWindow
            ) { _ in
                didEndAuthorizationExpectation.fulfill()
            }

            wait(for: [didEnterToProviderExpectation])
        }

        then(
            "Пользователь явно не закончил авторизацию в провайдере и открыл приложение с VKID SDK, начинается авторизация через WebView"
        ) {
            // Симулируем запуск приложения с нашим SDK из фона
            NotificationCenter.default.post(
                Notification(
                    name: UIApplication.didBecomeActiveNotification
                )
            )

            wait(for: [didEnterToWebViewExpectation, didEndAuthorizationExpectation])
        }
    }

    func testStartAuthorizationViaWebViewWhenOAuthProviderIsntVKID() throws {
        Allure.report(
            .init(
                id: 2315438,
                name: "Фолбэк на авторизацию через вебвью (при авторизации не через vkid)",
                meta: self.testCaseMeta
            )
        )

        let didEnterToWebViewExpectation = XCTestExpectation(
            description: "Ожидание открытия авторизации через WebView"
        )
        let didEndAuthorizationExpectation = XCTestExpectation(
            description: "Ожидание конца авторизации"
        )

        given("Не отправляется запрос провайдеров") {
            self.setupMainTransportResponse(
                authProvidersRequestInterceptor: {
                    XCTFail(
                        "Получен запрос провайдеров, вместо того чтобы открывать веб вью"
                    )
                    return self.getAuthProvidersResponse(count: 1)
                }
            )

            self.webViewAuthStrategyMock.handler = { _, _, _, completion in
                didEnterToWebViewExpectation.fulfill()

                completion(
                    .success(.random())
                )
            }
        }

        try when("Запускается авторизация через сторонний сервис") {
            let oAuthProvider: OAuthProvider = try XCTUnwrap(
                [.ok, .mail].randomElement()
            )

            self.vkid.authorize(
                authContext: self.authContext,
                authConfig: self.authConfig,
                oAuthProviderConfig: .init(primaryProvider: oAuthProvider),
                presenter: .newUIWindow
            ) { _ in
                didEndAuthorizationExpectation.fulfill()
            }
        }

        then(
            "Авторизация через сторонний сервис начинается сразу в WebView"
        ) {
            wait(for: [didEnterToWebViewExpectation, didEndAuthorizationExpectation])
        }
    }

    func testOpenApplicationWithProvokingADoubleBecomeActiveNotification() throws {
        Allure.report(
            .init(
                id: 2343999,
                name: "[Corner case] Авторизация через провайдер, при срабатывании нескольких событий DidBecomeActiveNotification",
                meta: self.testCaseMeta
            )
        )

        let didEnterToProviderExpectation = XCTestExpectation(
            description: "Ожидание открытия авторизации через провайдер"
        )
        let didEnterToWebViewExpectation = XCTestExpectation(
            description: "Ожидание открытия авторизации через WebView"
        )
        let didEndAuthorizationExpectation = XCTestExpectation(
            description: "Ожидание конца авторизации"
        )

        given("При запросе провайдеров - получен один провайдер") {
            self.setupMainTransportResponse(
                authProvidersRequestInterceptor: {
                    didEnterToProviderExpectation.fulfill()

                    return self.getAuthProvidersResponse(count: 1)
                }
            )

            self.appInteropOpenerMock.didOpenApplication = { _ in true }

            self.webViewAuthStrategyMock.handler = { _, _, _, completion in
                didEnterToWebViewExpectation.fulfill()

                completion(
                    .success(
                        .random(
                            state: self.pkceSecrets.state
                        )
                    )
                )
            }
        }

        when("Запускается авторизация, происходит попытка открыть провайдер") {
            self.vkid.authorize(
                authContext: self.authContext,
                authConfig: self.authConfig,
                oAuthProviderConfig: self.oAuthProviderConfig,
                presenter: .newUIWindow
            ) { result in
                switch result {
                case .success:
                    break
                case .failure:
                    XCTFail("Неожиданная ошибка авторизации")
                }
                didEndAuthorizationExpectation.fulfill()
            }

            wait(for: [didEnterToProviderExpectation])
        }

        then(
            "Пользователь явно не закончил авторизацию в провайдере и открыл приложение с VKID SDK, начинается авторизация через WebView"
        ) {
            // Симулируем запуск приложения с нашим SDK из фона, и появление алерта
            NotificationCenter.default.post(
                Notification(
                    name: UIApplication.didBecomeActiveNotification
                )
            )
            NotificationCenter.default.post(
                Notification(
                    name: UIApplication.didBecomeActiveNotification
                )
            )

            wait(for: [didEnterToWebViewExpectation, didEndAuthorizationExpectation])
        }
    }

    private func setupMainTransportResponse(
        authProvidersRequestInterceptor: (() -> Auth.GetAuthProviders.Response)? = nil
    ) {
        self.mainTransportMock.responseProvider = { response, request in
            if response.isAuthProvidersResponse, let authProvidersRequestInterceptor {
                return .success(
                    authProvidersRequestInterceptor()
                )
            } else if response.isExchangeAuthCodeResponse, let state = request.state {
                return .success(
                    self.getExchangeAuthCodeResponse(state: state)
                )
            } else {
                return .failure(
                    .unknown
                )
            }
        }
    }

    private func getURLFromProviderWithError() throws -> URL {
        try XCTUnwrap(
            .fromProviderWithError(
                appCredentials: Entity.appCredentials
            )
        )
    }

    private func getURLFromProvider() throws -> URL {
        try XCTUnwrap(
            .fromProvider(
                authContext: self.authContext,
                appCredentials: Entity.appCredentials,
                pkceSecrets: self.pkceSecrets,
                scope: .random,
                code: .random,
                deviceId: .random
            )
        )
    }

    private func getExpectedProviderAuthURL(universalLink: URL) throws -> URL {
        try XCTUnwrap(
            .providerAuthorize(
                universalLink: universalLink,
                authContext: self.authContext,
                appCredentials: Entity.appCredentials,
                pkceSecrets: self.pkceSecrets
            )
        )
    }

    private func getAuthProvidersResponse(count: Int) -> Auth.GetAuthProviders.Response {
        Auth.GetAuthProviders.Response.random(count: count)
    }

    private func getExchangeAuthCodeResponse(state: String) -> OAuth2.ExchangeAuthCode.Response {
        OAuth2.ExchangeAuthCode.Response.random(state: state)
    }
}

extension Auth.GetAuthProviders.Response {
    fileprivate func providerWithMinimalWeight() throws -> Auth.GetAuthProviders.Provider {
        try XCTUnwrap(
            self.items.min(
                by: { $0.weight < $1.weight }
            )
        )
    }

    fileprivate func providerWithMaximumWeight() throws -> Auth.GetAuthProviders.Provider {
        try XCTUnwrap(
            self.items.max(
                by: { $0.weight < $1.weight }
            )
        )
    }

    fileprivate func getProvider(with universalLink: URL) throws -> Auth.GetAuthProviders.Provider {
        try XCTUnwrap(
            self.items.first { $0.universalLink == universalLink.withoutQueryItems }
        )
    }
}

extension URL {
    fileprivate var withoutQueryItems: URL! {
        var urlComponents = self.urlComponents

        urlComponents.queryItems = nil

        return urlComponents.url!
    }

    private var redirectUri: URL? {
        let urlComponents = self.urlComponents

        let redirectUriString = urlComponents.queryItems?
            .first { $0.name == "redirect_uri" }?
            .value

        return URL(
            string: redirectUriString ?? ""
        )
    }

    fileprivate var oAuth2Params: String? {
        let redirectUri = self.redirectUri

        let urlComponents = redirectUri?.urlComponents

        return urlComponents?.queryItems?
            .first { $0.name == "oauth2_params" }?
            .value
    }

    private var urlComponents: URLComponents {
        URLComponents(url: self, resolvingAgainstBaseURL: false)!
    }
}

extension VKAPIRequest {
    fileprivate var state: String? {
        self.parameters["state"] as? String
    }

    fileprivate var code: String? {
        self.parameters["code"] as? String
    }

    fileprivate var deviceId: String? {
        self.parameters["deviceId"] as? String
    }

    private var clientId: String? {
        self.parameters["clientId"] as? String
    }
}
