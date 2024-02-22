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

internal protocol UserSessionDelegate: AnyObject {
    func userSession(_ session: UserSession, didLogoutWith result: LogoutResult)
}

/// Авторизованная сессия пользователя.
public final class UserSession {
    /// Зависисмости сессии.
    internal struct Dependencies: Dependency {
        let logoutService: LogoutService
    }

    /// Делегат сессии.
    private weak var delegate: UserSessionDelegate?
    /// Зависимости сессии.
    private let deps: Dependencies
    /// Данные сессии пользователя.
    internal var data: UserSessionData

    /// Провайдер авторизации.
    public var oAuthProvider: OAuthProvider { self.data.oAuthProvider }
    /// Токен доступа.
    public var accessToken: AccessToken { self.data.accessToken }
    /// Данные о пользователе.
    public var user: User { self.data.user }

    /// Инициализациия сессии пользователя.
    /// - Parameters:
    ///   - delegate: Делегат сессии.
    ///   - data: Данные сессии.
    ///   - deps: Зависимости сессии.
    internal init(
        delegate: UserSessionDelegate,
        data: UserSessionData,
        deps: Dependencies
    ) {
        self.delegate = delegate
        self.data = data
        self.deps = deps
    }

    /// Логаут сессии.
    /// - Parameter completion: Колбэк с результатом логаута.
    public func logout(completion: @escaping (LogoutResult) -> Void) {
        self.deps
            .logoutService
            .logout(from: self) { [weak self] result in
                guard let self else {
                    completion(.failure(.unknown))
                    return
                }

                self.delegate?.userSession(self, didLogoutWith: result)
                completion(result)
            }
    }
}
