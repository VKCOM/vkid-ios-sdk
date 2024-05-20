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

import VKIDCore
import XCTest
@testable import VKID
@testable import VKIDAllureReport

final class UserSessionManagerLogoutSessionTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .integration,
        product: .VKIDSDK,
        feature: "Логаут сессий в UserSessionManager"
    )

    var actualUserId: Int!
    var actualUserSession: UserSessionImpl!

    var deps: UserSessionManagerTestsDependency!

    override func setUpWithError() throws {
        self.deps = UserSessionManagerTestsDependency()

        self.actualUserId = Int.random
        self.actualUserSession = self.deps.userSessionManager.makeUserSession(
            with: UserSessionData.random(
                userId: self.actualUserId
            )
        )
    }

    override func tearDownWithError() throws {
        self.deps = nil

        self.actualUserId = nil
        self.actualUserSession = nil
    }

    func testUserSessionIsRemovedFromStorageAfterSuccessLogout() throws {
        Allure.report(
            .init(
                name: "После успешного логаута UserSession удаляется из хранилища",
                meta: self.testCaseMeta
            )
        )

        let expectation = XCTestExpectation()

        when("Выполнен успешный логаут из UserSession") {
            self.deps.logoutServiceMock.logoutResult = .success(())

            self.deps.userSessionDelegateMock.didLogout = { _, session, result in
                XCTAssertEqual(
                    ObjectIdentifier(session),
                    ObjectIdentifier(self.actualUserSession)
                )
                XCTAssertTrue(
                    self.deps.logoutServiceMock.logoutResult == result
                )
                expectation.fulfill()
            }

            self.actualUserSession.logout { _ in }

            wait(for: [expectation], timeout: 5.0)
        }

        then("В UserSessionManager и UserSessionDataStorage отсутствует UserSession") {
            XCTAssertNil(
                self.deps.userSessionManager.userSessions.first { $0.userId.value == self.actualUserId }
            )
            XCTAssertNil(
                try? self.deps.userSessionDataStorage.readUserSessionData(for: .init(value: self.actualUserId))
            )
        }
    }

    func testUserSessionIsRemainedStoredAfterFailureLogout() throws {
        Allure.report(
            .init(
                name: "После неудачного логаута UserSession не удаляется из хранилища",
                meta: self.testCaseMeta
            )
        )

        let expectation = XCTestExpectation()

        when("Не удалось выполнить логаут из UserSession") {
            self.deps.logoutServiceMock.logoutResult = .failure(.invalidAccessToken)

            self.deps.userSessionDelegateMock.didLogout = { _, _, _ in
                expectation.fulfill()
            }

            self.actualUserSession.logout { _ in }

            wait(for: [expectation], timeout: 5.0)
        }

        try then("UserSession осталась в UserSessionManager и UserSessionDataStorage") {
            let userSessionFromManager = try XCTUnwrap(
                self.deps.userSessionManager.userSessions.first { $0.userId.value == self.actualUserId }
            )
            let userSessionDataFromStorage = try XCTUnwrap(
                self.deps.userSessionDataStorage.readUserSessionData(for: .init(value: self.actualUserId))
            )

            XCTAssertEqual(userSessionFromManager.data, userSessionDataFromStorage)
            XCTAssertEqual(
                ObjectIdentifier(userSessionFromManager),
                ObjectIdentifier(self.actualUserSession)
            )
        }
    }

    func testLogoutFromUserSessionWhenItsAlreadyLoggedOut() throws {
        Allure.report(
            .init(
                name: "Повторный логаут из UserSession",
                meta: self.testCaseMeta
            )
        )

        let expectationLogoutDelegate = XCTestExpectation()
        let expectationLogoutCompletion = XCTestExpectation()

        when("Первый логаут из UserSession, вызывает методы делегата") {
            self.deps.logoutServiceMock.logoutResult = .success(())

            self.deps.userSessionDelegateMock.didLogout = { _, _, _ in
                expectationLogoutDelegate.fulfill()
            }

            self.actualUserSession.logout { _ in }

            wait(for: [expectationLogoutDelegate], timeout: 5.0)
        }

        // then
        then("Повторный логаут UserSession, не вызывает методы у делегата") {
            self.deps.userSessionDelegateMock.didLogout = { _, _, _ in
                XCTFail()
            }

            self.actualUserSession.logout { _ in
                expectationLogoutCompletion.fulfill()
            }

            wait(for: [expectationLogoutCompletion], timeout: 5.0)
        }
    }
}
