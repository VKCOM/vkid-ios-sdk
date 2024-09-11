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
import XCTest
@testable import VKIDCore

final class DeviceIDTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "DeviceID"
    )
    private let userDefaultsDeviceID = UUID()
    private let keychain = Keychain()

    override func setUpWithError() throws {
        DeviceId.reset()
        try? self.keychain.delete(query: .readDeviceId)
        UserDefaults.standard.storedCurrentDeviceId = nil
    }

    func testMigrateDeviceIdFromUserDefaultsToKeychain() throws {
        Allure.report(
            .init(
                id: 2292436,
                name: "Миграция DeviceId из UserDefaults в Keychain",
                meta: self.testCaseMeta
            )
        )
        given("Задаем DeviceId") {
            UserDefaults.standard.storedCurrentDeviceId = self.userDefaultsDeviceID
        }
        try then("Проверяем что в Keychain правильный DeviceId, а UserDefaults пустой") {
            XCTAssertEqual(self.userDefaultsDeviceID.uuidString, DeviceId.currentDeviceId.description)
            guard let savedInKeychainDeviceId: String? = try keychain.fetch(query: .readDeviceId) else {
                XCTFail("Failed to update DeviceId in Keychain")
                return
            }
            XCTAssertEqual(savedInKeychainDeviceId, self.userDefaultsDeviceID.uuidString)
            XCTAssertEqual(UserDefaults.standard.storedCurrentDeviceId, nil)
        }
    }

    func testDeviceIdEqualsToIdentifierForVendor() throws {
        Allure.report(
            .init(
                id: 2292442,
                name: "DeviceId - Identifier for vendor",
                meta: self.testCaseMeta
            )
        )
        given("Получаем идентификатор вендора") {
            let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString
            then("Проверяем, что идентификатор вендора записан в DeviceId") {
                XCTAssertEqual(identifierForVendor, DeviceId.currentDeviceId.description)
            }
        }
    }

    func testUpdateDeviceId() throws {
        Allure.report(
            .init(
                id: 2349487,
                name: "Обновление DeviceId",
                meta: self.testCaseMeta
            )
        )
        try given("Создаем DeviceId") {
            let deviceId = UUID()
            try when("Сохраняем DeviceId в Keychain") {
                try self.keychain.update(deviceId, query: .deviceId, addIfNotFound: true)
                then("Проверяем, что DeviceId соответствует обновленному, а в UserDefaults пустое значение") {
                    XCTAssertEqual(deviceId.uuidString, DeviceId.currentDeviceId.description)
                    XCTAssertEqual(UserDefaults.standard.storedCurrentDeviceId, nil)
                }
            }
        }
    }
}
