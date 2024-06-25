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
import VKIDCore

/// Авторизованная сессия пользователя.
public protocol UserSession: CustomDebugStringConvertible {
    /// Идентификатор пользователя
    var userId: UserID { get }

    /// Провайдер авторизации.
    var oAuthProvider: OAuthProvider { get }

    /// Токен доступа.
    var accessToken: AccessToken { get }

    /// Токен обновления токена доступа.
    var refreshToken: RefreshToken { get }

    /// ID токен
    var idToken: IDToken { get }

    /// Данные о пользователе.
    var user: User? { get }

    /// Дата  авторизации.
    var creationDate: Date { get }

    /// Айди сессии. Используется для вызовов API в качестве deviceId в OAuth2.1.
    var sessionId: String { get }

    /// Логаут
    /// - Parameters:
    ///   - completion: колбек с результатом получения логаута
    func logout(completion: @escaping (LogoutResult) -> Void)

    /// Метод получения свежего ```AccessToken```
    /// - Parameters:
    ///   - forceRefresh: принудительное обновление ```AccessToken```
    ///   - completion: колбек с результатом получения ```AccessToken```
    func getFreshAccessToken(
        forceRefresh: Bool,
        completion: @escaping (TokenRefreshingResult) -> Void
    )

    /// Получение пользовательских данных
    /// - Parameters:
    ///   - completion: колбек с результатом получения данных пользователя
    func fetchUser(completion: @escaping (UserFetchingResult) -> Void)
}

extension UserSession {
    /// Метод получения свежего ```AccessToken```
    ///   - completion: колбек с результатом получения ```AccessToken```
    public func getFreshAccessToken(
        completion: @escaping (TokenRefreshingResult) -> Void
    ) {
        self.getFreshAccessToken(forceRefresh: false, completion: completion)
    }
}

internal protocol UserSessionDelegate: AnyObject {
    func userSession(_ session: UserSessionImpl, didUpdate data: UserSessionData)
    func userSession(_ session: UserSessionImpl, didLogoutWith result: LogoutResult)
    func userSession(_ session: UserSessionImpl, didUpdateUserWith result: Result<User, UserFetchingError>)
    func userSession(
        _ session: UserSessionImpl,
        didRefreshAccessTokenWith result: Result<RefreshTokenData, TokenRefreshingError>
    )
}

/// Авторизованная сессия пользователя.
internal final class UserSessionImpl: UserSession {
    /// Зависисмости сессии.
    internal struct Dependencies: Dependency {
        let logoutService: LogoutService
        let refreshTokenService: RefreshTokenService
        let userInfoService: UserInfoService
    }

    /// Зависимости сессии.
    private let deps: Dependencies
    /// Данные сессии пользователя.
    internal var data: UserSessionData {
        didSet {
            if oldValue != self.data {
                self.delegate?.userSession(self, didUpdate: self.data)
            }
        }
    }

    /// Делегат сессии.
    internal weak var delegate: UserSessionDelegate?

    /// Идентификатор пользователя
    public var userId: UserID { self.data.id }

    /// Провайдер авторизации.
    public var oAuthProvider: OAuthProvider { self.data.oAuthProvider }

    /// Токен доступа.
    public var accessToken: AccessToken { self.data.accessToken }

    /// Токен обновления токена доступа.
    public var refreshToken: RefreshToken { self.data.refreshToken }

    /// ID токен
    public var idToken: IDToken { self.data.idToken }

    /// Данные о пользователе.
    public var user: User? { self.data.user }

    /// Дата  авторизации.
    public var creationDate: Date { self.data.creationDate }

    /// Айди сессии.
    public var sessionId: String { self.data.serverProvidedDeviceId }

    /// Инициализация сессии пользователя.
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
            .logout(with: self.accessToken) { [weak self] result in
                guard let self else {
                    completion(.failure(.unknown))
                    return
                }

                self.delegate?.userSession(self, didLogoutWith: result)

                completion(result)
            }
    }

    /// Метод получения `AccessToken`
    /// - Parameters:
    ///   - forceRefresh: принудительное обновление `AccessToken`, `RefreshToken`
    ///   - completion: колбек с результатом получения `AccessToken`
    public func getFreshAccessToken(
        forceRefresh: Bool = false,
        completion: @escaping (TokenRefreshingResult) -> Void
    ) {
        guard forceRefresh || self.accessToken.willExpire(in: Self.freshAccessTokenTime) else {
            completion(.success((self.accessToken, self.refreshToken)))
            return
        }
        self.deps
            .refreshTokenService
            .refreshAccessToken(
                by: self.refreshToken,
                deviceId: self.data.serverProvidedDeviceId
            ) { [weak self] result in
                guard let self else {
                    completion(.failure(.unknown))
                    return
                }
                if case .success(let refreshTokenResult) = result {
                    var data = self.data
                    data.refreshToken = refreshTokenResult.refreshToken
                    data.accessToken = refreshTokenResult.accessToken
                    self.data = data
                }
                self.delegate?.userSession(self, didRefreshAccessTokenWith: result)
                completion(
                    result
                        .map { ($0.accessToken, $0.refreshToken) }
                        .mapError { $0 }
                )
            }
    }

    /// Получение пользовательских данных
    /// - Parameters:
    ///   - completion: колбек с результатом получения данных пользователя
    public func fetchUser(completion: @escaping (UserFetchingResult) -> Void) {
        self.deps
            .userInfoService
            .fetchUserData(in: self) { result in
                if case .success(let user) = result {
                    self.data.user = user
                }
                self.delegate?.userSession(self, didUpdateUserWith: result)
                completion(result)
            }
    }
}

extension UserSessionImpl {
    /// Минимальное время жизни "свежего" аксес токена
    internal static let freshAccessTokenTime: TimeInterval = 60
}
