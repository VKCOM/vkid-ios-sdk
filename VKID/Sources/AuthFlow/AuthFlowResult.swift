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

internal typealias AuthFlowResult = Result<AuthFlowData, AuthFlowError>
internal typealias AuthFlowResultCompletion = (AuthFlowResult) -> Void

/// Данные флоу авторизации
public struct AuthFlowData {
    /// Токен доступа
    public let accessToken: AccessToken

    /// Токен для обновления токена доступа
    public let refreshToken: RefreshToken

    /// Токен для получения данных пользователя в маскированном виде
    public let idToken: IDToken

    /// Параметр, определяющий девайс айди, предоставляемый сервером в зашифрованном виде.
    /// Используется для вызовов API с OAuth2.1.
    public let deviceId: String

    public init(
        accessToken: AccessToken,
        refreshToken: RefreshToken,
        idToken: IDToken,
        deviceId: String
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.deviceId = deviceId
    }
}

/// Ошибки внутреннего флоу авторизации
internal enum AuthFlowError: Error {
    case invalidRedirectURL(URL)
    case authorizationFailed
    case invalidExchangeResult
    case authOverdue
    case invalidAuthCallbackURL
    case invalidAuthConfigTemplateURL
    case webViewAuthSessionFailedToStart
    case webViewAuthFailed(Error)
    case noAvailableProviders
    case providersFetchingFailed(Error)
    case authByProviderFailed(Error)
    case authCancelledByUser
    case stateMismatch
    case authCodeExchangingFailed(Error)
    // code verifier not provided for SDK auth code exchanging
    case codeVerifierNotProvided
}
