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
@_implementationOnly import VKIDCore

internal final class RootContainer {
    private let appCredentials: AppCredentials
    private let networkConfiguration: NetworkConfiguration
    private let defaultHeaders: VKAPIRequest.Headers

    internal init(
        appCredentials: AppCredentials,
        networkConfiguration: NetworkConfiguration
    ) {
        self.appCredentials = appCredentials
        self.networkConfiguration = networkConfiguration
        self.defaultHeaders = ["User-Agent": "\(UserAgent.default) VKID/\(Env.VKIDVersion)"]
    }

    internal var anonymousTokenTransport: URLSessionTransport {
        URLSessionTransport(
            urlRequestBuilder: URLRequestBuilder(hostname: Env.apiHost),
            genericParameters: VKAPIGenericParameters(
                deviceId: DeviceId.currentDeviceId.description,
                clientId: self.appCredentials.clientId,
                apiVersion: Env.VKAPIVersion,
                vkidVersion: Env.VKIDVersion
            ),
            defaultHeaders: self.defaultHeaders,
            sslPinningConfiguration: self.sslPinningConfiguration
        )
    }

    internal lazy var mainTransport: URLSessionTransport = {
        let anonTokenService = AnonymousTokenServiceImpl(
            keychain: Keychain(),
            api: VKAPI<OAuth>(transport: self.anonymousTokenTransport),
            credentials: self.appCredentials
        )

        return URLSessionTransport(
            urlRequestBuilder: URLRequestBuilder(hostname: Env.apiHost),
            requestInterceptors: [
                RequestAuthorizationInterceptor(anonymousTokenService: anonTokenService),
            ],
            responseInterceptors: [
                ExpiredAnonymousTokenInterceptor(anonymousTokenService: anonTokenService),
            ],
            genericParameters: VKAPIGenericParameters(
                deviceId: DeviceId.currentDeviceId.description,
                clientId: self.appCredentials.clientId,
                apiVersion: Env.VKAPIVersion,
                vkidVersion: Env.VKIDVersion
            ),
            defaultHeaders: self.defaultHeaders,
            sslPinningConfiguration: self.sslPinningConfiguration
        )
    }()

    internal var sslPinningConfiguration: SSLPinningConfiguration {
        self.networkConfiguration.isSSLPinningEnabled
            ? .init(domains: [.vkcom]) : .pinningDisabled
    }

    internal lazy var keychain = Keychain()
    internal lazy var appInteropHandler = AppInteropCompositeHandler()
    internal lazy var responseParser = AuthCodeResponseParserImpl()
    internal lazy var authURLBuilder = AuthURLBuilderImpl()
    internal lazy var logger: Logging = Logger(subsystem: "VKID")
    internal lazy var userSessionManager: UserSessionManager = UserSessionManagerImpl(
        deps: .init(
            logoutService: self.logoutService,
            userSessionDataStorage: self.userSessionDataStorage,
            logger: self.logger
        )
    )
    internal lazy var userSessionDataStorage: UserSessionDataStorage = UserSessionDataStorageImpl(
        deps: .init(
            keychain: self.keychain,
            appCredentials: self.appCredentials
        )
    )
    internal lazy var logoutService = LogoutServiceImpl(
        deps: .init(
            api: VKAPI<Auth>(transport: self.mainTransport),
            appCredentials: self.appCredentials
        )
    )
}

extension RootContainer: AuthFlowBuilder {
    func webViewAuthFlow(
        for authConfig: AuthConfiguration,
        appearance: Appearance
    ) -> AuthFlow {
        WebViewAuthFlow(
            deps: .init(
                api: VKAPI<OAuth>(transport: self.mainTransport),
                appCredentials: self.appCredentials,
                appearance: appearance,
                oAuthProvider: authConfig.oAuthProvider,
                pkceGenerator: PKCESecretsSHA256Generator(),
                authURLBuilder: self.authURLBuilder,
                webViewStrategyFactory: WebViewAuthStrategyDefaultFactory(
                    appInteropHandler: self.appInteropHandler,
                    responseParser: self.responseParser
                ),
                logger: self.logger
            )
        )
    }

    func authByProviderFlow(
        for authConfig: AuthConfiguration,
        appearance: Appearance
    ) -> AuthFlow {
        AuthByProviderFlow(
            deps: .init(
                appInteropHandler: self.appInteropHandler,
                authProvidersFetcher: AuthProviderFetcherImpl(
                    deps: .init(
                        api: VKAPI<Auth>(transport: self.mainTransport)
                    )
                ),
                appCredentials: self.appCredentials,
                pkceGenerator: PKCESecretsSHA256Generator(),
                responseParser: self.responseParser,
                authURLBuilder: self.authURLBuilder,
                api: VKAPI<OAuth>(transport: self.mainTransport),
                logger: self.logger
            )
        )
    }

    func serviceAuthFlow(
        for authConfig: AuthConfiguration,
        appearance: Appearance
    ) -> AuthFlow {
        ServiceAuthFlow(
            deps: .init(
                webViewAuthFlow: self.webViewAuthFlow(
                    for: authConfig,
                    appearance: appearance
                ),
                authByProviderFlow: self.authByProviderFlow(
                    for: authConfig,
                    appearance: appearance
                )
            )
        )
    }
}
