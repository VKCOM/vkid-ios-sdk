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
import UIKit
import VKIDCore

internal final class RootContainer {
    private let appCredentials: AppCredentials
    private let networkConfiguration: NetworkConfiguration
    private let defaultHeaders: VKAPIRequest.Headers
    private let deviceId = DeviceId.currentDeviceId
    private let apiHosts: APIHosts

    internal init(
        appCredentials: AppCredentials,
        networkConfiguration: NetworkConfiguration,
        webViewStrategyFactory: WebViewAuthStrategyFactory? = nil
    ) {
        self.appCredentials = appCredentials
        self.networkConfiguration = networkConfiguration
        self.defaultHeaders = ["User-Agent": "\(UserAgent.default) VKID/\(Env.VKIDVersion)"]
        self.apiHosts = APIHosts(template: networkConfiguration.customDomainTemplate, hostname: Env.apiHost)
        self.webViewStrategyFactory = webViewStrategyFactory
    }

    internal lazy var anonymousTokenTransport: VKAPITransport = {
        URLSessionTransport(
            urlRequestBuilder: URLRequestBuilder(
                apiHosts: self.apiHosts
            ),
            genericParameters: VKAPIGenericParameters(
                deviceId: self.deviceId.description,
                clientId: self.appCredentials.clientId,
                apiVersion: Env.VKAPIVersion,
                vkidVersion: Env.VKIDVersion
            ),
            defaultHeaders: self.defaultHeaders,
            sslPinningConfiguration: self.sslPinningConfiguration
        )
    }()

    internal lazy var requestAuthorizationInterceptor = RequestAuthorizationInterceptor(
        deps: .init(
            anonymousTokenService: anonTokenService
        )
    )
    internal lazy var expiredAccessTokenInterceptor = ExpiredAccessTokenInterceptor()
    internal lazy var anonTokenService = AnonymousTokenServiceImpl(
        deps: .init(
            keychain: Keychain(),
            api: VKAPI<Auth>(transport: self.anonymousTokenTransport),
            credentials: self.appCredentials
        )
    )

