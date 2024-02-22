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
@_implementationOnly import VKIDCore

internal protocol AnonymousTokenService {
    func getFreshToken(
        forceRefresh: Bool,
        completion: @escaping (Result<AnonymousToken, Error>) -> Void
    )
}

extension AnonymousTokenService {
    internal func getFreshToken(
        completion: @escaping (Result<AnonymousToken, Error>) -> Void
    ) {
        self.getFreshToken(forceRefresh: false, completion: completion)
    }
}

internal final class AnonymousTokenServiceImpl: AnonymousTokenService {
    private let keychain: Keychain
    private let api: VKAPI<OAuth>
    private let credentials: AppCredentials

    @Synchronized
    private var _cachedToken: AnonymousToken?

    internal init(
        keychain: Keychain,
        api: VKAPI<OAuth>,
        credentials: AppCredentials
    ) {
        self.keychain = keychain
        self.api = api
        self.credentials = credentials
    }

    func getFreshToken(
        forceRefresh: Bool,
        completion: @escaping (Result<AnonymousToken, Error>) -> Void
    ) {
        if
            !forceRefresh,
            let token = try? self.cachedToken,
            !token.willExpire(in: .minute)
        {
            completion(.success(token))
            return
        }
        self.api
            .getAnonymousToken
            .execute(
                with: .init(
                    anonymousToken: try? self.cachedToken?.value,
                    clientId: self.credentials.clientId,
                    clientSecret: self.credentials.clientSecret
                )
            ) { result in
                switch result {
                case .success(let response):
                    let token = AnonymousToken(
                        value: response.token,
                        expirationDate: response.expiredAt
                    )
                    try? self.cacheToken(token)
                    completion(.success(token))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    private var cachedToken: AnonymousToken? {
        get throws {
            try self.__cachedToken.mutate {
                if $0 == nil {
                    $0 = try self.keychain.fetch(
                        query: .anonymousTokenRead(for: self.credentials.clientId)
                    )
                }
                return $0
            }
        }
    }

    private func cacheToken(_ token: AnonymousToken?) throws {
        try self.__cachedToken.mutate {
            $0 = token
            if let token {
                try self.keychain.update(
                    token,
                    query: .anonymousTokenWrite(for: self.credentials.clientId),
                    addIfNotFound: true
                )
            } else {
                try self.keychain.delete(
                    query: .anonymousTokenRead(for: self.credentials.clientId)
                )
            }
        }
    }
}

extension Keychain.Query {
    fileprivate static func anonymousTokenWrite(for clientId: String) -> Keychain.Query {
        [
            .itemClass(.genericPassword),
            .attributeAccount(clientId),
            .attributeService("com.vkid.services.anonymousToken"),
            .accessible(.afterFirstUnlockThisDeviceOnly),
        ]
    }

    fileprivate static func anonymousTokenRead(for clientId: String) -> Keychain.Query {
        Self.anonymousTokenWrite(for: clientId).appending(.returnData(true))
    }
}

extension TimeInterval {
    fileprivate static let minute: TimeInterval = 60
}
