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
import VKIDCore

/// Отслеживание статуса авторизации
public protocol VKIDObserver: AnyObject {
    /// Сообщает о старте флоу авторизации через VKID
    /// - Parameters:
    ///   - vkid: объект взаимодействия с VKID
    ///   - oAuth: провайдер авторизации
    func vkid(_ vkid: VKID, didStartAuthUsing oAuth: OAuthProvider)

    /// Сообщает о завершении флоу авторизации через VKID
    /// - Parameters:
    ///   - vkid: объект взаимодействия с VKID
    ///   - result: результат авторизации
    ///   - oAuth: провайдер авторизации
    func vkid(_ vkid: VKID, didCompleteAuthWith result: AuthResult, in oAuth: OAuthProvider)

    /// Сообщает о завершении логаута сессии через VKID
    /// - Parameters:
    ///   - vkid: объект взаимодействия с VKID
    ///   - session: сессия, из которой был выполнен логаут
    ///   - result: результат логаута
    func vkid(_ vkid: VKID, didLogoutFrom session: UserSession, with result: LogoutResult)

    /// Сообщает об обновлении токенов через VKID
    /// - Parameters:
    ///   - vkid: объект взаимодействия с VKID
    ///   - session: сессия, в которой обновляются токены
    ///   - result: результат обновления токенов
    func vkid(_ vkid: VKID, didRefreshAccessTokenIn session: UserSession, with result: TokenRefreshingResult)

    /// Сообщает об обновлении данных пользователя через VKID
    /// - Parameters:
    ///   - vkid: объект взаимодействия с VKID
    ///   - session: сессия, в которой обновляются данные пользователя
    ///   - result: результат обновления данных пользователя
    func vkid(_ vkid: VKID, didUpdateUserIn session: UserSession, with result: UserFetchingResult)
}

// MARK: - Поддержка обратной совместимости
extension VKIDObserver {
    public func vkid(_ vkid: VKID, didLogoutFrom session: UserSession, with result: LogoutResult) {}
    public func vkid(_ vkid: VKID, didUpdateUserIn session: UserSession, with result: UserFetchingResult) {}
    public func vkid(_ vkid: VKID, didRefreshAccessTokenIn session: UserSession, with result: TokenRefreshingResult) {}
}

/// Объект, через который идет все взаимодействие с VKID
public final class VKID {
    private var config: Configuration
    private var observers = WeakObservers<VKIDObserver>()
    private var activeFlow: AuthFlow?

    internal let rootContainer: RootContainer

    // Менеджер для миграции сессии на OAuth2
    public var oAuth2MigrationManager: OAuth2MigrationManager {
        self.rootContainer.oAuth2MigrationManager
    }

    /// Сохраненные авторизованные сессии
    public var authorizedSessions: [UserSession] {
        self.rootContainer.userSessionManager.userSessions
    }

    /// Самая новая сессия из всех сохраненных.
    /// Это свойство вычисляемое, и будет возвращать всегда либо самую новую сессию, либо nil.
    public var currentAuthorizedSession: UserSession? {
        self.rootContainer.userSessionManager.currentAuthorizedSession
    }

    /// Сохраненные сессии требующие миграции
    public var legacyAuthorizedSessions: [LegacyUserSession] {
        self.rootContainer.legacyUserSessionManager.legacyUserSessions
    }

    public var appearance: Appearance {
        get {
            self.config.appearance
        }
        set {
            self.config.appearance = newValue
            Appearance.ColorScheme.current = newValue.colorScheme
        }
    }

    /// Создает объект VKID с указанной конфигурацией
    /// - Parameter config: объект конфигурация VKID
    public convenience init(config: Configuration) throws {
        try self.init(
            config: config,
            rootContainer: RootContainer(
                appCredentials: config.appCredentials,
                networkConfiguration: config.network
            )
        )
    }

