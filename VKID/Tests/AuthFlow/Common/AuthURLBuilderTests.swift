//
// Copyright (c) 2023 - present, LLC “V Kontakte”
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
import VKIDCore
import XCTest
@testable import VKID

final class AuthURLBuilderTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDCore,
        feature: "Создание запроса авторизации"
    )
    private var builder: AuthURLBuilder!

    private let secrets = PKCESecretsWallet(secrets: .init(
        codeVerifier: "test_code_vefifier_1@3$5",
        codeChallenge: "test_code_challenge_1@3$5",
        codeChallengeMethod: .s256,
        state: UUID().uuidString
    ))
    private let scope = "email phone_number"

    private let credentials = AppCredentials(clientId: "test_client_id_1@3$5", clientSecret: "test_client_secret_1@3$5")
    private let context = AuthContext(launchedBy: .service)

    override func setUpWithError() throws {
        self.builder = AuthURLBuilderImpl()
    }

    override func tearDownWithError() throws {
        self.builder = nil
    }

    func testBuildProviderAuthURLWithValidParameters() {
        Allure.report(
            .init(
                id: 2291645,
                name: "Валидный запрос через провайдер",
                meta: self.testCaseMeta
            )
        )
        given("Создается запрос авторизации и ожидаемые параметры") {
            do {
                let baseURL = URL(string: "http://example.com/")!

                let result = try builder.buildProviderAuthURL(
                    baseURL: baseURL,
                    authContext: self.context,
                    secrets: self.secrets,
                    credentials: self.credentials,
                    scope: self.scope,
                    deviceId: DeviceId.currentDeviceId.description
                )

                let urlComponents = URLComponents(url: result, resolvingAgainstBaseURL: true)
                let commonQueryItems = try createCommonQueryItems(
                    authContext: self.context,
                    secrets: self.secrets,
                    credentials: self.credentials
                )
                let expectedQueryItems = commonQueryItems + [
                    .authProviderMethod,
                    .init(
                        name: "redirect_uri",
                        value: redirectURL(
                            for: self.credentials.clientId,
                            in: self.context,
                            scope: self.scope,
                            version: Env.VKIDVersion
                        ).absoluteString
                    ),
                ]
                when("Создаем компоненты и URL") {
                    guard var expectedURLComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                        XCTFail("Failed to form a url string")
                        return
                    }
                    expectedURLComponents.queryItems = expectedQueryItems
                    then("Проверяем параметры и весь URL") {
                        XCTAssertEqual(urlComponents?.queryItems, expectedQueryItems)
                        XCTAssertEqual(expectedURLComponents.url, result)
                    }
                }
            } catch {
                XCTFail("Error in build URL from valid string: \(error)")
            }
        }
    }

    func testBuildProviderAuthURLWithEmptyParameters() {
        Allure.report(
            .init(
                id: 2291667,
                name: "Запрос с пустыми параметрами через провайдер",
                meta: self.testCaseMeta
            )
        )
        given("Создается запрос авторизации без параметров и ожидаемые параметры") {
            do {
                let baseURL = URL(string: "http://example.com/")!

                let secrets = PKCESecretsWallet(secrets: .init(
                    codeVerifier: "",
                    codeChallenge: "",
                    codeChallengeMethod: .s256,
                    state: ""
                ))
                let credentials = AppCredentials(clientId: "", clientSecret: "")
                let context = AuthContext(uniqueSessionId: "", launchedBy: .service)

                let result = try builder.buildProviderAuthURL(
                    baseURL: baseURL,
                    authContext: context,
                    secrets: secrets,
                    credentials: credentials,
                    scope: self.scope,
                    deviceId: DeviceId.currentDeviceId.description
                )

                let urlComponents = URLComponents(url: result, resolvingAgainstBaseURL: true)
                let commonQueryItems = try createCommonQueryItems(
                    authContext: context,
                    secrets: secrets,
                    credentials: credentials
                )
                let expectedQueryItems = commonQueryItems + [
                    .authProviderMethod,
                    .init(
                        name: "redirect_uri",
                        value: redirectURL(
                            for: credentials.clientId,
                            in: context,
                            scope: self.scope,
                            version: Env.VKIDVersion
                        ).absoluteString
                    ),
                ]
                when("Создаем компоненты и URL") {
                    guard var expectedURLComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                        XCTFail("Failed to form a url string")
                        return
                    }
                    expectedURLComponents.queryItems = expectedQueryItems
                    then("Проверяем параметры и весь URL") {
                        XCTAssertEqual(urlComponents?.queryItems, expectedQueryItems)
                        XCTAssertEqual(expectedURLComponents.url, result)
                    }
                }
            } catch {
                XCTFail("Error in build URL from valid string: \(error)")
            }
        }
    }

    func testBuildWebViewAuthURLWithValidParameters() {
        Allure.report(
            .init(
                id: 2291684,
                name: "Валидный запрос через вебвью",
                meta: self.testCaseMeta
            )
        )
        given("Создается запрос авторизации и ожидаемые параметры") {
            do {
                let baseURL = URL(string:"http://example.com/")!

                let oAuth = OAuthProvider.vkid
                let appearance = Appearance(colorScheme: .dark, locale: .ru)

                let result = try builder.buildWebViewAuthURL(
                    baseURL: baseURL,
                    oAuthProvider: oAuth,
                    authContext: self.context,
                    secrets: self.secrets,
                    credentials: self.credentials,
                    scope: self.scope,
                    deviceId: DeviceId.currentDeviceId.description,
                    appearance: appearance
                )

                let urlComponents = URLComponents(url: result, resolvingAgainstBaseURL: true)

                let commonQueryItems = try createCommonQueryItems(
                    authContext: self.context,
                    secrets: self.secrets,
                    credentials: self.credentials
                )
                let expectedQueryItems = commonQueryItems + [
                    .scheme("dark"),
                    .langId("0"),
                    .provider(oAuth: oAuth),
                    .codeChallengeMethod(try self.secrets.codeChallengeMethod.rawValue),
                    .deviceId(DeviceId.currentDeviceId.description),
                    .prompt("login"),
                    .oAuthVersion,
                    .version(Env.VKIDVersion),
                    .scope(self.scope),
                    .statsInfo(
                        base64StatsInfo(
                            from: self.context
                        )
                    ),
                    .init(
                        name: "redirect_uri",
                        value: redirectURL(
                            for: self.credentials.clientId
                        ).absoluteString
                    ),
                ]

                when("Создаем компоненты и URL") {
                    guard var expectedURLComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                        XCTFail("Failed to form a url string")
                        return
                    }

                    expectedURLComponents.queryItems = expectedQueryItems
                    then("Проверяем параметры и весь URL") {
                        XCTAssertEqual(urlComponents?.queryItems, expectedQueryItems)
                        XCTAssertEqual(expectedURLComponents.url, result)
                    }
                }
            } catch {
                XCTFail("Error in build URL from valid string: \(error)")
            }
        }
    }

    func testBuildWebViewAuthURLEmptyQueryItems() {
        Allure.report(
            .init(
                id: 2291660,
                name: "Запрос c пустыми параметрами через вебвью",
                meta: self.testCaseMeta
            )
        )
        given("Создается запрос авторизации c пустыми параметрами и ожидаемые параметры") {
            do {
                let baseURL = URL(string: "http://example.com/")!

                let oAuth = OAuthProvider.vkid
                let secrets = PKCESecretsWallet(secrets: .init(
                    codeVerifier: "",
                    codeChallenge: "",
                    codeChallengeMethod: .s256,
                    state: ""
                ))
                let credentials = AppCredentials(clientId: "", clientSecret: "")
                let appearance = Appearance(colorScheme: .light, locale: .en)
                let context = AuthContext(uniqueSessionId: "", launchedBy: .service)

                let result = try builder.buildWebViewAuthURL(
                    baseURL: baseURL,
                    oAuthProvider: oAuth,
                    authContext: context,
                    secrets: secrets,
                    credentials: credentials,
                    scope: self.scope,
                    deviceId: DeviceId.currentDeviceId.description,
                    appearance: appearance
                )

                let urlComponents = URLComponents(url: result, resolvingAgainstBaseURL: true)
                let commonQueryItems = try createCommonQueryItems(
                    authContext: context,
                    secrets: secrets,
                    credentials: credentials
                )
                let expectedQueryItems = commonQueryItems + [
                    .scheme("light"),
                    .langId("3"),
                    .provider(oAuth: oAuth),
                    .codeChallengeMethod(try secrets.codeChallengeMethod.rawValue),
                    .deviceId(DeviceId.currentDeviceId.description),
                    .prompt("login"),
                    .oAuthVersion,
                    .version(Env.VKIDVersion),
                    .scope(self.scope),
                    .statsInfo(
                        base64StatsInfo(
                            from: context
                        )
                    ),
                    .redirectURI(
                        redirectURL(
                            for: credentials.clientId
                        ).absoluteString
                    ),
                ]
                when("Создаем компоненты и URL") {
                    guard var expectedURLComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                        XCTFail("Failed to form a url string")
                        return
                    }
                    expectedURLComponents.queryItems = expectedQueryItems
                    then("Проверяем параметры и весь URL") {
                        XCTAssertEqual(expectedURLComponents.url, result)
                        XCTAssertEqual(urlComponents?.queryItems, expectedQueryItems)
                    }
                }
            } catch {
                XCTFail("Error in build URL from valid string: \(error)")
            }
        }
    }
}

extension AuthURLBuilderTests {
    private func createCommonQueryItems(
        authContext: AuthContext,
        secrets: PKCESecretsWallet,
        credentials: AppCredentials
    ) throws -> [URLQueryItem] {
        [
            .init(name: "response_type", value: "code"),
            .init(name: "state", value: try secrets.state),
            .init(name: "code_challenge", value: try secrets.codeChallenge),
            .init(name: "client_id", value: credentials.clientId),
        ]
    }
}
