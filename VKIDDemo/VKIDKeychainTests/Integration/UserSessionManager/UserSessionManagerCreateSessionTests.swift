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

final class UserSessionManagerCreateSessionTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .integration,
        product: .VKIDSDK,
        feature: "Создание сессий в UserSessionManager"
    )

    var deps: UserSessionManagerTestsDependency!

    override func setUpWithError() throws {
        self.deps = UserSessionManagerTestsDependency()
    }

    override func tearDownWithError() throws {
        self.deps = nil
    }

    func testCreatedUserSessionsIsStoredInKeychainAndManager() throws {
        Allure.report(
            .init(
                id: 2292390,
                name: "Созданные UserSession хранятся в Keychain и UserSessionManager",
                meta: self.testCaseMeta
            )
        )

        let usersCount = 5
        let actualUserIds = (0..<usersCount)
        let actualUserSessionsData = actualUserIds.map { UserSessionData.random(userId: $0) }

        try when("Создаем UserSessions через UserSessionManager") {
            let actualUserSessions = actualUserSessionsData.map {
                self.deps.userSessionManager.makeUserSession(with: $0)
            }

            let userSessionsDataFromKeychainStorage = try XCTUnwrap(
                self.deps.userSessionDataStorage.readAllUserSessionsData()
            )

            let actualUserSessionsIdentifiers = actualUserSessions.map { ObjectIdentifier($0) }

            then("Проверяем, что UserSessions из Keychain и UserSessionManager совпадают с записанными") {
                XCTAssertEqual(
                    userSessionsDataFromKeychainStorage,
                    actualUserSessionsData
                )
                XCTAssertEqual(
                    self.deps.userSessionManager.userSessions.map { $0.data },
                    actualUserSessionsData
                )
                XCTAssertEqual(
                    self.deps.userSessionManager.userSessions.map { ObjectIdentifier($0) },
                    actualUserSessionsIdentifiers
                )
            }
        }
    }
}
