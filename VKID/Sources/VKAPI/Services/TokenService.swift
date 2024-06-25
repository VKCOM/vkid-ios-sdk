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

internal protocol RefreshTokenService {
    func refreshAccessToken(
        by: RefreshToken,
        deviceId: String,
        completion: @escaping(Result<RefreshTokenData, TokenRefreshingError>) -> Void
    )
}

internal struct RefreshTokenData {
    let accessToken: AccessToken
    let refreshToken: RefreshToken
}

internal protocol CodeExchangingService {
    func exchangeAuthCode(
        _ code: String,
        codeVerifier: String,
        redirectUri: String,
        deviceId: String,
        completion: @escaping (Result<AuthFlowData, Error>) -> Void
    )
}

internal final class TokenService: RefreshTokenService, CodeExchangingService {
    struct Dependencies: Dependency {
        let api: VKAPI<OAuth2>
        let appCredentials: AppCredentials
    }

    /// Зависимости сервиса
    private let deps: Dependencies

    /// Инициализация сервиса обновления токенов.
    /// - Parameter deps: Зависимости.
    init(deps: Dependencies) {
        self.deps = deps
    }

    /// Обновление токенов
    func refreshAccessToken(
        by refreshToken: RefreshToken,
        deviceId: String,
        completion: @escaping (Result<RefreshTokenData, TokenRefreshingError>) -> Void
    ) {
        let state = UUID().uuidString
        self.deps
            .api
            .refreshToken
            .execute(
                with: .init(
                    refreshToken: refreshToken.value,
                    clientId: self.deps.appCredentials.clientId,
                    deviceId: deviceId,
                    state: state
                )
            ) { result in
                switch result {
                case .success(let response):
                    if state == response.state {
                        completion(
                            .success(
                                .init(
                                    accessToken: .init(from: response),
                                    refreshToken: .init(from: response)
                                )
                            )
                        )
                    } else {
                        completion(.failure(.stateMismatch))
                    }
                case .failure(.invalidRequest(reason: .invalidRefreshToken)):
                    completion(.failure(.invalidRefreshToken))
                default:
                    completion(.failure(.unknown))
                }
            }
    }

    func exchangeAuthCode(
        _ code: String,
        codeVerifier: String,
        redirectUri: String,
        deviceId: String,
        completion: @escaping (Result<AuthFlowData, Error>) -> Void
    ) {
        let state = UUID().uuidString // separate state for 'exchangeAuthCode'
        self.deps
            .api
            .exchangeAuthCode
            .execute(
                with: .init(
                    code: code,
                    codeVerifier: codeVerifier,
                    redirectUri: redirectUri,
                    state: state,
                    deviceId: deviceId,
                    clientId: self.deps.appCredentials.clientId
                )
            ) { result in
                switch result {
                case .success(let response):
                    completion(
                        state == response.state ?
                            .success(.init(from: response, serverProvidedDeviceId: deviceId)) :
                            .failure(AuthFlowError.stateMismatch)
                    )
                case .failure(let error):
                    completion(.failure(AuthFlowError.authCodeExchangingFailed(error)))
                }
            }
    }
}
