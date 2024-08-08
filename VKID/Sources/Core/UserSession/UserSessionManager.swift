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

internal protocol UserSessionManager {
    var userSessions: [UserSessionImpl] { get }
    var delegate: UserSessionManagerDelegate? { get set }
    var currentAuthorizedSession: UserSession? { get }

    func makeUserSession(with data: UserSessionData) -> UserSessionImpl
    func userSession(by userId: UserID) -> UserSessionImpl?
}

internal protocol UserSessionManagerDelegate: AnyObject {
    func userSessionManager(
        _ manager: UserSessionManager,
        didLogoutFrom session: UserSessionImpl,
        with result: LogoutResult
    )

    func userSessionManager(
        _ manager: UserSessionManager,
        didRefreshAccessTokenIn session: UserSessionImpl,
        with result: TokenRefreshingResult
    )

    func userSessionManager(
        _ manager: UserSessionManager,
        didUpdateUserIn session: UserSessionImpl,
        with result: UserFetchingResult
    )
}

/// Менеджер сесcий.
internal final class UserSessionManagerImpl: UserSessionManager {
    struct Dependencies: Dependency {
        let logoutService: LogoutService
        let userSessionDataStorage: any UserSessionDataStorage
        let refreshTokenService: RefreshTokenService
        let userInfoService: UserInfoService
        let logger: Logging
    }

    private let deps: Dependencies

    private lazy var _userSessions: Synchronized<[UserSessionImpl]> = Synchronized(
        wrappedValue: self.readAllUserSessionsFromStorage()
    )

    /// Сессии пользователя.
    private(set) var userSessions: [UserSessionImpl] {
        get {
            self._userSessions.wrappedValue
        }
        set {
            self._userSessions.wrappedValue = newValue
        }
    }

    /// Последняя созданная сессия пользователя.
    internal var lastCreatedUserSession: UserSession? {
        self.userSessions
            .sorted { $0.data.creationDate > $1.data.creationDate }
            .first
    }

    internal weak var delegate: UserSessionManagerDelegate?

    internal init(deps: Dependencies) {
        self.deps = deps
    }

    /// Самая новая сессия из всех сохраненных.
    /// Это свойство вычисляемое, и будет возвращать всегда либо самую новую сессию, либо nil.
    internal var currentAuthorizedSession: UserSession? {
        self.userSessions
            .sorted { $0.creationDate > $1.creationDate }
            .first
    }

    /// Возвращает  уже существующую сессию, если она есть
    /// или создает новую и сохраняет ее в поле userSessions и хранилище keychain.
    /// - Parameter data: Данные сессии пользователя.
    /// - Returns: Экземпляр сессии.
    internal func makeUserSession(with data: UserSessionData) -> UserSessionImpl {
        if let userSessionFromStorage = self.userSession(by: data.id) {
            self.deps.logger.info("Overwriting session(\(userSessionFromStorage.creationDate))")
            self.deps.logoutService.logout(with: userSessionFromStorage.data.accessToken) { [weak self] result in
                if case .failure(let error) = result {
                    self?.deps
                        .logger
                        .info("Overwritten session(\(userSessionFromStorage.creationDate)) logout failed: \(error)")
                }
            }
            userSessionFromStorage.data = data
            return userSessionFromStorage
        }

        let newUserSession = UserSessionImpl(
            delegate: self,
            data: data,
            deps: .init(
                logoutService: self.deps.logoutService,
                refreshTokenService: self.deps.refreshTokenService,
                userInfoService: self.deps.userInfoService
            )
        )

        self.writeSessionDataToStorage(data)
        self.userSessions.append(newUserSession)

        return newUserSession
    }

    func userSession(by userId: UserID) -> UserSessionImpl? {
        self.userSessions.first(where: { $0.userId == userId })
    }

    private func writeSessionDataToStorage(_ data: UserSessionData) {
        do {
            try self.deps.userSessionDataStorage.writeUserSessionData(data)
        } catch {
            self.deps.logger.error(
                "Error while saving session to keychain storage: \(error.localizedDescription)"
            )
        }
    }

    private func removeSessionDataFromStorage(_ userId: UserID) {
        do {
            try self.deps.userSessionDataStorage.removeUserSessionData(for: userId)
        } catch {
            self.deps.logger.error(
                "Error while removing session from keychain storage: \(error.localizedDescription)"
            )
        }
    }

    private func readAllUserSessionsFromStorage() -> [UserSessionImpl] {
        do {
            return try self.deps.userSessionDataStorage.readAllUserSessionsData().map {
                UserSessionImpl(
                    delegate: self,
                    data: $0,
                    deps: .init(
                        logoutService: self.deps.logoutService,
                        refreshTokenService: self.deps.refreshTokenService,
                        userInfoService: self.deps.userInfoService
                    )
                )
            }
        } catch KeychainError.itemNotFound {
            return []
        } catch {
            self.deps.logger.error(
                "Error while reading all sessions from keychain storage: \(error.localizedDescription)"
            )
            return []
        }
    }
}

/// Обработка событий сессии
extension UserSessionManagerImpl: UserSessionDelegate {
    func userSession(
        _ session: UserSessionImpl,
        didRefreshAccessTokenWith result: Result<RefreshTokenData, TokenRefreshingError>
    ) {
        self.delegate?.userSessionManager(
            self,
            didRefreshAccessTokenIn: session,
            with: result.flatMap {
                .success(($0.accessToken, $0.refreshToken))
            }
        )
    }

    internal func userSession(_ session: UserSessionImpl, didUpdate data: UserSessionData) {
        self.writeSessionDataToStorage(data)
    }

    internal func userSession(_ session: UserSessionImpl, didLogoutWith result: LogoutResult) {
        self.mutateSessions { sessions, strongSelf in
            if case .success = result {
                strongSelf.removeSessionDataFromStorage(session.userId)
                sessions.removeFirst { $0.userId == session.userId }
                // После успешного разлогина сессия становится невалидной.
                // Поэтому, чтобы не реагировать на ее изменения, занулляем у нее ссылку на делегата.
                session.delegate = nil
            }

            strongSelf.delegate?.userSessionManager(strongSelf, didLogoutFrom: session, with: result)
        }
    }

    func userSession(_ session: UserSessionImpl, didUpdateUserWith result: Result<User, UserFetchingError>) {
        self.delegate?.userSessionManager(self, didUpdateUserIn: session, with: result)
    }

    private func mutateSessions(block: (inout [UserSessionImpl], UserSessionManagerImpl)-> Void) {
        self._userSessions.mutate { [weak self] sessions in
            guard let self else {
                return
            }
            block(&sessions, self)
        }
    }
}
