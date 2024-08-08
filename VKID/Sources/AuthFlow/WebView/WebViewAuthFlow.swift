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

internal final class WebViewAuthFlow: Component, AuthFlow {
    struct Dependencies: Dependency {
        let api: VKAPI<OAuth2>
        let appCredentials: AppCredentials
        let appearance: Appearance
        let authConfig: ExtendedAuthConfiguration
        let authContext: AuthContext
        let oAuthProvider: OAuthProvider
        let authURLBuilder: AuthURLBuilder
        let webViewStrategyFactory: WebViewAuthStrategyFactory
        let logger: Logging
        let deviceId: DeviceId
        let authConfigTemplateURL: URL?
    }

    let deps: Dependencies

    private var webViewAuthStrategy: WebViewAuthStrategy?

    init(deps: Dependencies) {
        self.deps = deps
    }

    func authorize(
        with presenter: UIKitPresenter,
        completion: @escaping AuthFlowResultCompletion
    ) {
        guard let baseUrl = self.deps.authConfigTemplateURL else {
            completion(.failure(.invalidAuthConfigTemplateURL))
            return
        }
        do {
            let authURL = try self.deps.authURLBuilder.buildWebViewAuthURL(
                baseURL: baseUrl,
                oAuthProvider: self.deps.authConfig.oAuthProvider,
                authContext: self.deps.authContext,
                secrets: self.deps.authConfig.pkceSecrets,
                credentials: self.deps.appCredentials,
                scope: self.deps.authConfig.scope,
                deviceId: self.deps.deviceId.description,
                appearance: self.deps.appearance
            )
            self.authInWebView(
                with: presenter,
                authURL: authURL,
                redirectURL: redirectURL(
                    for: self.deps.appCredentials.clientId,
                    in: self.deps.authContext
                ),
                pkceSecrets: self.deps.authConfig.pkceSecrets,
                completion: completion
            )
        } catch let e as AuthFlowError {
            completion(.failure(e))
        } catch {
            completion(.failure(.webViewAuthFailed(error)))
        }
    }

    private func authInWebView(
        with presenter: UIKitPresenter,
        authURL: URL,
        redirectURL: URL,
        pkceSecrets: PKCESecretsWallet,
        completion: @escaping AuthFlowResultCompletion
    ) {
        self.deps.logger.info("Opening webView at: \(authURL), redirect: \(redirectURL)")

        let strategy = self.deps.webViewStrategyFactory.createWebViewAuthStrategy()
        strategy.authInWebView(
            at: authURL,
            redirectURL: redirectURL,
            presenter: presenter
        ) { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case .success(let authCodeResponse):

                self.exchangeCode(
                    using: self.deps.authConfig.codeExchanger,
                    authCodeResponse: authCodeResponse,
                    redirectURI: redirectURL.absoluteString,
                    pkceSecrets: pkceSecrets,
                    completion: completion
                )
            case .failure(let err):
                completion(.failure(err))
            }
        }
        self.webViewAuthStrategy = strategy
    }
}