    internal init(
        config: Configuration,
        rootContainer: RootContainer
    ) throws {
        Appearance.ColorScheme.current = config.appearance.colorScheme

        self.config = config
        self.rootContainer = rootContainer

        self.rootContainer.userSessionManager.delegate = self
        self.observers.add(
            self.rootContainer.vkidAnalytics
        )
        self.rootContainer.techAnalytcs.sdkInit.send()
    }

    public func add(observer: VKIDObserver) {
        guard !self.observers.contains(observer) else {
            return
        }
        self.observers.add(observer)
    }

    public func remove(observer: VKIDObserver) {
        self.observers.remove(observer)
    }

    /// Открытие ресурса в VKID
    ///
    /// Необходим для открытия ссылки при возврате после прыжка в провайдер(приложение).
    /// - Parameters:
    ///   - url: ссылка ресурса
    public func open(url: URL) -> Bool {
        self.rootContainer.appInteropHandler.open(url: url)
    }

    /// Запускает флоу авторизации через VKID.
    /// - Parameters:
    ///   - authConfig: настройки флоу авторизации
    ///   - presenter: объект, отвечающий за показ экранов авторизации
    ///   - oAuthProvider: OAuth провайдер
    ///   - completion: коллбэк с результатом авторизации
    public func authorize(
        with authConfig: AuthConfiguration = AuthConfiguration(),
        oAuthProvider: OAuthProvider = .vkid,
        using presenter: UIKitPresenter,
        completion: @escaping AuthResultCompletion
    ) {
        self.authorize(
            authContext: AuthContext(
                launchedBy: .service
            ),
            authConfig: authConfig,
            oAuthProviderConfig: .init(primaryProvider: oAuthProvider),
            presenter: presenter,
            completion: completion
        )
    }

    /// Запускает флоу авторизации через VKID.
    /// - Parameters:
    ///   - authConext: информация о текущей авторизации.
    ///   - authConfig: настройки флоу авторизации.
    ///   - oAuthProviderConfig: Конфигурация OAuth провайдеров
    ///   - presenter: объект, отвечающий за показ экранов авторизации.
    ///   - completion: коллбэк с результатом авторизации.
    internal func authorize(
        authContext: AuthContext,
        authConfig: AuthConfiguration,
        oAuthProviderConfig: OAuthProviderConfiguration,
        presenter: UIKitPresenter,
        completion: @escaping AuthResultCompletion
    ) {
        guard
            let pkce = authConfig.flow.pkce ?? (
                try? PKCESecrets(
                    pkceSecretsGenerator: self.rootContainer.pkceSecretsGenerator
                )
            )
        else {
            let pkceGenerationFailed: AuthResult = .failure(.unknown)
            self.observers.notify {
                $0.vkid(
                    self,
                    didCompleteAuthWith: pkceGenerationFailed,
                    in: oAuthProviderConfig.primaryProvider
                )
            }
            completion(pkceGenerationFailed)
            return
        }
        let pkceWallet = PKCESecretsWallet(secrets: pkce)
        let codeExchanger = authConfig.flow.codeExchanger ??
            CodeExchanger(
                deps: .init(codeExchangingService: self.rootContainer.codeExchangingService),
                pkceSecrets: pkceWallet
            )
        let extendedAuthConfiguration = ExtendedAuthConfiguration(
            pkceSecrets: pkceWallet,
            codeExchanger: codeExchanger,
            oAuthProvider: oAuthProviderConfig.primaryProvider,
            scope: authConfig.scope?.description
        )

        self.authorize(
            authContext: authContext,
            extendedAuthConfig: extendedAuthConfiguration,
            presenter: presenter,
            completion: completion
        )
    }

