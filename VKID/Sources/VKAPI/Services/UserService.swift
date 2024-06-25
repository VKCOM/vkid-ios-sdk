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

internal protocol UserInfoService {
    func fetchUserData(in session: UserSession, completion: @escaping (Result<User, UserFetchingError>) -> Void)
}

internal protocol LogoutService {
    func logout(with accessToken: AccessToken, completion: @escaping (LogoutResult) -> Void)
}

internal final class UserService: LogoutService, UserInfoService {
    struct Dependencies: Dependency {
        let api: VKAPI<OAuth2>
        let appCredentials: AppCredentials
        let deviceId: DeviceId
    }

    /// Зависимости сервиса
    private let deps: Dependencies

    /// Инициализация сервиса логаута сессии.
    /// - Parameter deps: Зависимости.
    init(deps: Dependencies) {
        self.deps = deps
    }

    /// Логаут сессии
    func logout(with accessToken: AccessToken, completion: @escaping (LogoutResult) -> Void) {
        self.deps
            .api
            .logout
            .execute(
                with: .init(
                    clientId: self.deps.appCredentials.clientId,
                    deviceId: self.deps.deviceId.description,
                    accessToken: accessToken.value
                )
            ) { result in
                switch result {
                case .success(let response):
                    completion(
                        response.isSuccess ? .success(()) : .failure(.unknown)
                    )
                case .failure(let error):
                    if case .invalidAccessToken = error {
                        completion(.failure(.invalidAccessToken))
                    } else {
                        completion(.failure(.unknown))
                    }
                }
            }
    }

    func fetchUserData(in session: UserSession, completion: @escaping (Result<User, UserFetchingError>) -> Void) {
        self.deps
            .api
            .userInfo
            .execute(
                with: .init(
                    clientId: self.deps.appCredentials.clientId,
                    deviceId: session.sessionId
                ),
                for: session.userId.value
            ) { result in
                switch result {
                case .success(let response):
                    completion(.success(.init(from: response.user, userId: session.userId)))
                case .failure(let error):
                    switch error {
                    case .invalidAccessToken:
                        completion(.failure(.invalidAccessToken))
                    default:
                        completion(.failure(.unknown))
                    }
                }
            }
    }
}
