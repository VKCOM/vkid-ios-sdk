//
// Copyright (c) 2024 - present, LLC “V Kontakte”
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
@testable import VKID
@testable import VKIDCore

extension URL {
    public static var authorize: Self {
        Self(string: "https://id.vk.com/authorize")!
    }

    public static func provider(appId: Int) -> Self {
        Self(string: "vk\(appId)://blank.html")!
    }

    public static func webViewAuthorize(
        authContext: AuthContext,
        secrets: PKCESecrets,
        credentials: AppCredentials,
        appearance: Appearance,
        scope: Scope?
    ) -> Self? {
        let baseURL: URL = .authorize

        guard
            let locale = Appearance.Locale(rawValue: appearance.locale.rawValue)?.rawLocale,
            var expectedURLComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        else {
            return nil
        }

        let expectedQueryItems: [URLQueryItem] = [
            .responseType("code"),
            .state(secrets.state),
            .codeChallenge(secrets.codeChallenge),
            .clientId(credentials.clientId),
            .scheme(appearance.colorScheme.rawValue),
            .langId(locale),
            .provider(oAuth: .vkid),
            .codeChallengeMethod(secrets.codeChallengeMethod.rawValue),
            .deviceId(DeviceId.currentDeviceId.description),
            .prompt("login"),
            .oAuthVersion,
            .version(Env.VKIDVersion),
            .scope(scope?.description ?? ""),
            .statsInfo(
                base64StatsInfo(
                    from: authContext
                )
            ),
            .redirectURI(
                redirectURL(
                    for: credentials.clientId
                ).absoluteString
            ),
        ]

        expectedURLComponents.queryItems = expectedQueryItems

        return expectedURLComponents.url
    }

    public static func fromProvider(
        authContext: AuthContext,
        appCredentials: AppCredentials,
        pkceSecrets: PKCESecrets,
        scope: Scope?,
        code: String,
        deviceId: String
    ) -> Self? {
        let baseURL: URL = .serviceApplication(with: appCredentials.clientId)

        guard var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let queryItems: [URLQueryItem] = [
            .oAuth2Params(
                oAuth2Parameters(
                    from: authContext,
                    with: scope?.description
                )
            ),
            .code(code),
            .expiresIn("600"),
            .deviceId(deviceId),
            .state(pkceSecrets.state),
            .type("code_v2"),
            .vkconnectAuthProviderMethod("external_auth"),
        ]

        urlComponents.queryItems = queryItems

        return urlComponents.url
    }

    public static func fromProviderWithError(
        appCredentials: AppCredentials
    ) -> Self? {
        let baseURL: URL = .serviceApplication(with: appCredentials.clientId)

        guard var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let queryItems: [URLQueryItem] = [
            .error(),
        ]

        urlComponents.queryItems = queryItems

        return urlComponents.url
    }

    public static func providerAuthorize(
        universalLink: URL,
        authContext: AuthContext,
        appCredentials: AppCredentials,
        pkceSecrets: PKCESecrets,
        scope: Scope? = nil
    ) -> Self? {
        guard var urlComponents = URLComponents(url: universalLink, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let queryItems: [URLQueryItem] = [
            .responseType("code"),
            .state(pkceSecrets.state),
            .codeChallenge(pkceSecrets.codeChallenge),
            .clientId(appCredentials.clientId),
            .vkconnectAuthProviderMethod("external_auth"),
            .redirectURI(
                redirectURL(
                    for: appCredentials.clientId,
                    in: authContext,
                    scope: scope?.description,
                    version: Env.VKIDVersion
                ).absoluteString
            ),
        ]

        urlComponents.queryItems = queryItems

        return urlComponents.url
    }
}

extension URLQueryItem {
    fileprivate static func code(_ code: String) -> Self {
        Self(
            name: "code",
            value: code
        )
    }

    fileprivate static func expiresIn(_ expiresIn: String) -> Self {
        Self(
            name: "expires_in",
            value: expiresIn
        )
    }

    fileprivate static func type(_ type: String) -> Self {
        Self(
            name: "type",
            value: type
        )
    }

    fileprivate static func vkconnectAuthProviderMethod(_ vkconnectAuthProviderMethod: String) -> Self {
        Self(
            name: "vkconnect_auth_provider_method",
            value: vkconnectAuthProviderMethod
        )
    }

    fileprivate static func error() -> Self {
        Self(
            name: "error",
            value: "some_error_data"
        )
    }
}
