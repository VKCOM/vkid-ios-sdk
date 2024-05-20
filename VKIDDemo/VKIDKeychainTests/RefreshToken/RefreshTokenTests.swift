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

import VKIDCore
import XCTest
@testable import VKID

final class RefreshTokenTest: XCTestCase {
    private let transportMock: TransportMock = .init()
    private let appCredentials: AppCredentials = Entity.appCredentials
    private var refreshTokenService: RefreshTokenService!
    private var userSessionManager: UserSessionManager!
    private var userInfoServiceMock: UserInfoService = UserInfoServiceMock()
    private var userSessionDataStorage: UserSessionDataStorage!
    private var legacyUserSessionManager: LegacyUserSessionManager!

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
        self.userSessionManager = UserSessionManagerImpl(
            deps: .init(
                logoutService: LogoutServiceMock(),
                userSessionDataStorage: self.userSessionDataStorage,
                refreshTokenService: self.refreshTokenService,
                userInfoService: self.userInfoServiceMock,
                logger: LoggerMock()
            )
        )
        self.transportMock.responseProvider = nil
    }

    override func tearDownWithError() throws {
        try? self.userSessionDataStorage.removeAllUserSessionsData()
        self.userSessionDataStorage = nil
    }

    func testRefreshTokenSuccess() {
        // given
        let userId = Int.random
        let baseData = UserSessionData.random(userId: userId, withUserData: false)
        let refreshData = UserSessionData.random(userId: userId, withUserData: false)
        let session = self.userSessionManager.makeUserSession(with: baseData)
        self.transportMock.responseProvider = { request -> Result<VKIDCore.VKAPIResponse, VKIDCore.VKAPIError> in
            .success(OAuth2.RefreshToken.Response.create(
                userSessionData: refreshData,
                state: request.parameters["state"] as! String
            ))
        }
        // when
        session.getFreshAccessToken(forceRefresh: true) { result in
            // then
            XCTAssertEqual(try? result.get().0.value, refreshData.accessToken.value)
            XCTAssertEqual(try? result.get().1.value, refreshData.refreshToken.value)
        }
    }

    func testRefreshTokenFailed() {
        // given
        let expectation = self.expectation(description: #function)
        let baseData = UserSessionData.random(withUserData: false)
        let session = self.userSessionManager.makeUserSession(with: baseData)
        self.transportMock.responseProvider = { request -> Result<VKIDCore.VKAPIResponse, VKIDCore.VKAPIError> in
            .failure(.unknown)
        }
        // when
        session.getFreshAccessToken(forceRefresh: true) { result in
            // then
            if case .failure(.unknown) = result {
                expectation.fulfill()
            } else {
                XCTFail("refreshed successfully with failed request")
            }
        }
        self.wait(for: [expectation], timeout: 0.1)
    }

    func testRefreshTokenMissing() {
        // given
        let expectation = self.expectation(description: #function)
        let encodedString =
            "{\"accessToken\":{\"value\":\"9B8494E3-54BF-47F6-ADF2-EFFAB1B21AA9\",\"expirationDate\":731966387.422122,\"userId\":{\"value\":6817500562519052877}},\"refreshToken\":{\"value\":\"\",\"userId\":{\"value\":6817500562519052877}},\"id\":{\"value\":6817500562519052877},\"creationDate\":731966387.422294,\"oAuthProvider\":{\"type\":\"vkid\"},\"idToken\":{\"value\":\"SOME_ID_TOKEN\",\"userId\":{\"value\":6817500562519052877}},\"serverProvidedDeviceId\":\"testServerProvidedDeviceId\"}"
        let baseData = try! JSONDecoder().decode(UserSessionData.self, from: encodedString.data(using: .utf8)!)
        let session = self.userSessionManager.makeUserSession(with: baseData)
        self.transportMock.responseProvider = { request -> Result<VKIDCore.VKAPIResponse, VKIDCore.VKAPIError> in
            .failure(.cancelled)
        }

        // when
        session.getFreshAccessToken(forceRefresh: true) { result in
            // then
            if case .failure(.unknown) = result {
                expectation.fulfill()
            } else {
                XCTFail("refreshing without refresh token\(result)")
            }
        }
        self.wait(for: [expectation], timeout: 0.1)
    }

    func testGetFreshAccessToken() {
        // given
        let userSessionData = UserSessionData.random(
            withUserData: false,
            accessTokenExpirationDate:
            Date().addingTimeInterval(UserSessionImpl.freshAccessTokenTime + 10)
        )
        let session = self.userSessionManager.makeUserSession(with: userSessionData)
        self.transportMock.responseProvider = { request -> Result<VKIDCore.VKAPIResponse, VKIDCore.VKAPIError> in
            XCTFail("should not be called")
            return .failure(.cancelled)
        }
        // when
        session.getFreshAccessToken(forceRefresh: false) { result in
            // then
            XCTAssertEqual(try? result.get().0.value, userSessionData.accessToken.value)
            XCTAssertEqual(try? result.get().1.value, userSessionData.refreshToken.value)
        }
    }

    func testRefreshTokenExpiredInRequest() {
        // given
        let expectation = self.expectation(description: #function)
        let userSessionData = UserSessionData.random(withUserData: false)
        let session = self.userSessionManager.makeUserSession(with: userSessionData)
        self.transportMock.responseProvider = { request -> Result<VKIDCore.VKAPIResponse, VKIDCore.VKAPIError> in
            .failure(.invalidRequest(reason: .invalidRefreshToken))
        }
        // when
        session.getFreshAccessToken(forceRefresh: true) { result in
            // then
            if case .failure(.invalidRefreshToken) = result {
                expectation.fulfill()
            } else {
                XCTFail("expired refresh token check failed")
            }
        }
        self.wait(for: [expectation], timeout: 0.1)
    }

    func testAccessTokenNeedRefresh() {
        // given
        let userId = Int.random
        let baseData = UserSessionData.random(
            userId: userId,
            withUserData: false,
            accessTokenExpirationDate:
            Date().addingTimeInterval(UserSessionImpl.freshAccessTokenTime - 1)
        )
        let refreshData = UserSessionData.random(userId: userId, withUserData: false)
        let session = self.userSessionManager.makeUserSession(with: baseData)
        self.transportMock.responseProvider = { request -> Result<VKIDCore.VKAPIResponse, VKIDCore.VKAPIError> in
            .success(OAuth2.RefreshToken.Response.create(
                userSessionData: refreshData,
                state: request.parameters["state"] as! String
            ))
        }
        // when
        session.getFreshAccessToken(forceRefresh: false) { result in
            // then
            XCTAssertEqual(try? result.get().0.value, refreshData.accessToken.value)
            XCTAssertEqual(try? result.get().1.value, refreshData.refreshToken.value)
        }
    }
}