    internal lazy var mainTransport: VKAPITransport = {
        URLSessionTransport(
            urlRequestBuilder: URLRequestBuilder(
                apiHosts: self.apiHosts
            ),
            requestInterceptors: [
                self.requestAuthorizationInterceptor,
            ],
            responseInterceptors: [
                ExpiredAnonymousTokenInterceptor(anonymousTokenService: self.anonTokenService),
                self.expiredAccessTokenInterceptor,
            ],
            genericParameters: VKAPIGenericParameters(
                deviceId: self.deviceId.description,
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
    internal lazy var appInteropHandler: AppInteropCompositeHandling = AppInteropCompositeHandler()
    internal lazy var appInteropURLOpener: AppInteropURLOpening = AppInteropURLOpener()
    internal lazy var responseParser: AuthCodeResponseParser = AuthCodeResponseParserImpl()
    internal lazy var authURLBuilder: AuthURLBuilder = AuthURLBuilderImpl()
    internal lazy var logger: Logging = Logger(subsystem: "VKID")
    internal lazy var tokenService = TokenService(
        deps: .init(
            api: VKAPI<OAuth2>(transport: self.mainTransport),
            appCredentials: self.appCredentials
        )
    )
    internal lazy var userService = UserService(
        deps: .init(
            api: VKAPI<OAuth2>(transport: self.mainTransport),
            appCredentials: self.appCredentials,
            deviceId: self.deviceId
        )
    )
    internal lazy var userSessionManager: UserSessionManager = {
        let userSessionManager = UserSessionManagerImpl(
            deps: .init(
                logoutService: self.logoutService,
                userSessionDataStorage: self.userSessionDataStorage,
                refreshTokenService: self.refreshTokenService,
                userInfoService: self.userInfoService,
                logger: self.logger
            )
        )
        self.requestAuthorizationInterceptor.userSessionManager = userSessionManager
        self.expiredAccessTokenInterceptor.userSessionManager = userSessionManager

        return userSessionManager
    }()

    internal lazy var legacyUserSessionManager: LegacyUserSessionManager = LegacyUserSessionManagerImpl(
        deps: .init(
            legacyLogoutService: self.legacyLogoutService,
            logger: self.logger,
            legacyUserSessionDataStorage: self.legacyUserSessionDataStorage
        )
    )
    internal lazy var userSessionDataStorage: any UserSessionDataStorage = UserSessionDataStorageImpl(
        deps: .init(
            keychain: self.keychain,
            appCredentials: self.appCredentials
        )
    )
    internal lazy var legacyUserSessionDataStorage: any LegacyUserSessionDataStorage =
        StorageImpl<LegacyUserSessionData>(
            deps: .init(
                keychain: self.keychain,
                appCredentials: self.appCredentials
            )
        )
    internal lazy var legacyLogoutService = LegacyLogoutServiceImpl(
        deps: .init(
            api: VKAPI<Auth>(transport: self.mainTransport),
            appCredentials: self.appCredentials
        )
    )
    internal lazy var oAuth2MigrationService: OAuth2MigrationService = OAuth2MigrationServiceImpl(
        deps: .init(
            api: VKAPI<OAuth2>(transport: self.mainTransport),
            appCredentials: self.appCredentials,
            deviceId: self.deviceId
        )
    )
    // Менеджер для миграции сессии на OAuth2
    public lazy var oAuth2MigrationManager: OAuth2MigrationManager = OAuth2MigrationManagerImpl(
        deps: .init(
            logoutService: self.logoutService,
            legacyUserSessionManager: self.legacyUserSessionManager,
            userSessionManager: self.userSessionManager,
            oAuth2MigrationService: self.oAuth2MigrationService,
            appCredentials: self.appCredentials,
            codeExchangingService: self.tokenService
        )
    )
    internal lazy var analyticsService = AnalyticsServiceImpl(
        deps: .init(
            api: VKAPI<StatEvents>(transport: self.mainTransport),
            logger: self.logger
        )
    )
    internal lazy var productAnalytics = Analytics<TypeRegistrationItemNamespace>(
        deps: .init(
            service: self.analyticsService
        )
    )
    internal lazy var techAnalytcs = Analytics<TypeSAKSessionsEventItemNamespace>(
        deps: .init(
            service: self.analyticsService
        )
    )
    internal lazy var vkidAnalytics = VKIDAnalytics(
        deps: .init(
            analytics: self.productAnalytics
        )
    )

    internal var refreshTokenService: RefreshTokenService {
        self.tokenService
    }

    internal var codeExchangingService: CodeExchangingService {
        self.tokenService
    }

    internal var userInfoService: UserInfoService {
        self.userService
    }

    internal var logoutService: LogoutService {
        self.userService
    }

    internal lazy var appStateProvider: AppStateProvider = UIApplication.shared

    internal var webViewStrategyFactory: WebViewAuthStrategyFactory?

    internal lazy var authFlowBuilder: AuthFlowBuilder = {
        AuthFlowBuilderImpl(rootContainer: self)
    }()

    internal lazy var pkceSecretsGenerator: PKCESecretsGenerator = {
        PKCESecretsS256Generator()
    }()
}

// AuthFlowBuilder implementation
extension RootContainer {
    internal func webViewAuthFlow(
        in authContext: AuthContext,
        for authConfig: ExtendedAuthConfiguration,
        appearance: Appearance
    ) -> AuthFlow {
        WebViewAuthFlow(
            deps: .init(
                api: VKAPI<OAuth2>(transport: self.mainTransport),
                appCredentials: self.appCredentials,
                appearance: appearance,
                authConfig: authConfig,
                authContext: authContext,
                oAuthProvider: authConfig.oAuthProvider,
                authURLBuilder: self.authURLBuilder,
                webViewStrategyFactory: self.webViewStrategyFactory ?? WebViewAuthStrategyDefaultFactory(
                    deps: .init(
                        appInteropHandler: self.appInteropHandler,
                        appInteropOpener: self.appInteropURLOpener,
                        responseParser: self.responseParser
                    )
                ),
                logger: self.logger,
                deviceId: self.deviceId,
                authConfigTemplateURL:
                URLComponents(
                    string: "https://\(self.apiHosts.getHostBy(requestHost: .id))/authorize"
                )?.url
            )
        )
    }

    internal func authByProviderFlow(
        in authContext: AuthContext,
        for authConfig: ExtendedAuthConfiguration,
        appearance: Appearance
    ) -> AuthFlow {
        AuthByProviderFlow(
            deps: .init(
                appInteropHandler: self.appInteropHandler,
                appInteropOpener: self.appInteropURLOpener,
                authProvidersFetcher: AuthProviderFetcherImpl(
                    deps: .init(
                        api: VKAPI<Auth>(transport: self.mainTransport)
                    )
                ),
                appCredentials: self.appCredentials,
                authConfig: authConfig,
                authContext: authContext,
                analytics: self.productAnalytics,
                responseParser: self.responseParser,
                authURLBuilder: self.authURLBuilder,
                api: VKAPI<OAuth2>(transport: self.mainTransport),
                logger: self.logger,
                deviceId: self.deviceId
            )
        )
    }

    internal func serviceAuthFlow(
        in authContext: AuthContext,
        for authConfig: ExtendedAuthConfiguration,
        appearance: Appearance
    ) -> AuthFlow {
        ServiceAuthFlow(
            deps: .init(
                webViewAuthFlow: self.webViewAuthFlow(
                    in: authContext,
                    for: authConfig,
                    appearance: appearance
                ),
                authByProviderFlow: self.authByProviderFlow(
                    in: authContext,
                    for: authConfig,
                    appearance: appearance
                ),
                appStateProvider: self.appStateProvider
            )
        )
    }
}
