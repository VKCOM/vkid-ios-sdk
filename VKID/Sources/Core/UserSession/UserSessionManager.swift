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
@_implementationOnly import VKIDCore

internal protocol UserSessionManager {
    var userSessions: [UserSession] { get }
    var delegate: UserSessionManagerDelegate? { get set }

    func makeUserSession(with data: UserSessionData) -> UserSession
}

internal protocol UserSessionManagerDelegate: AnyObject {
    func userSessionManager(
        _ manager: UserSessionManager,
        didLogoutFrom session: UserSession,
        with result: LogoutResult
    )
}

/// Менеджер сесиий.
internal final class UserSessionManagerImpl: UserSessionManager {
    struct Dependencies: Dependency {
        let logoutService: LogoutService
        let userSessionDataStorage: UserSessionDataStorage
        let logger: Logging
    }

    private let deps: Dependencies

    private lazy var _userSessions: Synchronized<[UserSession]> = Synchronized(
        wrappedValue: self.readAllUserSessionsFromStorage()
    )

    private(set) var userSessions: [UserSession] {
        get {
            self._userSessions.wrappedValue
        }
        set {
            self._userSessions.wrappedValue = newValue
        }
    }

    internal weak var delegate: UserSessionManagerDelegate?

    internal init(deps: Dependencies) {
        self.deps = deps
    }

    /// Возвращает  уже существующую сессию, если она есть
    /// или создает новую и сохраняет ее в поле userSessions и хранилище keychain.
    /// - Parameter data: Данные сессии пользователя.
    /// - Returns: Экземпляр сессии.
    internal func makeUserSession(with data: UserSessionData) -> UserSession {
        if let userSessionFromStorage = userSessions.first(where: { $0.user.id == data.user.id }) {
            userSessionFromStorage.data = data
            return userSessionFromStorage
        } else {
            let newUserSession = UserSession(
                delegate: self,
                data: data,
                deps: .init(
                    logoutService: self.deps.logoutService
                )
            )
            self.writeSession(newUserSession)
            return newUserSession
        }
    }

    private func writeSession(_ session: UserSession) {
        do {
            try self.deps.userSessionDataStorage.writeUserSessionData(session.data)
            self.userSessions.removeAll { $0.user.id == session.user.id }
            self.userSessions.append(session)
        } catch {
            self.deps.logger.error(
                "Error while saving session to keychain storage: \(error.localizedDescription)"
            )
        }
    }

    private func removeSession(_ session: UserSession) {
        do {
            try self.deps.userSessionDataStorage.removeUserSessionData(for: session.user.id)
            self.userSessions.removeAll { $0.user.id == session.user.id }
        } catch {
            self.deps.logger.error(
                "Error while removing session from keychain storage: \(error.localizedDescription)"
            )
        }
    }

    private func readAllUserSessionsFromStorage() -> [UserSession] {
        var userSessionsData: [UserSessionData] = []

        do {
            userSessionsData = try self.deps.userSessionDataStorage.readAllUserSessionsData()
        } catch KeychainError.itemNotFound {
            return []
        } catch {
            self.deps.logger.error(
                "Error while reading all sessions from keychain storage: \(error.localizedDescription)"
            )
        }

        return userSessionsData.map {
            UserSession(
                delegate: self,
                data: $0,
                deps: .init(
                    logoutService: self.deps.logoutService
                )
            )
        }
    }
}

/// Обработка событий сесии
extension UserSessionManagerImpl: UserSessionDelegate {
    internal func userSession(_ session: UserSession, didLogoutWith result: LogoutResult) {
        if case .success = result {
            self.removeSession(session)
        }

        self.delegate?.userSessionManager(self, didLogoutFrom: session, with: result)
    }
}
