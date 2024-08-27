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

final class LogoutTests: XCTestCase, TestCaseInfra {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "Взаимодействие с авторизованной сессией пользователя (UserSession)",
        priority: .critical
    )
    var vkid: VKID!
    var urlSessionTransportMock: URLSessionTransportMock!
    var userSessionDataStorageMock: UserSessionDataStorageMock!

    override func setUpWithError() throws {
        self.userSessionDataStorageMock = UserSessionDataStorageMock()
        self.urlSessionTransportMock = URLSessionTransportMock()
        self.vkid = self.createVKID(
            userSessionDataStorage: self.userSessionDataStorageMock,
            mainTransport: self.urlSessionTransportMock
        )
    }

    override func tearDownWithError() throws {
        self.urlSessionTransportMock = nil
        self.userSessionDataStorageMock = nil
        self.vkid = nil
    }

    func testSuccessLogout() {
        Allure.report(
            .init(
                id: 2315464,
                name: "Удаление авторизованной сессии из хранилища при успешном логауте",
                meta: self.testCaseMeta
            )
        )
        var session: UserSession!
        var userSessionData: UserSessionData!
        let successResponseExpectation = expectation(
            description: "Сервер предоставил респонс с успешным логаутом"
        )
        let successLogoutExpectation = expectation(
            description: "Успешный логаут"
        )

        given("Создание сессии") {
            (session, userSessionData) = self.createUserSession()
            self.mockLogoutResponse {
                successResponseExpectation.fulfill()
                return .success(OAuth2.Logout.Response.init(response: 1))
            }
        }
        when("Логаут") {
            session.logout { result in
                then("Проверка логаута") {
                    do {
                        guard
                            case .success = result,
                            try self.userSessionDataStorageMock
                                .readUserSessionData(for: userSessionData.id) == nil
                        else {
                            XCTFail("Logout failed")
                            return
                        }
                        successLogoutExpectation.fulfill()
                    } catch {
                        XCTFail("Storage mock error")
                    }
                }
            }
            self.wait(
                for: [
                    successLogoutExpectation,
                    successResponseExpectation,
                ],
                timeout: 1
            )
        }
    }

    func testFailedLogout() {
        Allure.report(
            .init(
                id: 2315465,
                name: "Сетевая ошибка при логауте",
                meta: self.testCaseMeta
            )
        )
        var session: UserSession!
        var userSessionData: UserSessionData!
        let failureResponseExpectation = expectation(description: "Респонс с ошибкой")
        let failureResponseHandledExpectation = expectation(description: "Респонс с ошибкой обработан верно")

        given("Создание сессии") {
            (session, userSessionData) = self.createUserSession()
            self.mockLogoutResponse {
                failureResponseExpectation.fulfill()
                return .failure(.unknown)
            }
        }
        when("Логаут") {
            session.logout { result in
                then("Проверка логаута") {
                    do {
                        guard
                            case .failure(.unknown) = result,
                            let userStorageSessionData = try self.userSessionDataStorageMock
                                .readUserSessionData(for: userSessionData.id),
                                userStorageSessionData == userSessionData
                        else {
                            XCTFail("Failed logout handled wrong way")
                            return
                        }
                        failureResponseHandledExpectation.fulfill()
                    } catch {
                        XCTFail("Storage mock error")
                    }
                }
            }
            self.wait(
                for: [
                    failureResponseExpectation,
                    failureResponseHandledExpectation,
                ],
                timeout: 1
            )
        }
    }

    private func mockLogoutResponse(
        responseProvider: @escaping () -> Result<any VKAPIResponse, VKAPIError>
    ) {
        self.urlSessionTransportMock.responseProvider = { responseType, request in
            if responseType.isLogoutResponse,
               request.path == "/oauth2/logout"
            {
                return responseProvider()
            }
            return .failure(.unknown)
        }
    }
}
