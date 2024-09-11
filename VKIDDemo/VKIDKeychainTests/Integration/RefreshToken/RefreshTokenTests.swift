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

import VKIDAllureReport
import VKIDTestingInfra
import XCTest

@testable import VKID
@testable import VKIDCore

final class UserSessionRefreshTokenTests: XCTestCase {
    private let transportMock: URLSessionTransportMock = .init()
    private let appCredentials: AppCredentials = Entity.appCredentials
    private var refreshTokenService: RefreshTokenService!
    private var userSessionManager: UserSessionManager!
    private var userInfoServiceMock: UserInfoService = UserInfoServiceMock()
    private var userSessionDataStorage: (any UserSessionDataStorage)!
    private var legacyUserSessionManager: LegacyUserSessionManager!
    private var userSessionManagerDelegateMock: UserSessionManagerDelegateMock!

    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .integration,
        product: .VKIDSDK,
        feature: "Рефреш токена"
    )

    override func setUpWithError() throws {
        self.refreshTokenService = TokenService(
            deps: .init(
                api: VKAPI<OAuth2>(transport: self.transportMock),
                appCredentials: self.appCredentials
            )
        )
        self.userSessionDataStorage = StorageImpl<UserSessionData>(
            deps: .init(
                keychain: Entity.keychain,
                appCredentials: Entity.appCredentials
            )
        )
        self.legacyUserSessionManager = LegacyUserSessionManagerImpl(
            deps: .init(
                legacyLogoutService: LegacyLogoutServiceStub(),
                logger: Entity.loggerMock,
                legacyUserSessionDataStorage: StorageImpl<LegacyUserSessionData>(
                    deps: .init(
                        keychain: Entity.keychain,
                        appCredentials: Entity.appCredentials
                    )
                )
            )
        )
        self.userSessionManager = UserSessionManagerImpl(
            deps: .init(
                logoutService: LogoutServiceMock(),
                userSessionDataStorage: self.userSessionDataStorage,
                refreshTokenService: self.refreshTokenService,
                userInfoService: self.userInfoServiceMock,
                logger: LoggerMock()
            )
        )
        self.userSessionManagerDelegateMock = UserSessionManagerDelegateMock()
        self.userSessionManager.delegate = self.userSessionManagerDelegateMock
        self.transportMock.responseProvider = nil
    }

    override func tearDownWithError() throws {
        try? self.userSessionDataStorage.removeAllUserSessionsData()
        self.userSessionDataStorage = nil
        self.refreshTokenService = nil
        self.userSessionDataStorage = nil
        self.legacyUserSessionManager = nil
        self.userSessionManager = nil
    }

    func testRefreshTokenMissing() {
        Allure.report(
            .init(
                id: 2313656,
                name: "РТ просрочился или невалидный",
                meta: self.testCaseMeta
            )
        )
        var session: UserSession!
        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 3
        given("Создание сессии") {
            let encodedString =
                "{\"accessToken\":{\"value\":\"9B8494E3-54BF-47F6-ADF2-EFFAB1B21AA9\",\"expirationDate\":731966387.422122,\"userId\":{\"value\":6817500562519052877}},\"refreshToken\":{\"value\":\"\",\"userId\":{\"value\":6817500562519052877}},\"id\":{\"value\":6817500562519052877},\"creationDate\":731966387.422294,\"oAuthProvider\":{\"type\":\"vkid\"},\"idToken\":{\"value\":\"SOME_ID_TOKEN\",\"userId\":{\"value\":6817500562519052877}},\"serverProvidedDeviceId\":\"testServerProvidedDeviceId\"}"
            let baseData = try! JSONDecoder().decode(UserSessionData.self, from: encodedString.data(using: .utf8)!)
            session = self.userSessionManager.makeUserSession(with: baseData)
            self.userSessionManagerDelegateMock.didRefreshToken = { manager, session, result in
                guard
                    case .failure(.invalidRefreshToken) = result
                else {
                    XCTFail("Wrong manager delegate's result")
                    return
                }
                expectation.fulfill()
            }
            self.transportMock.responseProvider = { _, request -> Result<VKIDCore.VKAPIResponse, VKIDCore.VKAPIError> in
                expectation.fulfill()
                return .failure(.invalidRequest(reason: .invalidRefreshToken))
            }
        }
        when("Получение токена") {
            session.getFreshAccessToken(forceRefresh: true) { result in
                then("Проверка ошибки обновления токена") {
                    if case .failure(.invalidRefreshToken) = result {
                        expectation.fulfill()
                        XCTAssertEqual(session.accessToken.value, "9B8494E3-54BF-47F6-ADF2-EFFAB1B21AA9")
                    } else {
                        XCTFail("refreshing without refresh token\(result)")
                    }
                }
            }
            self.wait(for: [expectation], timeout: 0.1)
        }
    }

    func testRefreshTokenFailed() {
        Allure.report(
            .init(
                id: 2313657,
                name: "Ошибка обновления токена - фейл запроса",
                meta: self.testCaseMeta
            )
        )
        var session: UserSession!
        let expectation = self.expectation(description: #function)
        given("Создание сессии") {
            let baseData = UserSessionData.random(withUserData: false)
            session = self.userSessionManager.makeUserSession(with: baseData)
            self.transportMock.responseProvider = { _, request -> Result<VKIDCore.VKAPIResponse, VKIDCore.VKAPIError> in
                .failure(.unknown)
            }
        }
        when("Получение токена") {
            session.getFreshAccessToken(forceRefresh: true) { result in
                then("Проверка ошибки обновления токена") {
                    if case .failure(.unknown) = result {
                        expectation.fulfill()
                    } else {
                        XCTFail("refreshed successfully with failed request")
                    }
                }
            }
            self.wait(for: [expectation], timeout: 0.1)
        }
    }
}

extension OAuth2.RefreshToken.Response {
    fileprivate static func create(
        userSessionData data: UserSessionData,
        state: String
    ) -> OAuth2.RefreshToken.Response {
        .init(
            refreshToken: data.refreshToken.value,
            accessToken: data.accessToken.value,
            state: state,
            expiresIn: 3600,
            userId: data.id.value,
            scope: ""
        )
    }
}
