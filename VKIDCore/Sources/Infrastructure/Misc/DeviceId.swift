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

import Foundation
import UIKit

package struct DeviceId {
    private let uuid: UUID
    private static var _deviceId: DeviceId?

    private init(uuid: UUID) {
        self.uuid = uuid
    }

    package static var currentDeviceId: Self {
        if let deviceId = Self._deviceId {
            return deviceId
        }
        let fetchedDeviceID = fetchCurrentDeviceId()
        Self._deviceId = fetchedDeviceID
        return fetchedDeviceID
    }

    internal static func reset() {
        Self._deviceId = nil
    }

    private static func fetchCurrentDeviceId() -> DeviceId {
        let ud = UserDefaults.standard
        let keychain = Keychain()

        func save(deviceId: UUID, inKeychain: Keychain) throws {
            try keychain.add(deviceId, query: .deviceId)
            ud.storedCurrentDeviceId = nil
        }

        if let deviceId = try? keychain.fetch(query: .readDeviceId).flatMap(DeviceId.init(uuid:)) {
            return deviceId
        }

        if let id = ud.storedCurrentDeviceId.flatMap(DeviceId.init(uuid:)) {
            do {
                try save(deviceId: id.uuid, inKeychain: keychain)
            } catch {
                // do nothing
            }
            return id
        } else {
            let id = DeviceId(uuid: UIDevice.current.identifierForVendor ?? UUID())
            do {
                try save(deviceId: id.uuid, inKeychain: keychain)
            } catch {
                ud.storedCurrentDeviceId = id.uuid
            }
            return id
        }
    }
}

extension DeviceId: CustomStringConvertible {
    package var description: String {
        self.uuid.uuidString
    }
}

extension UserDefaults {
    private enum Keys: String {
        case deviceId = "com.vkid.core.deviceId"
    }

    var storedCurrentDeviceId: UUID? {
        get {
            self.string(forKey: Keys.deviceId.rawValue)
                .flatMap(UUID.init(uuidString:))
        }
        set {
            self.set(
                newValue?.uuidString,
                forKey: Keys.deviceId.rawValue
            )
        }
    }
}

extension Keychain.Query {
    fileprivate enum Keys {
        static let deviceIdKey: String = "com.vkid.storage.deviceID"
    }

    internal static let deviceId: Keychain.Query = {
        [
            .itemClass(.genericPassword),
            .accessible(.afterFirstUnlockThisDeviceOnly),
            .attributeService(Keys.deviceIdKey),
        ]
    }()

    internal static let readDeviceId: Keychain.Query = {
        Keychain.Query.deviceId.appending(.returnData(true))
    }()
}
