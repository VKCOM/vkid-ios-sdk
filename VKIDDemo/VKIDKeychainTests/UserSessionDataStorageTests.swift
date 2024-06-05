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
@testable import VKIDCore

final class UserSessionDataStorageTests: XCTestCase {
    enum Entity {
        static let appCredentials = AppCredentials(
            clientId: UUID().uuidString,
            clientSecret: UUID().uuidString
        )

        static let keychain = Keychain()
    }

    var userSessionDataStorage: UserSessionDataStorage!

    override func setUpWithError() throws {
        self.userSessionDataStorage = UserSessionDataStorageImpl(
            deps: .init(
                keychain: Entity.keychain,
                appCredentials: Entity.appCredentials
            )
        )
        try? self.userSessionDataStorage.removeAllUserSessionsData()
    }

    func testWriteUserSessionData() throws {
        // given
        let userSessionData = makeUserSessionData()

        // when / then
        XCTAssertNoThrow(
            try self.userSessionDataStorage.writeUserSessionData(userSessionData)
        )
    }

    func testReadUserSessionData() throws {
        // given
        let userSessionData = makeUserSessionData()

        XCTAssertNoThrow(
            try self.userSessionDataStorage.writeUserSessionData(userSessionData)
        )

        // when
        let userSessionDataFromStorage = try userSessionDataStorage.readUserSessionData(for: userSessionData.user.id)

        // then
        XCTAssertEqual(userSessionData, userSessionDataFromStorage)
    }

    func testReadNotExistedUserSessionData() throws {
        // given
        let userId = UserID(value: Int.random)

        // when / then
        XCTAssertThrowsError(
            try self.userSessionDataStorage.readUserSessionData(for: userId)
        )
    }

    func testReadAllUserSessionData() throws {
        // given
        let userSessionsData: [UserSessionData] = Array(0...3).map { makeUserSessionData(userId: $0) }

        for userSessionData in userSessionsData {
            XCTAssertNoThrow(
                try self.userSessionDataStorage.writeUserSessionData(userSessionData)
            )
        }

        // when
        let userSessionsDataFromStorage = try userSessionDataStorage.readAllUserSessionsData()

        // then
        XCTAssertEqual(
            userSessionsData.sorted { $0.creationDate > $1.creationDate },
            userSessionsDataFromStorage.sorted { $0.creationDate > $1.creationDate }
        )
    }

    func testRemoveNotExistedUserSessionData() throws {
        // given
        let userId = UserID(value: Int.random)

        // when / then
        XCTAssertThrowsError(
            try self.userSessionDataStorage.removeUserSessionData(for: userId)
        )
    }

    func testRemoveUserSessionData() throws {
        // given
        let userSessionData = makeUserSessionData()

        XCTAssertNoThrow(
            try self.userSessionDataStorage.writeUserSessionData(userSessionData)
        )

        // when
        XCTAssertNoThrow(
            try self.userSessionDataStorage.removeUserSessionData(for: userSessionData.user.id)
        )

        // then
        XCTAssertThrowsError(
            try self.userSessionDataStorage.readAllUserSessionsData()
        )
    }

    func testRemoveAllUserSessionData() throws {
        // given
        let userSessionsData: [UserSessionData] = Array(0...3).map { makeUserSessionData(userId: $0) }

        for userSessionData in userSessionsData {
            XCTAssertNoThrow(
                try self.userSessionDataStorage.writeUserSessionData(userSessionData)
            )
        }

        // when
        XCTAssertNoThrow(
            try self.userSessionDataStorage.removeAllUserSessionsData()
        )

        // then
        XCTAssertThrowsError(
            try self.userSessionDataStorage.readAllUserSessionsData()
        )
    }
}

extension UserSessionDataStorageTests {
    func makeUserSessionData(userId: Int = Int.random) -> UserSessionData {
        let userId = UserID(value: userId)

        return UserSessionData(
            oAuthProvider: .vkid,
            accessToken: self.makeAccessToken(userId: userId),
            user: self.makeUser(userId: userId)
        )
    }

    func makeAccessToken(userId: UserID) -> AccessToken {
        AccessToken(
            userId: userId,
            value: UUID().uuidString,
            expirationDate: Date()
        )
    }

    func makeUser(userId: UserID) -> User {
        User(
            id: userId,
            firstName: UUID().uuidString,
            lastName: UUID().uuidString,
            email: nil,
            phone: nil,
            avatarURL: nil
        )
    }
}
