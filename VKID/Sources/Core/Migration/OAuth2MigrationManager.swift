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

// Ошибки миграции
public enum OAuth2MigrationError: Error {
    case invalidAccessToken
    case migrationOverdue
    case unknown
    /// ```PKCESecrets``` были предоставлены без `codeVerifier`.
    case codeVerifierNotProvided
}

/// Протокол миграции ```UserSession``` на OAuth2.1. При миграции ```AccessToken``` получит доступы, которые были выданы ранее. Если ранее доступы не выдавались, токен получит [базовое право доступа `vkid.personal_info`](https://id.vk.com/about/business/go/docs/ru/vkid/latest/vk-id/connection/api-integration/api-description#Dostup-prilozheniya-k-dannym-polzovatelya). Доступы 'phone', 'email' не входят в базовый доступ и должны запрашиваться при авторизации. [Подробнее] (https://id.vk.com/about/business/go/docs/ru/vkid/latest/vk-id/connection/ios/oauth-2.1#Nastrojka-dostupov)
public protocol OAuth2MigrationManager {
    /// Метод миграции сессии с помощью `AccessToken`
    /// - Parameters:
    ///   - byAccessToken: `AccessToken` для миграции
    ///   - oAuthProvider: провайдер авторизации
    ///   - flow: флоу авторизации
    ///   - completion: результат миграции
    func migrate(
        from legacyAccessToken: String,
        oAuthProvider: OAuthProvider,
        secrets: PKCESecrets?,
        completion: @escaping (Result<UserSession, OAuth2MigrationError>) -> Void
    )
    /// Метод миграции сессии с помощью `UserSession`
    /// - Parameters:
    ///   - byUserSession: `UserSession`  для миграции
    ///   - flow: флоу авторизации
    ///   - completion: результат миграции
    func migrate(
        from legacyUserSession: LegacyUserSession,
        secrets: PKCESecrets?,
        completion: @escaping (Result<UserSession, OAuth2MigrationError>) -> Void
    )
}

extension OAuth2MigrationManager {
    public func migrate(
        from accessToken: String,
        oAuthProvider: OAuthProvider,
        completion: @escaping (Result<UserSession, OAuth2MigrationError>) -> Void
    ) {
        self.migrate(
            from : accessToken,
            oAuthProvider: oAuthProvider,
            secrets: nil,
            completion: completion
        )
    }

    public func migrate(
        from session: LegacyUserSession,
        completion: @escaping (Result<UserSession, OAuth2MigrationError>) -> Void
    ) {
        self.migrate(
            from: session,
            secrets: nil,
            completion: completion
        )
    }
}

final class OAuth2MigrationManagerImpl: OAuth2MigrationManager, Component {
    struct Dependencies: Dependency {
        let logoutService: LogoutService
        let legacyUserSessionManager: any LegacyUserSessionManager
        let userSessionManager: UserSessionManager
        let oAuth2MigrationService: OAuth2MigrationService
        let appCredentials: AppCredentials
        let codeExchangingService: CodeExchangingService
    }

    internal let deps: Dependencies

    internal init(deps: Dependencies) {
        self.deps = deps
    }

    func migrate(
        from legacyUserSession: LegacyUserSession,
        secrets: PKCESecrets?,
        completion: @escaping (Result<UserSession, OAuth2MigrationError>) -> Void
    ) {
        if let session = self.deps
            .userSessionManager
            .userSession(by: legacyUserSession.id)
        {
            self.deps
                .legacyUserSessionManager
                .removeLegacySession(by: legacyUserSession.id)
            completion(.success(session))
            return
        }
        self.migrate(
            from: legacyUserSession.accessToken.value,
            oAuthProvider: legacyUserSession.oAuthProvider,
            secrets: secrets,
            completion: completion
        )
    }

    func migrate(
        from legacyAccessToken: String,
        oAuthProvider: OAuthProvider,
        secrets: PKCESecrets?,
        completion: @escaping (Result<UserSession, OAuth2MigrationError>) -> Void
    ) {
        self.migrate(
            token: legacyAccessToken,
            oAuthProvider: oAuthProvider,
            secrets: secrets,
            completion: completion
        )
    }

    private func migrate(
        token: String,
        oAuthProvider: OAuthProvider,
        secrets: PKCESecrets?,
        completion: @escaping (Result<UserSession, OAuth2MigrationError>) -> Void
    ) {
        do {
            let pkce = try secrets ?? (try PKCESecrets())
            guard let _ = pkce.codeVerifier else {
                completion(.failure(.codeVerifierNotProvided))
                return
            }
            let pkceWallet = PKCESecretsWallet(secrets: pkce)
            self.deps
                .oAuth2MigrationService
                .migrate(
                    accessToken: token,
                    pkceSecrets: pkceWallet
                ) { result in
                    switch result {
                    case .success(let response):
                        let codeExchanger = CodeExchanger(
                            deps: .init(
                                codeExchangingService: self.deps.codeExchangingService
                            ),
                            pkceSecrets: pkceWallet
                        )
                        do {
                            self.handle(response: response,
                                        codeExchanger: codeExchanger,
                                        oAuthProvider: oAuthProvider,
                                        codeVerifier: try pkceWallet.codeVerifier,
                                        completion: completion)
                        } catch {
                            completion(.failure(.migrationOverdue))
                        }
                    case .failure(let error):
                        if let apiError = error as? VKAPIError,
                           case VKAPIError.invalidAccessToken = apiError
                        {
                            completion(.failure(.invalidAccessToken))
                        } else {
                            completion(.failure(.unknown))
                        }
                    }
                }
        } catch {
            completion(.failure(.unknown))
        }
    }

    private func handle(
        response: AuthCodeResponse,
        codeExchanger: AuthCodeExchanging,
        oAuthProvider: OAuthProvider,
        codeVerifier: String?,
        completion: @escaping (Result<UserSession, OAuth2MigrationError>) -> Void
    ) {
        codeExchanger.exchangeAuthCode(
            .init(
                from: response,
                codeVerifier: codeVerifier,
                redirectURI: "vk\(self.deps.appCredentials.clientId)://vk.com/blank.html"
            )
        ) { result in
            switch result {
            case .success(let authFlowData):
                self.deps
                    .legacyUserSessionManager
                    .removeLegacySession(by: authFlowData.accessToken.userId)
                if let _ = self.deps
                    .userSessionManager
                    .userSession(by: authFlowData.accessToken.userId)
                {
                    let updatedSession = self.deps.userSessionManager.makeUserSession(
                        with: .init(from: authFlowData, oAuthProvider: oAuthProvider)
                    )
                    completion(.success(updatedSession))
                    return
                }
                let session = self.deps.userSessionManager.makeUserSession(with:
                    .init(
                        id: authFlowData.accessToken.userId,
                        oAuthProvider: oAuthProvider,
                        accessToken: authFlowData.accessToken,
                        refreshToken: authFlowData.refreshToken,
                        idToken: authFlowData.idToken,
                        serverProvidedDeviceId: authFlowData.deviceId
                    ))
                completion(.success(session))
            case .failure:
                completion(.failure(.unknown))
            }
        }
    }
}
