//
// Copyright (c) 2023 - present, LLC “V Kontakte”
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

struct SensitiveData: Codable, Equatable {
    var id = UUID()
    var value = "value"
}

final class KeychainTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "Keychain"
    )
    private var keychain: Keychain!

    enum Keys {
        static let account = "vkid"
        static let service = "com.vkid.keychain"
    }

    override func setUpWithError() throws {
        self.clearKeychain()
        self.keychain = Keychain()
    }

    override func tearDownWithError() throws {
        self.clearKeychain()
        self.keychain = nil
    }

    func testAddItem() throws {
        Allure.report(
            .init(
                id: 2291677,
                name: "Добавление данных в Keychain",
                meta: self.testCaseMeta
            )
        )
        try given("Создание данных") {
            let sensitiveData = SensitiveData()
            try when("Добавление записи с данными") {
                try self.keychain.add(
                    sensitiveData,
                    query: [
                        .itemClass(.genericPassword),
                        .accessible(.whenUnlockedThisDeviceOnly),
                        .attributeAccount(Keys.account),
                        .attributeService(Keys.service),
                    ],
                    overwriteIfAlreadyExists: false
                )
                then("Проверка записанных данных") {
                    XCTAssertEqual(
                        sensitiveData,
                        self.fetchSensitiveDataFromKeychain(
                            account: Keys.account,
                            service: Keys.service
                        )
                    )
                }
            }
        }
    }

    func testAddItemWithOverwrite() throws {
        Allure.report(
            .init(
                id: 2291666,
                name: "Перезаписывание данных в Keychain",
                meta: self.testCaseMeta
            )
        )
        try given("Записываем данные в Keychain") {
            let query: Keychain.Query = [
                .itemClass(.genericPassword),
                .accessible(.whenUnlockedThisDeviceOnly),
                .attributeAccount(Keys.account),
                .attributeService(Keys.service),
            ]
            var sensitiveData = SensitiveData()
            try self.keychain.add(
                sensitiveData,
                query: query,
                overwriteIfAlreadyExists: false
            )
            try when("Перезаписываем данные в Keychain") {
                sensitiveData.value += "123"
                try self.keychain.add(
                    sensitiveData,
                    query: query,
                    overwriteIfAlreadyExists: true
                )
                then("Проверяем, что данные перезаписаны правильно") {
                    XCTAssertEqual(
                        sensitiveData,
                        self.fetchSensitiveDataFromKeychain(
                            account: Keys.account,
                            service: Keys.service
                        )
                    )
                }
            }
        }
    }

    func testFetchItem() throws {
        Allure.report(
            .init(
                id: 2291676,
                name: "Получение данных из Keychain",
                meta: self.testCaseMeta
            )
        )
        try given("Записываем данные в Keychain") {
            let sensitiveData = SensitiveData()
            try self.keychain.add(
                sensitiveData,
                query: [
                    .itemClass(.genericPassword),
                    .accessible(.whenUnlockedThisDeviceOnly),
                    .attributeAccount(Keys.account),
                    .attributeService(Keys.service),
                ]
            )
            try when("Получаем данные из Keychain") {
                let fetchedData: SensitiveData? = try self.keychain.fetch(
                    query: [
                        .itemClass(.genericPassword),
                        .accessible(.whenUnlockedThisDeviceOnly),
                        .attributeAccount(Keys.account),
                        .attributeService(Keys.service),
                        .returnData(true),
                    ]
                )
                then("Проверяем данные, полученные из Keychain") {
                    XCTAssertEqual(sensitiveData, fetchedData)
                }
            }
        }
    }

    func testUpdateNonExistingItemWithoutAdding() throws {
        Allure.report(
            .init(
                id: 2291650,
                name: "Обновление не существующей записи без инициализации",
                meta: self.testCaseMeta
            )
        )
        let errorExpectation = expectation(description: "Error on failed update")
        given("Создаем данные") {
            let data = SensitiveData()
            when("Обновляем данные") {
                then("Проверяем, что выбрасывается ошибка") {
                    do {
                        try self.keychain.update(
                            data,
                            query: [
                                .itemClass(.genericPassword),
                                .accessible(.whenUnlockedThisDeviceOnly),
                                .attributeAccount(Keys.account),
                                .attributeService(Keys.service),
                            ],
                            addIfNotFound: false
                        )
                    } catch {
                        guard case KeychainError.itemNotFound = error else {
                            XCTFail("Wrong error while updating data in Keychain")
                            return
                        }
                        errorExpectation.fulfill()
                    }
                }
                wait(for: [errorExpectation], timeout: 0.1)
            }
        }
    }

    func testUpdateExistingItem() throws {
        Allure.report(
            .init(
                id: 2291672,
                name: "Обновление данных в Keychain",
                meta: self.testCaseMeta
            )
        )
        try given("Добавляем данные в Keychain") {
            var sensitiveData = SensitiveData()
            let query: Keychain.Query = [
                .itemClass(.genericPassword),
                .accessible(.whenUnlockedThisDeviceOnly),
                .attributeAccount(Keys.account),
                .attributeService(Keys.service),
            ]

            try self.keychain.add(
                sensitiveData,
                query: query,
                overwriteIfAlreadyExists: false
            )
            try when("Обновляем данные в Keychain") {
                sensitiveData.value += "dsfkmsk"
                try self.keychain.update(
                    sensitiveData,
                    query: query,
                    addIfNotFound: false
                )
                then("Проверяем, что данные обновлены верно") {
                    XCTAssertEqual(
                        sensitiveData,
                        self.fetchSensitiveDataFromKeychain(
                            account: Keys.account,
                            service: Keys.service
                        )
                    )
                }
            }
        }
    }

    func testUpdateNonExistingItemWithAdding() throws {
        Allure.report(
            .init(
                id: 2291670,
                name: "Обновление не существующей записи с инициализацией",
                meta: self.testCaseMeta
            )
        )
        try given("Создаем данные") {
            let sensitiveData = SensitiveData()
            try when("Обновляем данные с инициализацией в Keychain") {
                try self.keychain.update(
                    sensitiveData,
                    query: [
                        .itemClass(.genericPassword),
                        .accessible(.whenUnlockedThisDeviceOnly),
                        .attributeAccount(Keys.account),
                        .attributeService(Keys.service),
                    ],
                    addIfNotFound: true
                )
                then("Проверяем, что данные записаны верно") {
                    XCTAssertEqual(
                        sensitiveData,
                        self.fetchSensitiveDataFromKeychain(
                            account: Keys.account,
                            service: Keys.service
                        )
                    )
                }
            }
        }
    }

    func testDeleteItem() throws {
        Allure.report(
            .init(
                id: 2291646,
                name: "Удаление данных из Keychain",
                meta: self.testCaseMeta
            )
        )
        try given("Записываем данные в Keychain") {
            try self.keychain.add(
                SensitiveData(),
                query: [
                    .itemClass(.genericPassword),
                    .accessible(.whenUnlockedThisDeviceOnly),
                    .attributeAccount(Keys.account),
                    .attributeService(Keys.service),
                ]
            )
            try when("Удаляем данные из Keychain") {
                try self.keychain.delete(query: [
                    .itemClass(.genericPassword),
                    .accessible(.whenUnlockedThisDeviceOnly),
                    .attributeAccount(Keys.account),
                    .attributeService(Keys.service),
                ])
                then("Проверяем, что дынные удалены") {
                    XCTAssertNil(
                        self.fetchSensitiveDataFromKeychain(
                            account: Keys.account,
                            service: Keys.service
                        )
                    )
                }
            }
        }
    }
}

extension KeychainTests {
    func fetchSensitiveDataFromKeychain(
        account: String,
        service: String
    ) -> SensitiveData? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecAttrService: service,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecReturnData: kCFBooleanTrue as Any,
        ]
        var dataRef: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &dataRef)
        if let data = dataRef as? Data {
            return try? JSONDecoder().decode(SensitiveData.self, from: data)
        }
        return nil
    }

    func clearKeychain() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: Keys.account,
            kSecAttrService: Keys.service,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
