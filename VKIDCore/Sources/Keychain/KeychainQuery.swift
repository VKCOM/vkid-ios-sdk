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
import Security

internal protocol KeychainQueryDictionaryRepresentable {
    var dictionaryRepresentation: [CFString: Any] { get }
}

extension Keychain {
    public struct Query: KeychainQueryDictionaryRepresentable, ExpressibleByArrayLiteral {
        private var items: [Item]

        var dictionaryRepresentation: [CFString : Any] {
            self.items.reduce(into: [CFString: Any]()) { result, item in
                result.merge(item.dictionaryRepresentation) { _, new in new }
            }
        }

        public init(items: [Item]) {
            self.items = items
        }

        public init(arrayLiteral elements: Item...) {
            self.init(items: elements)
        }

        public mutating func append(_ item: Item) {
            self.items.append(item)
        }

        public func appending(_ item: Item) -> Self {
            self.appending([item])
        }

        public func appending(_ items: [Item]) -> Self {
            Self(items: self.items + items)
        }
    }
}

extension Keychain.Query {
    public struct Item: KeychainQueryDictionaryRepresentable {
        private let key: CFString
        private let value: Any

        fileprivate init(key: CFString, value: Any) {
            self.key = key
            self.value = value
        }

        var dictionaryRepresentation: [CFString: Any] {
            [self.key: self.value]
        }
    }
}

extension Keychain.Query.Item {
    public static func itemClass(_ cls: Keychain.Query.ItemClass) -> Keychain.Query.Item {
        .init(key: kSecClass, value: cls.rawValue)
    }

    public static func attributeAccount(_ account: String) -> Keychain.Query.Item {
        .init(key: kSecAttrAccount, value: account)
    }

    public static func attributeService(_ service: String) -> Keychain.Query.Item {
        .init(key: kSecAttrService, value: service)
    }

    public static func returnData(_ flag: Bool) -> Keychain.Query.Item {
        .init(
            key: kSecReturnData,
            value: (flag ? kCFBooleanTrue : kCFBooleanFalse) as Any
        )
    }

    public static func accessible(_ attr: Keychain.Query.Accessible) -> Keychain.Query.Item {
        .init(key: kSecAttrAccessible, value: attr.rawValue)
    }

    public static func matchLimit(_ limit: Keychain.Query.MatchLimit) -> Keychain.Query.Item {
        .init(key: kSecMatchLimit, value: limit.rawValue)
    }

    public static func valueData(_ data: Data) -> Keychain.Query.Item {
        .init(key: kSecValueData, value: data)
    }

    public static func accessGroup(_ group: String) -> Keychain.Query.Item {
        .init(key: kSecAttrAccessGroup, value: group)
    }
}

extension Keychain.Query {
    public struct ItemClass: RawRepresentable {
        public private(set) var rawValue: CFString

        public init(rawValue: CFString) {
            self.rawValue = rawValue
        }

        public static let genericPassword = Self(rawValue: kSecClassGenericPassword)
        public static let internetPassword = Self(rawValue: kSecClassInternetPassword)
        public static let certificate = Self(rawValue: kSecClassCertificate)
    }

    public struct Accessible: RawRepresentable {
        public private(set) var rawValue: CFString

        public init(rawValue: CFString) {
            self.rawValue = rawValue
        }

        public static let whenUnlocked = Self(rawValue: kSecAttrAccessibleWhenUnlocked)
        public static let afterFirstUnlock = Self(rawValue: kSecAttrAccessibleAfterFirstUnlock)
        public static let whenUnlockedThisDeviceOnly = Self(rawValue: kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
        public static let afterFirstUnlockThisDeviceOnly =
            Self(rawValue: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
    }

    public struct MatchLimit: RawRepresentable {
        public private(set) var rawValue: CFString

        public init(rawValue: CFString) {
            self.rawValue = rawValue
        }

        public static let one = Self(rawValue: kSecMatchLimitOne)
        public static let all = Self(rawValue: kSecMatchLimitAll)
    }
}
