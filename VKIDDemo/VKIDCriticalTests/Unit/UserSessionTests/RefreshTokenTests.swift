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

final class RefreshTokenTests: XCTestCase, TestCaseInfra {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "Взаимодействие с авторизованной сессией пользователя (UserSession)",
        priority: .critical
    )

    var vkid: VKID!
    var userSessionDataStorageMock: UserSessionDataStorageMock!
    var urlSessionTransportMock: URLSessionTransportMock!
    var rootContainer: RootContainer!
    var session: UserSession!
    var userSessionData: UserSessionData!
    var updatedSessionData: UserSessionData!

    override func setUpWithError() throws {
        self.rootContainer = RootContainer(
            appCredentials: Entity.appCredentials,
            networkConfiguration: .init(isSSLPinningEnabled: false)
        )
        self.urlSessionTransportMock = URLSessionTransportMock()
        self.userSessionDataStorageMock = UserSessionDataStorageMock()
        self.vkid = self.createVKID(
            rootContainer: self.rootContainer,
            userSessionDataStorage: self.userSessionDataStorageMock,
            mainTransport: self.urlSessionTransportMock
        )
    }

    override func tearDownWithError() throws {
        self.vkid = nil
        self.userSessionDataStorageMock = nil
        self.urlSessionTransportMock = nil
        self.rootContainer = nil
        self.session = nil
        self.userSessionData = nil
        self.updatedSessionData = nil
    }

    func testObtainFreshAccessToken() {
        Allure.report(
            .init(
                id: 2315459,
                name: "Получение свежего AT (отдаем текущий AT если до его протухания > 1 мин)",
                meta: self.testCaseMeta
            )
        )
        let expectation = expectation(description: #function)
        given("Создание сессии") {
            (self.session, self.userSessionData) = self.createUserSession()
        }
        when("Получение AT") {
            self.session.getFreshAccessToken { result in
                then("Проверяем, что полученный AT соответствуем свежему токену сессии") {
                    guard
                        case .success((let accessToken, _)) = result,
                        self.userSessionData.accessToken == accessToken
                    else {
                        XCTFail("Fresh access token not fetched")
                        return
                    }
                    expectation.fulfill()
                }
            }
            self.wait(for: [expectation], timeout: 1)
        }
    }

    func testObtainRefreshedAccessTokenThatWasNotExpired() {
        Allure.report(
            .init(
                name: "Получение свежего AT (отдаем текущий AT если до его протухания < 1 мин, обновляем AT через RT и возвращаем свежий)",
                meta: self.testCaseMeta
            )
        )
        let responseProvidedExpectation = expectation(
            description: "Успешный респонс от сервера"
        )
        let successRefreshExpectation = expectation(
            description: "Успешный рефреш"
        )

        given("Создание сессии") {
            (self.session, self.userSessionData) = self.createUserSession(
                userSessionData: UserSessionData.random(
                    accessTokenExpirationDate: Date() + 30
                )
            )
            self.updatedSessionData = UserSessionData.random(
                userId: self.userSessionData.id.value
            )
            self.mockRefreshTokenResponse { request in
                responseProvidedExpectation.fulfill()
                return self.successResponse(
                    request: request,
                    userSessionData: self.updatedSessionData
                )
            }
        }
        when("Получение AT") {
            self.session.getFreshAccessToken { result in
                then("Проверяем, что полученный AT соответствует новому токену") {
                    guard
                        case .success((let accessToken, let refreshToken)) = result,
                        self.updatedSessionData.accessToken.value == accessToken.value,
                        self.updatedSessionData.refreshToken == refreshToken
                    else {
                        XCTFail("Fresh access token not fetched")
                        return
                    }
                    successRefreshExpectation.fulfill()
                }
            }
            self.wait(
                for: [
                    successRefreshExpectation,
                    responseProvidedExpectation,
                ],
                timeout: 1
            )
        }
    }

    func testRefreshingExpiredAccessToken() {
        Allure.report(
            .init(
                name: "Получение свежего AT, если он протух",
                meta: self.testCaseMeta
            )
        )
        let responseProvidedExpectation = expectation(
            description: "Успешный респонс от сервера"
        )
        let successRefreshExpectation = expectation(
            description: "Успешный рефреш"
        )
        given("Создание сессии") {
            (self.session, self.userSessionData) = self.createUserSession(
                userSessionData: UserSessionData.random(
                    accessTokenExpirationDate: Date() - 30
                )
            )
            self.updatedSessionData = UserSessionData.random(
                userId: self.userSessionData.id.value
            )
            self.mockRefreshTokenResponse { request in
                responseProvidedExpectation.fulfill()
                return self.successResponse(
                    request: request,
                    userSessionData: self.updatedSessionData
                )
            }
        }
        when("Получение AT") {
            self.session.getFreshAccessToken { result in
                then("Проверяем, что полученный AT соответствует новому токену") {
                    guard
                        case .success((let accessToken, let refreshToken)) = result,
                        self.updatedSessionData.accessToken.value == accessToken.value,
                        self.updatedSessionData.refreshToken == refreshToken
                    else {
                        XCTFail("Fresh access token not fetched")
                        return
                    }
                    successRefreshExpectation.fulfill()
                }
            }
            self.wait(
                for: [
                    successRefreshExpectation,
                    responseProvidedExpectation,
                ],
                timeout: 1
            )
        }
    }

    func testForceRefreshAccessToken() {
        Allure.report(
            .init(
                id: 2315460,
                name: "Принудительное обновление AT по RT",
                meta: self.testCaseMeta
            )
        )
        let responseProvidedExpectation = expectation(
            description: "Успешный респонс от сервера"
        )
        let successRefreshExpectation = expectation(
            description: "Успешный рефреш"
        )
        given("Создание сессии") {
            (self.session, self.userSessionData) = self.createUserSession()
            self.updatedSessionData = UserSessionData.random(
                userId: self.userSessionData.id.value
            )
            self.mockRefreshTokenResponse { request in
                responseProvidedExpectation.fulfill()
                return self.successResponse(
                    request: request,
                    userSessionData: self.updatedSessionData
                )
            }
        }
        when("Принудительное получение AT") {
            self.session.getFreshAccessToken(forceRefresh: true) { result in
                then("Проверяем, что полученный AT соответствуем свежему токену сессии") {
                    guard
                        case .success((let accessToken, let refreshToken)) = result,
                        self.updatedSessionData.accessToken.value == accessToken.value,
                        self.updatedSessionData.refreshToken == refreshToken
                    else {
                        XCTFail("Fresh access token not fetched")
                        return
                    }
                    successRefreshExpectation.fulfill()
                }
            }
            self.wait(
                for: [
                    responseProvidedExpectation,
                    successRefreshExpectation,
                ],
                timeout: 1
            )
        }
    }

    func testForceRefreshWithExpiredRefreshToken() {
        Allure.report(
            .init(
                id: 2315461,
                name: "Принудительное обновление AT по RT, кейс с просроченным RT",
                meta: self.testCaseMeta
            )
        )
        let responseProvidedExpectation = expectation(
            description: "Ошибка рефреша от сервера"
        )
        let handledFailedRefreshExpectation = expectation(
            description: "Корректно обработана ошибка рефреша"
        )
        given("Создание сессии") {
            (self.session, self.userSessionData) = self.createUserSession()
            self.mockRefreshTokenResponse { request in
                responseProvidedExpectation.fulfill()
                return .failure(.invalidRequest(reason: .invalidRefreshToken))
            }
        }
        when("Принудительное получение AT") {
            self.session.getFreshAccessToken(forceRefresh: true) { result in
                then("Проверяем, что полученный AT соответствуем свежему токену сессии") {
                    guard case .failure(.invalidRefreshToken) = result else {
                        XCTFail("Fresh access token not fetched")
                        return
                    }
                    handledFailedRefreshExpectation.fulfill()
                }
            }
            self.wait(
                for: [
                    handledFailedRefreshExpectation,
                    responseProvidedExpectation,
                ],
                timeout: 1
            )
        }
    }

    func testSavingTokensInStorage() {
        Allure.report(
            .init(
                id: 2315462,
                name: "Сохранение обновленных AT и RT в хранилище",
                meta: self.testCaseMeta
            )
        )
        let expectation = expectation(description: #function)
        given("Создание сессии") {
            (self.session, self.userSessionData) = self.createUserSession()
            self.updatedSessionData = UserSessionData.random(
                userId: self.userSessionData.id.value
            )
            self.mockRefreshTokenResponse { request in
                expectation.fulfill()
                return self.successResponse(
                    request: request,
                    userSessionData: self.updatedSessionData
                )
            }
        }
        when("Принудительное получение AT") {
            self.session.getFreshAccessToken(forceRefresh: true) { result in
                then("Проверяем, что AT в хранилище соответствуем свежему токену сессии") {
                    guard
                        case .success((_, _)) = result,
                        let storageSessionData = try? self.userSessionDataStorageMock
                            .readUserSessionData(for: self.updatedSessionData.id),
                            self.updatedSessionData.accessToken.value == storageSessionData.accessToken.value,
                            self.updatedSessionData.refreshToken == storageSessionData.refreshToken
                    else {
                        XCTFail("Storage has wrong AT")
                        return
                    }
                }
            }
            self.wait(for: [expectation], timeout: 1)
        }
    }

    private func mockRefreshTokenResponse(
        responseProvider: @escaping (VKAPIRequest) -> Result<VKIDCore.VKAPIResponse, VKIDCore.VKAPIError>
    ) {
        self.urlSessionTransportMock.responseProvider = { responseType, request in
            if responseType.isRefreshTokenResponse {
                return responseProvider(request)
            }
            return .failure(.unknown)
        }
    }

    func successResponse(request: VKAPIRequest, userSessionData: UserSessionData) -> Result<VKAPIResponse, VKAPIError> {
        .success(OAuth2.RefreshToken.Response.create(
            userSessionData: self.updatedSessionData,
            state: request.parameters["state"] as? String ?? "unknown"
        ))
    }
}

extension VKAPIRequest {
    fileprivate var state: String {
        self.parameters["state"] as? String ?? "unknown"
    }
}