    /// Запускает флоу авторизации через VKID.
    /// - Parameters:
    ///   - authConext: информация о текущей авторизации.
    ///   - extendedAuthConfig: расширенные настройки флоу авторизации.
    ///   - presenter: объект, отвечающий за показ экранов авторизации.
    ///   - completion: коллбэк с результатом авторизации.
    internal func authorize(
        authContext: AuthContext,
        extendedAuthConfig: ExtendedAuthConfiguration,
        presenter: UIKitPresenter,
        completion: @escaping AuthResultCompletion
    ) {
        dispatchPrecondition(condition: .onQueue(.main))

        if self.activeFlow != nil {
            let authAlreadyInProgress: AuthResult = .failure(.authAlreadyInProgress)
            self.observers.notify {
                $0.vkid(self, didCompleteAuthWith: authAlreadyInProgress, in: extendedAuthConfig.oAuthProvider)
            }
            completion(authAlreadyInProgress)
            return
        }

        self.rootContainer.vkidAnalytics.authContext = authContext

        switch extendedAuthConfig.oAuthProvider.type {
        case .vkid:
            self.activeFlow = self.rootContainer.authFlowBuilder.serviceAuthFlow(
                in: authContext,
                for: extendedAuthConfig,
                appearance: self.appearance
            )
        case .ok, .mail:
            self.activeFlow = self.rootContainer.authFlowBuilder.webViewAuthFlow(
                in: authContext,
                for: extendedAuthConfig,
                appearance: self.appearance
            )
        }
        self.observers.notify {
            $0.vkid(
                self,
                didStartAuthUsing: extendedAuthConfig.oAuthProvider
            )
        }
        self.activeFlow?.authorize(with: presenter) { [weak self] result in
            dispatchPrecondition(condition: .onQueue(.main))

            guard let self else { return }

            self.activeFlow = nil

            let userSessionResult = result.map {
                self.rootContainer
                    .userSessionManager
                    .makeUserSession(
                        with: UserSessionData(
                            id: $0.accessToken.userId,
                            oAuthProvider: extendedAuthConfig.oAuthProvider,
                            accessToken: $0.accessToken,
                            refreshToken: $0.refreshToken,
                            idToken: $0.idToken,
                            serverProvidedDeviceId: $0.deviceId
                        )
                    ) as UserSession
            }

            let authResult = AuthResult(userSessionResult)

            self.observers.notify {
                $0.vkid(
                    self,
                    didCompleteAuthWith: authResult,
                    in: extendedAuthConfig.oAuthProvider
                )
            }
            completion(authResult)
        }
    }
}

extension VKID: UserSessionManagerDelegate {
    internal func userSessionManager(
        _ manager: UserSessionManager,
        didRefreshAccessTokenIn session: UserSessionImpl,
        with result: TokenRefreshingResult
    ) {
        self.observers.notify {
            $0.vkid(self, didRefreshAccessTokenIn: session, with: result)
        }
    }

    internal func userSessionManager(
        _ manager: UserSessionManager,
        didLogoutFrom session: UserSessionImpl,
        with result: LogoutResult
    ) {
        self.observers.notify {
            $0.vkid(self, didLogoutFrom: session, with: result)
        }
    }

    internal func userSessionManager(
        _ manager: UserSessionManager,
        didUpdateUserIn session: UserSessionImpl,
        with result: UserFetchingResult
    ) {
        self.observers.notify {
            $0.vkid(self, didUpdateUserIn: session, with: result)
        }
    }
}

extension VKID: UIFactory {}

extension VKID {
    /// VKID version
    public static var sdkVersion: String { VKID_VERSION }

    /// VKID server API version
    public static var apiVersion: String { VKAPI_VERSION }

    internal var isAuthorizing: Bool {
        self.activeFlow != nil
    }
}

extension AuthResult {
    internal init(
        _ result: Result<UserSession, AuthFlowError>
    ) {
        switch result {
        case .success(let session):
            self = .success(session)
        case .failure(.authCancelledByUser):
            self = .failure(.cancelled)
        case .failure(.codeVerifierNotProvided):
            self = .failure(.codeVerifierNotProvided)
        case .failure:
            self = .failure(.unknown)
        }
    }
}
