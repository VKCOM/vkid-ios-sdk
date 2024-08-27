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

@_spi(VKIDDebug)
@testable import VKID
@testable import VKIDCore

public protocol TestCaseInfra {
    var vkid: VKID! { get set }
}

extension TestCaseInfra {
    public func createVKID(
        rootContainer: RootContainer? = nil,
        webViewAuthStrategyFactory: WebViewAuthStrategyFactory? = nil,
        requestInterceptors: [VKAPIRequestInterceptor] = [],
        responseInterceptors: [VKAPIResponseInterceptor] = [],
        urlSessionMock: URLSessionMock = URLSessionMock(
            urlSessionDataTaskMock: URLSessionDataTaskMock()
        ),
        userSessionDataStorage: any UserSessionDataStorage = UserSessionDataStorageMock(),
        anonymousTokenTransport: any VKAPITransport = URLSessionTransportMock()
    ) -> VKID {
        let rootContainer = rootContainer ?? self.createRootContainer(
            webViewAuthStrategyFactory: webViewAuthStrategyFactory
        )

        let urlSessionTransport = URLSessionTransport(
            urlRequestBuilder: URLRequestBuilder(
                apiHosts: APIHosts(hostname: Env.apiHost)
            ),
            requestInterceptors: requestInterceptors,
            responseInterceptors: responseInterceptors,
            genericParameters: VKAPIGenericParameters(
                deviceId: "",
                clientId: "",
                apiVersion: Version("0.0.0"),
                vkidVersion: Version("0.0.0")
            ),
            defaultHeaders: [:],
            sslPinningConfiguration: .pinningDisabled,
            urlSession: urlSessionMock
        )

        return self.createVKID(
            rootContainer: rootContainer,
            userSessionDataStorage: userSessionDataStorage,
            mainTransport: urlSessionTransport,
            anonymousTokenTransport: anonymousTokenTransport
        )
    }

    public func createVKID(
        rootContainer: RootContainer? = nil,
        appInteropOpener: AppInteropURLOpening = AppInteropOpenerMock(),
        userSessionDataStorage: any UserSessionDataStorage = UserSessionDataStorageMock(),
        mainTransport: VKAPITransport = URLSessionTransportMock(),
        anonymousTokenTransport: VKAPITransport = URLSessionTransportMock()
    ) -> VKID {
        let rootContainer = rootContainer ?? self.createRootContainer()

        rootContainer.userSessionDataStorage = userSessionDataStorage
        rootContainer.appInteropURLOpener = appInteropOpener

        rootContainer.mainTransport = mainTransport
        rootContainer.anonymousTokenTransport = anonymousTokenTransport

        return try! VKID(
            config: .init(
                appCredentials: Entity.appCredentials
            ),
            rootContainer: rootContainer
        )
    }

    public func createRootContainer(
        urlSessionTransport: URLSessionTransport? = nil,
        webViewAuthStrategyFactory: WebViewAuthStrategyFactory? = nil
    ) -> RootContainer {
        RootContainer(
            appCredentials: Entity.appCredentials,
            networkConfiguration: .init(isSSLPinningEnabled: false),
            webViewStrategyFactory: webViewAuthStrategyFactory
        )
    }

    public func createUserSession() -> (UserSession, UserSessionData) {
        self.createUserSession(userSessionData: .random())
    }

    public func createUserSession(
        userSessionData: UserSessionData = .random()
    ) -> (UserSession, UserSessionData) {
        (
            self.vkid.rootContainer.userSessionManager
                .makeUserSession(with: userSessionData),
            userSessionData
        )
    }
}
