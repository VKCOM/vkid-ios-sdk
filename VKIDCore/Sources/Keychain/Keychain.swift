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

public enum KeychainError: Error {
    case unknown
    case itemNotFound
    case itemEncodingFailed(Error)
    case itemDecodingFailed(Error)
    case generic(OSStatus)

    internal init(with status: OSStatus) {
        switch status {
        case errSecItemNotFound:
            self = .itemNotFound
        default:
            self = .generic(status)
        }
    }
}

public final class Keychain {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init() {}

    public func add<T: Encodable>(
        _ item: T,
        query: Keychain.Query,
        overwriteIfAlreadyExists: Bool = true
    ) throws {
        do {
            let itemData = try self.encoder.encode(item)
            let rawQuery = query
                .appending(.valueData(itemData))
                .dictionaryRepresentation as CFDictionary
            if overwriteIfAlreadyExists {
                try? self.withCheckingStatus(SecItemDelete(rawQuery))
            }
            try self.withCheckingStatus(SecItemAdd(rawQuery, nil))
        } catch let e as EncodingError {
            throw KeychainError.itemEncodingFailed(e)
        } catch let e as KeychainError {
            throw e
        } catch {
            throw KeychainError.unknown
        }
    }

    public func update<T: Encodable>(
        _ item: T,
        query: Keychain.Query,
        addIfNotFound: Bool = false
    ) throws {
        do {
            let itemData = try self.encoder.encode(item)
            let attributesToUpdate =
                Keychain
                    .Query
                    .Item
                    .valueData(itemData).dictionaryRepresentation as CFDictionary
            let rawQuery = query.dictionaryRepresentation as CFDictionary
            try self.withCheckingStatus(SecItemUpdate(rawQuery, attributesToUpdate))
        } catch let e as EncodingError {
            throw KeychainError.itemEncodingFailed(e)
        } catch KeychainError.itemNotFound where addIfNotFound {
            try self.add(item, query: query, overwriteIfAlreadyExists: false)
        } catch let e as KeychainError {
            throw e
        } catch {
            throw KeychainError.unknown
        }
    }

    public func fetch<T: Decodable>(query: Keychain.Query) throws -> T? {
        let rawQuery = query.dictionaryRepresentation as CFDictionary
        var dataRef: AnyObject?
        try self.withCheckingStatus(SecItemCopyMatching(rawQuery, &dataRef))

        guard let data = dataRef as? Data else {
            return nil
        }

        return try self.decode(from: data)
    }

    public func fetchMany<T: Decodable>(query: Keychain.Query) throws -> [T]? {
        let rawQuery = query.dictionaryRepresentation as CFDictionary
        var dataRef: AnyObject?
        try self.withCheckingStatus(SecItemCopyMatching(rawQuery, &dataRef))

        guard let data = dataRef as? [Data] else {
            return nil
        }

        var result: [T] = []

        for item in data {
            result.append(
                try self.decode(from: item)
            )
        }
        return result
    }

    public func delete(query: Keychain.Query) throws {
        try self.withCheckingStatus(SecItemDelete(query.dictionaryRepresentation as CFDictionary))
    }

    private func decode<T: Decodable>(from data: Data) throws -> T {
        do {
            let item = try self.decoder.decode(T.self, from: data)
            return item
        } catch {
            throw KeychainError.itemDecodingFailed(error)
        }
    }

    private func withCheckingStatus(_ op: @autoclosure () -> OSStatus) throws {
        let status = op()
        if status != errSecSuccess {
            throw KeychainError(with: status)
        }
    }
}
