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

internal final class WebViewAuthFlow: Component, AuthFlow {
    struct Dependencies: Dependency {
        let api: VKAPI<OAuth>
        let appCredentials: AppCredentials
        let appearance: Appearance
        let oAuthProvider: OAuthProvider
        let pkceGenerator: PKCESecretsGenerator
        let authURLBuilder: AuthURLBuilder
        let webViewStrategyFactory: WebViewAuthStrategyFactory
        let logger: Logging
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
        self.deps
            .api
            .getAuthConfig
            .execute(
                with: .init(appId: self.deps.appCredentials.clientId)
            ) { [weak self] result in
                guard let self else {
                    return
                }
                do {
                    let config = try result.get()
                    let pkceSecrets = try self.deps.pkceGenerator.generateSecrets()
                    let authURL = try self.deps.authURLBuilder.buildWebViewAuthURL(
                        from: config.userVisibleAuth,
                        for: self.deps.oAuthProvider,
                        with: pkceSecrets,
                        credentials: self.deps.appCredentials,
                        appearance: self.deps.appearance
                    )
                    self.authInWebView(
                        with: presenter,
                        authURL: authURL,
                        redirectURL: redirectURL(for: self.deps.appCredentials.clientId),
                        pkceSecrets: pkceSecrets,
                        completion: completion
                    )
                } catch {
                    completion(.failure(.webViewAuthFailed(error)))
                }
            }
    }

    private func authInWebView(
        with presenter: UIKitPresenter,
        authURL: URL,
        redirectURL: URL,
        pkceSecrets: PKCESecrets,
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
                guard authCodeResponse.oauth.state == pkceSecrets.state else {
                    completion(.failure(.authCodeResponseStateMismatch))
                    return
                }
                self.deps
                    .api
                    .exchangeAuthCode
                    .execute(
                        with: .init(
                            code: authCodeResponse.oauth.code,
                            codeVerifier: pkceSecrets.codeVerifier,
                            redirectUri: redirectURL.absoluteString
                        )
                    ) { result in
                        completion(
                            result
                                .map {
                                    .init(
                                        accessToken: .init(from: $0),
                                        user: .init(from: authCodeResponse.user, response: $0)
                                    )
                                }
                                .mapError { AuthFlowError.authCodeExchangingFailed($0) }
                        )
                    }
            case .failure(let err):
                completion(.failure(err))
            }
        }
        self.webViewAuthStrategy = strategy
    }
}
