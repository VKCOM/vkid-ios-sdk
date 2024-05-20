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

import VKIDCore
import XCTest

struct SensitiveData: Codable, Equatable {
    var id = UUID()
    var value = "value"
}

final class KeychainTests: XCTestCase {
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
        let sensitiveData = SensitiveData()
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
        XCTAssertEqual(
            sensitiveData,
            self.fetchSensitiveDataFromKeychain(
                account: Keys.account,
                service: Keys.service
            )
        )
    }

    func testAddItemWithOverwrite() throws {
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
        sensitiveData.value += "123"
        try self.keychain.add(
            sensitiveData,
            query: query,
            overwriteIfAlreadyExists: true
        )

        XCTAssertEqual(
            sensitiveData,
            self.fetchSensitiveDataFromKeychain(
                account: Keys.account,
                service: Keys.service
            )
        )
    }

    func testFetchItem() throws {
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
        let fetchedData: SensitiveData? = try self.keychain.fetch(
            query: [
                .itemClass(.genericPassword),
                .accessible(.whenUnlockedThisDeviceOnly),
                .attributeAccount(Keys.account),
                .attributeService(Keys.service),
                .returnData(true),
            ]
        )

        XCTAssertEqual(sensitiveData, fetchedData)
    }

    func testUpdateNonExistingItemWithoutAdding() throws {
        XCTAssertThrowsError(
            try self.keychain.update(
                SensitiveData(),
                query: [
                    .itemClass(.genericPassword),
                    .accessible(.whenUnlockedThisDeviceOnly),
                    .attributeAccount(Keys.account),
                    .attributeService(Keys.service),
                ],
                addIfNotFound: false
            )
        )
    }

    func testUpdateExistingItem() throws {
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
        sensitiveData.value += "dsfkmsk"
        try self.keychain.update(
            sensitiveData,
            query: query,
            addIfNotFound: false
        )

        XCTAssertEqual(
            sensitiveData,
            self.fetchSensitiveDataFromKeychain(
                account: Keys.account,
                service: Keys.service
            )
        )
    }

    func testUpdateNonExistingItemWithAdding() throws {
        let sensitiveData = SensitiveData()

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

        XCTAssertEqual(
            sensitiveData,
            self.fetchSensitiveDataFromKeychain(
                account: Keys.account,
                service: Keys.service
            )
        )
    }

    func testDeleteItem() throws {
        try self.keychain.add(
            SensitiveData(),
            query: [
                .itemClass(.genericPassword),
                .accessible(.whenUnlockedThisDeviceOnly),
                .attributeAccount(Keys.account),
                .attributeService(Keys.service),
            ]
        )
        try self.keychain.delete(query: [
            .itemClass(.genericPassword),
            .accessible(.whenUnlockedThisDeviceOnly),
            .attributeAccount(Keys.account),
            .attributeService(Keys.service),
        ])

        XCTAssertNil(
            self.fetchSensitiveDataFromKeychain(
                account: Keys.account,
                service: Keys.service
            )
        )
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
