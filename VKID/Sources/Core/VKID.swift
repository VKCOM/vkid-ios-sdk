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
}

/// Объект, через который идет все взаимодействие с VKID
public final class VKID {
    private var config: Configuration
    private var observers = WeakObservers<VKIDObserver>()
    private var activeFlow: AuthFlow?

    private let rootContainer: RootContainer

    /// Сохраненные авторизованные сессии
    public var authorizedSessions: [UserSession] {
        self.rootContainer.userSessionManager.userSessions
    }

    /// Самая новая сессия из всех сохраненных.
    /// Это свойство вычисляемое, и будет возвращать всегда либо самую новую сессию, либо nil.
    public var currentAuthorizedSession: UserSession? {
        self.authorizedSessions
            .sorted { $0.data.creationDate > $1.data.creationDate }
            .first
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
    public init(config: Configuration) throws {
        Appearance.ColorScheme.current = config.appearance.colorScheme

        self.config = config
        self.rootContainer = RootContainer(
            appCredentials: config.appCredentials,
            networkConfiguration: config.network
        )
        self.rootContainer.userSessionManager.delegate = self
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

    /// Запускает флоу авторизации через VKID
    /// - Parameters:
    ///   - authConfig: настройки флоу авторизации
    ///   - presenter: объект, отвечающий за показ экранов авторизации
    ///   - completion: коллбэк с результатом авторизации
    public func authorize(
        with authConfig: AuthConfiguration = AuthConfiguration(),
        using presenter: UIKitPresenter,
        completion: @escaping AuthResultCompletion
    ) {
        dispatchPrecondition(condition: .onQueue(.main))

        if self.activeFlow != nil {
            let authAlreadyInProgress: AuthResult = .failure(.authAlreadyInProgress)
            self.observers.notify {
                $0.vkid(self, didCompleteAuthWith: authAlreadyInProgress, in: authConfig.oAuthProvider)
            }
            completion(authAlreadyInProgress)
            return
        }

        if authConfig.oAuthProvider.type == .vkid {
            self.activeFlow = self.rootContainer.serviceAuthFlow(
                for: authConfig,
                appearance: self.appearance
            )
        } else {
            self.activeFlow = self.rootContainer.webViewAuthFlow(
                for: authConfig,
                appearance: self.appearance
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
                            oAuthProvider: authConfig.oAuthProvider,
                            accessToken: $0.accessToken,
                            user: $0.user
                        )
                    )
            }

            let authResult = AuthResult(userSessionResult)
            self.observers.notify {
                $0.vkid(self, didCompleteAuthWith: authResult, in: authConfig.oAuthProvider)
            }
            completion(authResult)
        }
        self.observers.notify {
            $0.vkid(self, didStartAuthUsing: authConfig.oAuthProvider)
        }
    }

    /// Открытие ресурса в VKID
    ///
    /// Необходим для открытия ссылки при возврате после прыжка в провайдер(приложение).
    /// - Parameters:
    ///   - url: ссылка ресурса
    public func open(url: URL) -> Bool {
        self.rootContainer.appInteropHandler.open(url: url)
    }
}

extension VKID: UserSessionManagerDelegate {
    internal func userSessionManager(
        _ manager: UserSessionManager,
        didLogoutFrom session: UserSession,
        with result: LogoutResult
    ) {
        self.observers.notify {
            $0.vkid(self, didLogoutFrom: session, with: result)
        }
    }
}

extension VKID: UIFactory {}

extension VKID {
    /// VKID version
    public static var sdkVersion: String { VKID_VERSION }

    internal var isAuthorizing: Bool {
        self.activeFlow != nil
    }
}

extension AuthResult {
    internal init(_ result: Result<UserSession, AuthFlowError>) {
        switch result {
        case .success(let session):
            self = .success(session)
        case .failure(.authCancelledByUser):
            self = .failure(.cancelled)
        case .failure:
            self = .failure(.unknown)
        }
    }
}
