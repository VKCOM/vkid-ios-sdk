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
import VKIDCore
import XCTest

@testable import VKID

final class UserSessionManagerUpdateSessionTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .integration,
        product: .VKIDSDK,
        feature: "Обновление данных сессий в UserSessionManager"
    )

    var userId: Int!
    var oldUserSessionData: UserSessionData!
    var newUserSessionData: UserSessionData!

    var deps: UserSessionManagerTestsDependency!

    override func setUpWithError() throws {
        self.userId = Int.random
        self.oldUserSessionData = UserSessionData.random(userId: self.userId)
        self.newUserSessionData = UserSessionData.random(userId: self.userId)

        self.deps = UserSessionManagerTestsDependency()
    }

    override func tearDownWithError() throws {
        self.userId = nil
        self.oldUserSessionData = nil
        self.newUserSessionData = nil

        self.deps = nil
    }

    func testUpdateUserSessionDataUpdatesStorage() throws {
        Allure.report(
            .init(
                name: "Обновление UserSessionData у UserSession, обновляет UserSessionData в хранилищах",
                meta: self.testCaseMeta
            )
        )

        let userSession = self.deps.userSessionManager.makeUserSession(with: self.oldUserSessionData)

        when("Обновляем UserSessionData в UserSession") {
            userSession.data = self.newUserSessionData
        }

        try then("В Keychain лежит обновленная UserSessionData") {
            XCTAssertEqual(
                try XCTUnwrap(
                    self.deps.userSessionDataStorage.readUserSessionData(
                        for: .init(
                            value: self.userId
                        )
                    )
                ),
                self.newUserSessionData
            )
        }
    }

    func testUpdateDataForLoggedOutUserSessionDoesNotAffectStorage() throws {
        Allure.report(
            .init(
                name: "Обновление UserSessionData у инвалидированной UserSession, не обновляет UserSessionData в хранилищах",
                meta: self.testCaseMeta
            )
        )

        let userSession = self.deps.userSessionManager.makeUserSession(with: self.oldUserSessionData)

        given("Создаем UserSession для конкретного пользователя и выполняем у нее логаут") {
            userSession.logout(completion: { _ in })
        }

        when("Обновляем UserSessionData в UserSession") {
            userSession.data = self.newUserSessionData
        }

        then("В Keychain удалена UserSessionData для конкретного пользователя") {
            XCTAssertNil(
                try? self.deps.userSessionDataStorage.readUserSessionData(
                    for: .init(
                        value: self.userId
                    )
                )
            )
        }
    }

    func testRepeatedMakingOfSessionUpdatesDataInStorage() throws {
        Allure.report(
            .init(
                name: "Создание UserSession с новым данными для пользователя, обновляет UserSessionData в хранилищах",
                meta: self.testCaseMeta
            )
        )

        let oldUserSession = self.deps.userSessionManager.makeUserSession(with: self.oldUserSessionData)
        let newUserSession = self.deps.userSessionManager.makeUserSession(with: self.newUserSessionData)
        given("Создаем две UserSession со старой и новой UserSessionData для конкретного пользователя") {}

        try then("В Keychain, UserSession лежит обновленная UserSessionData") {
            XCTAssertEqual(
                try XCTUnwrap(
                    self.deps.userSessionDataStorage.readUserSessionData(
                        for: .init(
                            value: self.userId
                        )
                    )
                ),
                self.newUserSessionData
            )
            XCTAssertEqual(oldUserSession.data, self.newUserSessionData)
            XCTAssertTrue(oldUserSession.creationDate <= newUserSession.creationDate)
            XCTAssertEqual(
                ObjectIdentifier(newUserSession),
                ObjectIdentifier(oldUserSession)
            )
        }
    }
}
