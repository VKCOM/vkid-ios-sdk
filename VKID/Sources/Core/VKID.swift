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

public protocol VKIDObserver: AnyObject {
    func vkid(_ vkid: VKID, didStartAuthUsing oAuth: OAuthProvider)
    func vkid(_ vkid: VKID, didCompleteAuthWith result: AuthResult, in oAuth: OAuthProvider)
}

/// Объект, через который идет все взаимодействие с VKID
public final class VKID {
    private var config: Configuration

    private var observers = WeakObservers<VKIDObserver>()
    private let rootContainer: RootContainer
    private var activeFlow: AuthFlow?
    public private(set) var currentAuthorizedSession: UserSession?

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
        self.config = config
        Appearance.ColorScheme.current = config.appearance.colorScheme
        self.rootContainer = RootContainer(
            appCredentials: config.appCredentials,
            networkConfiguration: config.network
        )
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
                UserSession(
                    oAuthProvider: authConfig.oAuthProvider,
                    accessToken: $0
                )
            }
            self.currentAuthorizedSession = try? userSessionResult.get()
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

    public func open(url: URL) -> Bool {
        self.rootContainer.appInteropHandler.open(url: url)
    }
}

extension VKID: UIFactory {}

extension VKID {
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
