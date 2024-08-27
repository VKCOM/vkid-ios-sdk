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

final class UserFetchingTests: XCTestCase, TestCaseInfra {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "Взаимодействие с авторизованной сессией пользователя (UserSession)",
        priority: .critical
    )
    var vkid: VKID!
    var urlSessionTransportMock: URLSessionTransportMock!
    var session: UserSession!
    var userSessionData: UserSessionData!

    override func setUpWithError() throws {
        let rootContainer = RootContainer(
            appCredentials: Entity.appCredentials,
            networkConfiguration: .init(isSSLPinningEnabled: false)
        )
        self.urlSessionTransportMock = URLSessionTransportMock()
        self.vkid = self.createVKID(
            rootContainer: rootContainer,
            mainTransport: self.urlSessionTransportMock
        )
    }

    override func tearDownWithError() throws {
        self.vkid = nil
        self.urlSessionTransportMock = nil
        self.session = nil
        self.userSessionData = nil
    }

    func testFetchingUser() {
        Allure.report(
            .init(
                id: 2315452,
                name: "Загрузка пользовательских данных из сети",
                meta: self.testCaseMeta
            )
        )
        let userResponseProvidedExpectation = expectation(
            description: "Сервер предоставил данные пользователя"
        )
        let userFetchedExpectation = expectation(
            description: "Успешное получение данных пользователя"
        )
        var updatedUser: User!
        given("Создание сессии, добавление респонса") {
            (self.session, self.userSessionData) = self.createUserSession()
            updatedUser = UserSessionData.random(userId: self.userSessionData.id.value).user!
            self.mockUserFetchingResponse {
                userResponseProvidedExpectation.fulfill()
                return .success(OAuth2.UserInfo.Response.create(updatedUser))
            }
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
                    userFetchedExpectation.fulfill()
                }
            }
            self.wait(
                for: [
                    userResponseProvidedExpectation,
                    userFetchedExpectation,
                ],
                timeout: 1
            )
        }
    }

    func testUserFetchingFailed() {
        Allure.report(
            .init(
                id: 2315458,
                name: "Сетевая ошибка при загрузке данных",
                meta: self.testCaseMeta
            )
        )
        let errorResponseProvidedExpectation = expectation(
            description: "Сервер вернул ошибку"
        )
        let handledUserFetchingExpectation = expectation(
            description: "Правильная обработка ошибки"
        )
        given("Создание сессии, добавление респонса") {
            (self.session, self.userSessionData) = self.createUserSession(
                userSessionData: UserSessionData.random(withUserData: false)
            )
            self.mockUserFetchingResponse {
                errorResponseProvidedExpectation.fulfill()
                return .failure(VKAPIError.noResponseDataProvided)
            }
        }
        when("Получение пользовательских данных") {
            self.session.fetchUser { result in
                then("Проверка полученных данных") {
                    if case .failure(UserFetchingError.unknown) = result {
                        handledUserFetchingExpectation.fulfill()
                    } else {
                        XCTFail("Failed to handle failed response")
                    }
                }
            }
            self.wait(
                for: [
                    handledUserFetchingExpectation,
                    errorResponseProvidedExpectation,
                ],
                timeout: 1
            )
        }
    }

    func testUserObtainginFromCache() {
        Allure.report(
            .init(
                id: 2315453,
                name: "Получение из кэша ранее загруженных данных",
                meta: self.testCaseMeta
            )
        )
        given("Создание сессии") {
            (self.session, self.userSessionData) = self.createUserSession()
        }
        when("Получение пользовательских данных из сессии") {
            then("Проверка данных пользователя") {
                XCTAssertEqual(self.session.user, self.userSessionData.user)
            }
        }
    }

    func testUserFetchingRefreshesCache() {
        Allure.report(
            .init(
                id: 2315457,
                name: "Обновление данных в кэше при повторной загрузке из сети",
                meta: self.testCaseMeta
            )
        )
        let userResponseProvidedExpectation = expectation(
            description: "Сервер предоставил данные пользователя"
        )
        let userFetchedExpectation = expectation(
            description: "Успешное получение данных пользователя"
        )
        var updatedUser: User!
        given("Создание сессии, добавление респонса") {
            (self.session, self.userSessionData) = self.createUserSession()
            updatedUser = UserSessionData.random(userId: self.userSessionData.id.value).user
            self.mockUserFetchingResponse {
                userResponseProvidedExpectation.fulfill()
                return .success(OAuth2.UserInfo.Response.create(updatedUser))
            }
        }
        when("Получение пользовательских данных") {
            self.session.fetchUser { result in
                then("Проверка данных в кеше") {
                    guard
                        case .success = result
                    else {
                        XCTFail("User data was not obtained")
                        return
                    }
                    XCTAssertEqual(self.session.user, updatedUser)
                    userFetchedExpectation.fulfill()
                }
            }
            self.wait(
                for: [
                    userResponseProvidedExpectation,
                    userFetchedExpectation,
                ],
                timeout: 1
            )
        }
    }

    private func mockUserFetchingResponse(
        responseProvider: @escaping () -> Result<VKIDCore.VKAPIResponse, VKIDCore.VKAPIError>
    ) {
        self.urlSessionTransportMock.responseProvider = { responseType, request in
            if responseType.isUserInfoResponse,
               request.path == "/oauth2/user_info"
            {
                return responseProvider()
            }
            return .failure(.unknown)
        }
    }
}
