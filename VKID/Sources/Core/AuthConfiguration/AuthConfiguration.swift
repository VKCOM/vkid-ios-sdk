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

/// Определяет основные параметры авторизации
public struct AuthConfiguration {
    let scope: Scope?

    /// Флоу авторизации
    let flow: Flow

    /// Создает конфигурацию авторизации
    /// - Parameters:
    ///   - flow: Флоу авторизации Confidential client flow или Public client flow
    ///   - scope:
    ///   Запрашиваемые [права доступа](https://id.vk.com/about/business/go/docs/ru/vkid/latest/vk-id/connection/api-integration/api-description#Dostup-prilozheniya-k-dannym-polzovatelya).
    ///   Запрошенный список прав для приложения не может быть больше, чем разрешенный список в [настройках приложения](https://id.vk.com/about/business/go/docs/ru/vkid/latest/vk-id/connection/application-settings)
    ///   По умолчанию scope = nil, в этом случае будет выдано базовое право доступа `vkid.personal_info`.
    public init (
        flow: Flow = .publicClientFlow(),
        scope: Scope? = nil
    ) {
        self.flow = flow
        self.scope = scope
    }
}

/// Код авторизации и параметры необходимые для его обмена на ```AccessToken```, ```RefreshToken```, ```IDToken```
/// по Confidential client flow
public struct AuthorizationCode {
    /// Случайно сгенерированная строка из ```PKCESecrets```
    public let state: String

    /// Параметр, предоставленный в ```PKCESecrets```
    public let codeVerifier: String?

    /// [Код авторизации](https://datatracker.ietf.org/doc/html/rfc6749#section-1.3.1), полученный от сервера
    public let code: String

    /// Девайс айди. Предоставляется в зашифрованном виде, поэтому значения для каждой сессии разные.
    /// Используется для вызовов API с OAuth2.1.
    public let deviceId: String

    /// Параметр необходим для поддержания безопасности. [Подробнее](https://datatracker.ietf.org/doc/html/rfc6749#section-10.6)
    public let redirectURI: String
}

/// Протокол обмена кода авторизации на токены ```AccessToken```, ```RefreshToken```, ```IDToken```
public protocol AuthCodeExchanging {
    /// Обмен кода авторизации на токены
    /// - Parameters:
    ///   - code: ```AuthorizationCode```, который необходимо заменить на токены, чтобы завершить авторизацию
    ///   - completion: колбек с результатом авторизации ```AuthFlowData```
    func exchangeAuthCode(
        _ code: AuthorizationCode,
        completion: @escaping (Result<AuthFlowData, Error>)-> Void
    )
}

extension AuthConfiguration {
    /// Определяет сценарий получения ```AccessToken```.
    ///
    /// Cогласно [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749#section-2.1) доступны следующие сценарии:
    /// - Confidential client flow: обмен ```AuthorizationCode``` на ```AccessToken``` через ваш сервер
    /// - Public client flow: обмен ```AuthorizationCode``` на ```AccessToken``` на стороне VK ID SDK
    public struct Flow {
        internal let codeExchanger: AuthCodeExchanging?
        internal let pkce: PKCESecrets?

        /// Создает сценарий авторизации для confidential клиентов согласно [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749#section-2.1).
        /// - Parameters:
        ///   - codeExchanger: Реализация обмена ```AuthorizationCode``` на ```AccessToken``` через ваш сервер
        ///   - pkce: PKCE секреты, сгенерированные на вашей стороне. Если не указаны, VK ID SDK сгенерирует PKCE на своей стороне.
        /// - Returns: сценарий авторизации для confidential клиентов
        public static func confidentialClientFlow(
            codeExchanger: AuthCodeExchanging,
            pkce: PKCESecrets? = nil
        ) -> Self {
            .init(codeExchanger: codeExchanger, pkce: pkce)
        }

        /// Создает сценарий авторизации для public клиентов согласно [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749#section-2.1).
        /// - Parameter pkce: PKCE секреты, сгенерированные на вашей стороне. Если вы предоставляете параметры PKCE, то `codeVerifier`
        /// обязателен для `publicClientFlow`, иначе авторизация закончится с ошибкой  `AuthFlowError.codeVerifierNotProvided`.
        /// Если же `pkce` не указан, то VK ID SDK сгенерирует PKCE на своей стороне.
        /// - Returns: Сценарий авторизации для public клиентов
        public static func publicClientFlow(
            pkce: PKCESecrets? = nil
        ) -> Self {
            .init(codeExchanger: nil, pkce: pkce)
        }

        internal init(
            codeExchanger: AuthCodeExchanging?,
            pkce: PKCESecrets?
        ) {
            self.codeExchanger = codeExchanger
            self.pkce = pkce
        }
    }
}
