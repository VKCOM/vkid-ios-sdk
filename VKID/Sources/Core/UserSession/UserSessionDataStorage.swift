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

import Foundation
import VKIDCore

protocol Storable: Equatable, Codable {
    var id: UserID { get }
    static var storageKey: String { get }
    static var storageAccessible: Keychain.Query.Accessible { get }
}

extension Storable {
    var storageKey: String {
        type(of: self).storageKey
    }
}

internal protocol Storage<T> {
    associatedtype T: Storable
    func readUserSessionData(for userId: UserID) throws -> T?
    func readAllUserSessionsData() throws -> [T]
    func writeUserSessionData(_ data: T) throws
    func removeUserSessionData(for userId: UserID) throws
    func removeAllUserSessionsData() throws
}

typealias UserSessionDataStorage = Storage<UserSessionData>
typealias LegacyUserSessionDataStorage = Storage<LegacyUserSessionData>

typealias UserSessionDataStorageImpl = StorageImpl<UserSessionData>
typealias LegacyUserSessionDataStorageImpl = StorageImpl<LegacyUserSessionData>

internal final class StorageImpl<U: Storable>: Storage {
    /// Зависимости хранилища
    internal struct Dependencies: Dependency {
        let keychain: Keychain
        let appCredentials: AppCredentials
    }

    /// Зависимости хранилища
    private let deps: Dependencies

    /// Идентификатор клиента
    private var clientId: String {
        self.deps.appCredentials.clientId
    }

    /// Инициализация хранилища
    /// - Parameter deps: Зависимости хранилища
    init(deps: Dependencies) {
        self.deps = deps
    }

    func readUserSessionData(for userId: UserID) throws -> U? {
        do {
            return try self.deps.keychain.fetch(
                query: .userSessionRead(
                    for: userId.asString,
                    with: self.deps.appCredentials.clientId,
                    forType: U.self
                )
            )
        } catch KeychainError.itemNotFound {
            return nil
        }
    }

    func readAllUserSessionsData() throws -> [U] {
        do {
            return try self.deps.keychain.fetchMany(
                query: .userSessionRead(
                    with: self.clientId,
                    forType: U.self
                )
            ) ?? []
        } catch KeychainError.itemNotFound {
            return []
        }
    }

    func writeUserSessionData(_ data: U) throws {
        try self.deps.keychain.add(
            data,
            query: .userSessionWrite(
                for: data.id.asString,
                with: self.clientId,
                forType: U.self
            )
        )
    }

    func removeUserSessionData(for userId: UserID) throws {
        try self.deps.keychain.delete(
            query: .userSessionWrite(
                for: userId.asString,
                with: self.clientId,
                forType: U.self
            )
        )
    }

    func removeAllUserSessionsData() throws {
        try self.deps.keychain.delete(
            query: .userSession(with: self.clientId, forType: U.self)
        )
    }
}

extension UserID {
    fileprivate var asString: String {
        String(value)
    }
}

extension Keychain.Query {
    /// Кейчейн Query для формирования данных по идентификатору клиента
    fileprivate static func userSession<U: Storable>(with clientId: String, forType: U.Type) -> Keychain.Query {
        [
            .itemClass(.genericPassword),
            .accessible(U.storageAccessible),
            .attributeService(
                [U.storageKey, clientId].joined(separator: ".")
            ),
        ]
    }

    /// Кейчейн Query для записи данных по идентификатору пользователя и клиента
    fileprivate static func userSessionWrite<U: Storable>(
        for userId: String,
        with clientId: String,
        forType: U.Type
    ) -> Keychain.Query {
        Self.userSession(with: clientId, forType: U.self).appending(
            .attributeAccount(userId)
        )
    }

    /// Кейчейн Query для чтения данных по идентификатору клиента
    fileprivate static func userSessionRead<U: Storable>(with clientId: String, forType: U.Type) -> Keychain.Query {
        Self.userSession(with: clientId, forType: U.self).appending(
            [
                .matchLimit(.all),
                .returnData(true),
            ]
        )
    }

    /// Кейчейн Query для чтееия данных по идентификатору пользователя и клиента
    fileprivate static func userSessionRead<U: Storable>(
        for userId: String,
        with clientId: String,
        forType: U.Type
    ) -> Keychain.Query {
        Self.userSessionWrite(for: userId, with: clientId, forType: U.self).appending(
            .returnData(true)
        )
    }
}
