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

internal protocol LegacyUserSessionDelegate: AnyObject {
    func legacyUserSession(_ legacySession: LegacyUserSession, didLogoutWith result: LogoutResult)
}

/// Устаревшая авторизованная сессия пользователя, необходима для миграции на OAuth2.1 или логаута
public final class LegacyUserSession {
    /// Зависисмости устаревшей сессии.
    internal struct Dependencies: Dependency {
        let legacyLogoutService: LegacyLogoutService
    }

    /// Зависимости устаревшей сессии.
    private let deps: Dependencies

    /// Данные устаревшей сессии пользователя.
    internal var data: LegacyUserSessionData

    /// Идентификатор пользователя
    public var id: UserID { self.data.id }

    /// Токен доступа.
    public var accessToken: AccessToken { self.data.accessToken }

    /// Данные о пользователе.
    public var user: User? { self.data.user }

    /// Провайдер авторизации.
    public var oAuthProvider: OAuthProvider { self.data.oAuthProvider }

    /// Дата  авторизации.
    public var creationDate: Date { self.data.creationDate }

    /// Делегат устаревшей сессии.
    internal weak var delegate: LegacyUserSessionDelegate?

    /// Логаут сессии.
    /// - Parameter completion: Колбэк с результатом логаута.
    public func logout(completion: @escaping (LogoutResult) -> Void) {
        self.deps.legacyLogoutService.logout(
            accessToken: self.accessToken.value
        ) { result in
            self.delegate?.legacyUserSession(self, didLogoutWith: result)
            completion(result)
        }
    }

    internal init(
        delegate: LegacyUserSessionDelegate,
        data: LegacyUserSessionData,
        deps: Dependencies
    ) {
        self.data = data
        self.deps = deps
        self.delegate = delegate
    }
}

internal struct LegacyUserSessionData {
    ///  Id пользователя
    var id: UserID { self.accessToken.userId }
    /// Токен доступа.
    var accessToken: AccessToken
    /// Данные о пользователе.
    var user: User
    /// Провайдер авторизации.
    var oAuthProvider: OAuthProvider
    /// Дата создания данных сессии.
    var creationDate: Date
}

extension LegacyUserSessionData: Storable {
    static var storageAccessible: VKIDCore.Keychain.Query.Accessible {
        .afterFirstUnlockThisDeviceOnly
    }

    static let storageKey: String = "com.vkid.storage.userSession"
}
