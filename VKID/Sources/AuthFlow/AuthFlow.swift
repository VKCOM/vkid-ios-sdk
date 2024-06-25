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

internal protocol AuthFlow {
    func authorize(
        with presenter: UIKitPresenter,
        completion: @escaping AuthFlowResultCompletion
    )
}

internal protocol AuthFlowBuilder {
    func webViewAuthFlow(
        in authContext: AuthContext,
        for authConfig: ExtendedAuthConfiguration,
        appearance: Appearance
    ) -> AuthFlow
    func authByProviderFlow(
        in authContext: AuthContext,
        for authConfig: ExtendedAuthConfiguration,
        appearance: Appearance
    ) -> AuthFlow
    func serviceAuthFlow(
        in authContext: AuthContext,
        for authConfig: ExtendedAuthConfiguration,
        appearance: Appearance
    ) -> AuthFlow
}

extension AuthFlow {
    func handle(
        exchangeCodeResult: Result<OAuth2.ExchangeAuthCode.Response, VKAPIError>,
        state: String,
        serverProvidedDeviceId: String,
        completion: @escaping AuthFlowResultCompletion
    ) {
        switch exchangeCodeResult {
        case .success(let response):
            completion(
                state == response.state ?
                    .success(.init(from: response, serverProvidedDeviceId: serverProvidedDeviceId)) :
                    .failure(.stateMismatch)
            )
        case .failure(let error):
            completion(.failure(.authCodeExchangingFailed(error)))
        }
    }

    func exchangeCode(
        using codeExchanger: AuthCodeExchanging,
        authCodeResponse: AuthCodeResponse,
        redirectURI: String,
        pkceSecrets: PKCESecretsWallet,
        completion: @escaping AuthFlowResultCompletion
    ) {
        do {
            codeExchanger.exchangeAuthCode(
                .init(
                    from: authCodeResponse,
                    codeVerifier: try pkceSecrets.codeVerifier,
                    redirectURI: redirectURI
                )
            ) { result in
                switch result {
                case .success(let data):
                    completion(.success(data))
                case .failure(AuthFlowError.codeVerifierNotProvided):
                    completion(.failure(.codeVerifierNotProvided))
                default:
                    completion(.failure(.authorizationFailed))
                }
            }
        } catch PKCEWalletError.secretsExpired {
            completion(.failure(.authOverdue))
        } catch let error {
            completion(.failure(.authCodeExchangingFailed(error)))
        }
    }
}
