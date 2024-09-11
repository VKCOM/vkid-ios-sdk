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
import VKIDAllureReport
import VKIDTestingInfra
import XCTest

@testable import VKID
@testable import VKIDCore

class UserFetchingTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .integration,
        product: .VKIDSDK,
        feature: "Получение данных пользователя"
    )
    private let transportMock: URLSessionTransportMock = .init()
    private let appCredentials: AppCredentials = Entity.appCredentials
    private var userSessionManager: UserSessionManager!
    private var userInfoService: UserInfoService!
    private var userSessionDataStorage: (any UserSessionDataStorage)!
    private var legacyUserSessionManager: LegacyUserSessionManager!

    override func setUpWithError() throws {
        self.userInfoService = UserService(deps:
            .init(
                api: VKAPI<OAuth2>(transport: self.transportMock),
                appCredentials: Entity.appCredentials,
                deviceId: DeviceId.currentDeviceId
            ))
        self.userSessionDataStorage = StorageImpl<UserSessionData>(
            deps: .init(
                keychain: Entity.keychain,
                appCredentials: Entity.appCredentials
            )
        )
        self.userSessionManager = UserSessionManagerImpl(deps:
            .init(
                logoutService: LogoutServiceMock(),
                userSessionDataStorage: self.userSessionDataStorage,
                refreshTokenService: RefreshTokenServiceMock(),
                userInfoService: self.userInfoService,
                logger: LoggerMock()
            ))
        self.transportMock.responseProvider = nil
    }

    override func tearDownWithError() throws {
        try? self.userSessionDataStorage.removeAllUserSessionsData()
        self.userSessionDataStorage = nil
    }

    func testInvalidAccessToken() {
        Allure.report(
            .init(
                id: 2292437,
                name: "Не валидный токен",
                meta: self.testCaseMeta
            )
        )
        given("Создание сессии и симуляция не валидного токена") {
            let sessionData = UserSessionData.random(withUserData: true)
            let session = self.userSessionManager.makeUserSession(with: sessionData)
            self.transportMock.responseProvider = { _, request -> Result<VKIDCore.VKAPIResponse, VKIDCore.VKAPIError> in
                .failure(VKAPIError.invalidAccessToken)
            }
            when("Запрос на получение пользовательских данных") {
                session.fetchUser { result in
                    then("") {
                        if case .failure(UserFetchingError.invalidAccessToken) = result {
                            // success
                        } else {
                            XCTFail("Failed to handle failed access token response")
                        }
                    }
                }
            }
        }
    }
}
