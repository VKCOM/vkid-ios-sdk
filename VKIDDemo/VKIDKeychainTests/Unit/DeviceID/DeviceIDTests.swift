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
@testable import VKIDCore

final class DeviceIDTests: XCTestCase {
    private let userDefaultsDeviceID = UUID()
    private let keychain = Keychain()

    override func setUpWithError() throws {
        DeviceId.reset()
        try? self.keychain.delete(query: .readDeviceId)
        UserDefaults.standard.storedCurrentDeviceId = nil
    }

    func testMigrateDeviceIdFromUserDefaultsToKeychain() throws {
        // given
        UserDefaults.standard.storedCurrentDeviceId = self.userDefaultsDeviceID
        // when
        // then
        XCTAssertEqual(self.userDefaultsDeviceID.uuidString, DeviceId.currentDeviceId.description)
        XCTAssertEqual(UserDefaults.standard.storedCurrentDeviceId, nil)
    }

    func testDeviceIdEqualsToIdentifierForVendor() throws {
        // given
        // when
        // then
        XCTAssertEqual(UIDevice.current.identifierForVendor?.uuidString, DeviceId.currentDeviceId.description)
        XCTAssertEqual(UserDefaults.standard.storedCurrentDeviceId, nil)
    }

    func testFetchDeviceIdFromKeychain() throws {
        // given
        let deviceId = UUID()
        try keychain.update(deviceId, query: .deviceId, addIfNotFound: true)
        // when
        // then
        XCTAssertEqual(deviceId.uuidString, DeviceId.currentDeviceId.description)
        XCTAssertEqual(UserDefaults.standard.storedCurrentDeviceId, nil)
    }
}
