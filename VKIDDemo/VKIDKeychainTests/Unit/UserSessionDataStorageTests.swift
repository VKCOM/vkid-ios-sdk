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

import XCTest
@testable import VKID
@testable import VKIDAllureReport
@testable import VKIDCore

final class UserSessionDataStorageTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "Хранилище UserSessionData"
    )

    var userSessionDataStorage: UserSessionDataStorage!

    override func setUpWithError() throws {
        self.userSessionDataStorage = StorageImpl<UserSessionData>(
            deps: .init(
                keychain: Entity.keychain,
                appCredentials: Entity.appCredentials
            )
        )
    }

    override func tearDownWithError() throws {
        try? self.userSessionDataStorage.removeAllUserSessionsData()

        self.userSessionDataStorage = nil
    }

    func testWriteReadUserSessionData() throws {
        Allure.report(
            .init(
                name: "Данные сесси сохраняются в хранилище",
                meta: self.testCaseMeta
            )
        )

        let userSessionData = UserSessionData.random()

        try when("Записываем UserSessionData по UserId") {
            XCTAssertNoThrow(
                try self.userSessionDataStorage.writeUserSessionData(userSessionData)
            )
        }

        try then("При чтении по UserId, получена та же UserSessionData") {
            XCTAssertEqual(
                try self.userSessionDataStorage.readUserSessionData(
                    for: userSessionData.id
                ),
                userSessionData
            )
        }
    }

    func testReadAllUserSessionData() throws {
        Allure.report(
            .init(
                name: "Чтение всех записанных UserSessionData",
                meta: self.testCaseMeta
            )
        )

        let userSessionsData: [UserSessionData] = Array(0...3).map { UserSessionData.random(userId: $0) }

        try given("Записываем несколько UserSessionData") {
            for userSessionData in userSessionsData {
                XCTAssertNoThrow(
                    try self.userSessionDataStorage.writeUserSessionData(userSessionData)
                )
            }
        }

        try when("Считываем все UserSessionData из хранилища") {
            let userSessionsDataFromStorage = try userSessionDataStorage.readAllUserSessionsData()

            then("Прочитанные UserSessionData совпадают c записанными") {
                XCTAssertEqual(
                    userSessionsData,
                    userSessionsDataFromStorage
                )
            }
        }
    }

    func testReadNotExistedUserSessionData() throws {
        Allure.report(
            .init(
                name: "Чтение по UserId, при отсутствии UserSessionData, возвращает nil",
                meta: self.testCaseMeta
            )
        )

        let userId = UserID(value: Int.random)

        given("Хранилище пустое") {}

        try when("Чтение по userId возвращает nil") {
            XCTAssertNil(
                try self.userSessionDataStorage.readUserSessionData(for: userId)
            )
        }
    }

    func testRemoveUserSessionData() throws {
        Allure.report(
            .init(
                name: "Удаление UserSessionData по UserId",
                meta: self.testCaseMeta
            )
        )

        let userSessionData = UserSessionData.random()

        try given("Записываем UserSessionData по UserId и проверяем, что она записалась") {
            XCTAssertNoThrow(
                try self.userSessionDataStorage.writeUserSessionData(userSessionData)
            )
            XCTAssertNotNil(
                try self.userSessionDataStorage.readUserSessionData(for: userSessionData.id)
            )
        }

        try when("Удаляем UserSessionData по UserId") {
            XCTAssertNoThrow(
                try self.userSessionDataStorage.removeUserSessionData(for: userSessionData.id)
            )
        }

        try then("Считываем UserSessionData по UserId и проверяем, что возвращается nil") {
            XCTAssertNil(
                try self.userSessionDataStorage.readUserSessionData(for: userSessionData.id)
            )
        }
    }

    func testRemoveAllUserSessionData() throws {
        Allure.report(
            .init(
                name: "Удаление всех UserSessionData",
                meta: self.testCaseMeta
            )
        )

        let userSessionsData: [UserSessionData] = Array(0...3).map { UserSessionData.random(userId: $0) }

        try given("Записываем несколько UserSessionData и проверяем, что они записались") {
            for userSessionData in userSessionsData {
                XCTAssertNoThrow(
                    try self.userSessionDataStorage.writeUserSessionData(userSessionData)
                )
            }
            XCTAssertEqual(
                try self.userSessionDataStorage.readAllUserSessionsData(),
                userSessionsData
            )
        }

        try when("Удаляем все UserSessionData") {
            XCTAssertNoThrow(
                try self.userSessionDataStorage.removeAllUserSessionsData()
            )
        }

        try then("Считываем все UserSessionData и проверяем, что возвращается пустой массив") {
            XCTAssertEqual(
                try self.userSessionDataStorage.readAllUserSessionsData(), []
            )
        }
    }

    func testRemoveNotExistedUserSessionData() throws {
        Allure.report(
            .init(
                name: "Удаление несуществующей UserSessionData по UserId",
                meta: self.testCaseMeta
            )
        )

        let userId = UserID(value: Int.random)

        try when("Удаляем несуществующую UserSessionData по UserId") {
            XCTAssertThrowsError(
                try self.userSessionDataStorage.removeUserSessionData(for: userId)
            ) { error in
                then("Получена KeychainError.itemNotFound") {
                    XCTAssertEqual(
                        error as? KeychainError,
                        KeychainError.itemNotFound
                    )
                }
            }
        }
    }
}

extension KeychainError: Equatable {}
