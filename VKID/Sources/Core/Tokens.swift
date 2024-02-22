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

public protocol Expiring {
    var expirationDate: Date { get }
    var isExpired: Bool { get }

    func willExpire(in interval: TimeInterval) -> Bool
}

extension Expiring {
    public var isExpired: Bool {
        self.willExpire(in: 0)
    }

    public func willExpire(in interval: TimeInterval) -> Bool {
        expirationDate.addingTimeInterval(interval) <= Date()
    }
}

/// Токен авторизации запросов
///
///  Данный токен необходим для вызова методов API после того, как пользователь авторизовался с помощью VK ID в вашем сервисе.
///  [Access token](https://id.vk.com/about/business/go/docs/ru/vkid/latest/vk-id/tokens/access-token)
///  — это подпись пользователя в вашем приложении.Он сообщает серверу, от имени какого пользователя осуществляются запросы
///  и какие права доступа пользователь выдал вашему приложению.
public struct AccessToken: Expiring, Equatable, Codable {
    public let userId: UserID
    public let value: String
    public let expirationDate: Date

    public init(userId: UserID, value: String, expirationDate: Date) {
        self.userId = userId
        self.value = value
        self.expirationDate = expirationDate
    }
}

/// Уникальный идентификатор пользователя VKID
public struct UserID: Equatable, Hashable, Codable {
    public let value: Int

    public init(value: Int) {
        self.value = value
    }
}

/// Анонимный токен для запросов в неавторизованной зоне
public struct AnonymousToken: Expiring, Codable {
    public let value: String
    public let expirationDate: Date

    public init(value: String, expirationDate: Date) {
        self.value = value
        self.expirationDate = expirationDate
    }
}
