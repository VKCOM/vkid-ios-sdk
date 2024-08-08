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

internal protocol LegacyUserSessionManager {
    var legacyUserSessions: [LegacyUserSession] { get }
    func removeLegacySession(by id: UserID)
}

internal final class LegacyUserSessionManagerImpl: LegacyUserSessionManager {
    struct Dependencies: Dependency {
        let legacyLogoutService: LegacyLogoutService
        let logger: Logging
        let legacyUserSessionDataStorage: any LegacyUserSessionDataStorage
    }

    private let deps: Dependencies

    init(deps: Dependencies) {
        self.deps = deps
    }

    private lazy var _legacyUserSessions: Synchronized<[LegacyUserSession]> = Synchronized(
        wrappedValue: self.readAllLegacyUserSessionsFromStorage()
    )

    private(set) var legacyUserSessions: [LegacyUserSession] {
        get {
            self._legacyUserSessions.wrappedValue
        }
        set {
            self._legacyUserSessions.wrappedValue = newValue
        }
    }

    internal func removeLegacySession(by id: UserID) {
        self._legacyUserSessions.mutate { legacySessions in
            do {
                try self.deps.legacyUserSessionDataStorage.removeUserSessionData(for: id)
            } catch {
                self.deps.logger.error(
                    "Error while removing legacy session from keychain storage: \(error.localizedDescription)"
                )
            }
            legacySessions.removeAll(where: { $0.data.id == id })
        }
    }

    private func readAllLegacyUserSessionsFromStorage() -> [LegacyUserSession] {
        do {
            return try self.deps.legacyUserSessionDataStorage.readAllUserSessionsData()
                .map {
                    LegacyUserSession(
                        delegate: self,
                        data: $0,
                        deps: .init(
                            legacyLogoutService: self.deps.legacyLogoutService
                        )
                    )
                }
        } catch KeychainError.itemNotFound {
            return []
        } catch {
            self.deps.logger.error(
                "Error while reading all legacy sessions from keychain storage: \(error.localizedDescription)"
            )
            return []
        }
    }
}

extension LegacyUserSessionManagerImpl: LegacyUserSessionDelegate {
    func legacyUserSession(_ legacySession: LegacyUserSession, didLogoutWith result: LogoutResult) {
        if case .success = result {
            self.removeLegacySession(by: legacySession.id)
        }
    }
}
