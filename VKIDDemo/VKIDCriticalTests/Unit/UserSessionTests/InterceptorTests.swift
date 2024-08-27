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

@testable import VKID
@testable import VKIDCore

final class InterceptorTests: XCTestCase, TestCaseInfra {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "Взаимодействие с авторизованной сессией пользователя (UserSession)",
        priority: .critical
    )
    var vkid: VKID!
    var urlSessionDataTaskMock: URLSessionDataTaskMock!

    override func setUpWithError() throws {
        self.urlSessionDataTaskMock = URLSessionDataTaskMock()
        let urlSessionMock = URLSessionMock(
            urlSessionDataTaskMock: self.urlSessionDataTaskMock
        )
        let expiredAccessTokenInterceptor = ExpiredAccessTokenInterceptor()
        self.vkid = self.createVKID(
            responseInterceptors: [expiredAccessTokenInterceptor],
            urlSessionMock: urlSessionMock
        )
        expiredAccessTokenInterceptor.userSessionManager = self.vkid.rootContainer.userSessionManager
    }

    override func tearDownWithError() throws {
        self.vkid = nil
        self.urlSessionDataTaskMock = nil
    }

    func testAutoRefresh() {
        Allure.report(
            .init(
                id: 2315463,
                name: "Авторефреш AT в случае получения ошибки о протухшем токене. Например при загрузке пользовательских данных",
                meta: self.testCaseMeta
            )
        )
        var session: UserSession!
        var userSessionData: UserSessionData!
        var updatedSessionData: UserSessionData!
        let invalidTokenExpectation = expectation(
            description: "Ответ сервера, что токен заэкспаерился"
        )
        let userFetchingExpectation = expectation(
            description: "Завершение получения пользовательских данных"
        )

        given("Создание сессии") {
            (session, userSessionData) = self.createUserSession(
                userSessionData: UserSessionData.random(
                    accessTokenExpirationDate: Date() - 60
                )
            )
            updatedSessionData = UserSessionData.random(
                userId: userSessionData.id.value
            )
            self.mockRefreshAndUserInfoResponses(
                updatedSessionData: updatedSessionData,
                invalidTokenExpectation: invalidTokenExpectation
            )
        }
        when("Получение пользовательских данных") {
            session.fetchUser { _ in
                then("Проверяем, что полученный AT соответствуем автоматически обновленному токену") {
                    guard
                        session.accessToken.value == updatedSessionData.accessToken.value,
                        session.refreshToken == updatedSessionData.refreshToken
                    else {
                        XCTFail("Fresh access token not fetched automatically")
                        return
                    }
                    userFetchingExpectation.fulfill()
                }
            }
            self.wait(for: [userFetchingExpectation, invalidTokenExpectation], timeout: 1)
        }
    }

    private func mockRefreshAndUserInfoResponses(
        updatedSessionData: UserSessionData,
        invalidTokenExpectation: XCTestExpectation
    ) {
        var invalidTokenResponseProvided = false
        self.urlSessionDataTaskMock.responseProvider = { request in
            return switch request?.url?.path {
            case "/oauth2/auth": { request in
                    let state = request.parameterValue(byName: "state")
                    let response = OAuth2.RefreshToken.Response.create(
                        userSessionData: updatedSessionData,
                        state: state!
                    )
                    return try! JSONEncoder().encode(response)
                }(request)
            case "/oauth2/user_info": {
                    struct InvalidTokenError: Encodable {
                        let error = "invalid_token"
                        let error_description = "access_token is missing or invalid"
                    }
                    let response: Encodable = {
                        if !invalidTokenResponseProvided {
                            invalidTokenResponseProvided = true
                            invalidTokenExpectation.fulfill()
                            return InvalidTokenError()
                        } else {
                            return OAuth2.UserInfo.Response.create(updatedSessionData.user!)
                        }
                    }()
                    return try! JSONEncoder().encode(response)
                }()
            default: nil
            }
        }
    }
}
