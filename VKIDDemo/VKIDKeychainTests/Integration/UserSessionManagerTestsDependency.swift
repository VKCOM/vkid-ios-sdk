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

@testable import VKID

final class UserSessionManagerTestsDependency {
    var userSessionManager: UserSessionManager!
    var legacyUserSessionManager: (any LegacyUserSessionManager)!
    var userSessionDataStorage: UserSessionDataStorage!
    var userSessionDelegateMock: UserSessionManagerDelegateMock!
    var logoutServiceMock: LogoutServiceMock!
    var refreshTokenServiceMock: RefreshTokenServiceMock!
    var userInfoServiceMock: UserInfoServiceMock!

    init() {
        self.logoutServiceMock = LogoutServiceMock()
        self.legacyUserSessionManager = LegacyUserSessionManagerImpl(
            deps: .init(
                legacyLogoutService: LegacyLogoutServiceMock(),
                logger: Entity.loggerMock,
                legacyUserSessionDataStorage: StorageImpl<LegacyUserSessionData>(
                    deps: .init(
                        keychain: Entity.keychain,
                        appCredentials: Entity.appCredentials
                    )
                )
            )
        )
        self.legacyUserSessionManager = LegacyUserSessionManagerImpl(
            deps: .init(
                legacyLogoutService: LegacyLogoutServiceMock(),
                logger: Entity.loggerMock,
                legacyUserSessionDataStorage: StorageImpl<LegacyUserSessionData>(
                    deps: .init(
                        keychain: Entity.keychain,
                        appCredentials: Entity.appCredentials
                    )
                )
            )
        )
        self.userSessionDelegateMock = UserSessionManagerDelegateMock()
        self.refreshTokenServiceMock = RefreshTokenServiceMock()
        self.userInfoServiceMock = UserInfoServiceMock()

        self.userSessionDataStorage = StorageImpl<UserSessionData>(
            deps: .init(
                keychain: Entity.keychain,
                appCredentials: Entity.appCredentials
            )
        )

        self.userSessionManager = UserSessionManagerImpl(
            deps: .init(
                logoutService: self.logoutServiceMock,
                userSessionDataStorage: self.userSessionDataStorage,
                refreshTokenService: self.refreshTokenServiceMock,
                userInfoService: self.userInfoServiceMock,
                logger: Entity.loggerMock
            )
        )
        self.userSessionManager.delegate = self.userSessionDelegateMock
    }

    deinit {
        self.logoutServiceMock = nil
        self.userSessionDelegateMock = nil

        try? self.userSessionDataStorage.removeAllUserSessionsData()

        self.userSessionDataStorage = nil
        self.userSessionManager = nil
    }
}
