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

internal protocol AuthURLBuilder {
    func buildProviderAuthURL(
        baseURL: URL,
        authContext: AuthContext,
        secrets: PKCESecretsWallet,
        credentials: AppCredentials,
        scope: String?,
        deviceId: String
    ) throws -> URL

    func buildWebViewAuthURL(
        baseURL: URL,
        oAuthProvider: OAuthProvider,
        authContext: AuthContext,
        secrets: PKCESecretsWallet,
        credentials: AppCredentials,
        scope: String?,
        deviceId: String,
        appearance: Appearance
    ) throws -> URL
}

private let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.outputFormatting = .sortedKeys
    return encoder
}()

internal final class AuthURLBuilderImpl: AuthURLBuilder {
    func buildProviderAuthURL(
        baseURL: URL,
        authContext: AuthContext,
        secrets: PKCESecretsWallet,
        credentials: AppCredentials,
        scope: String?,
        deviceId: String
    ) throws -> URL {
        let queryItems: [URLQueryItem] = [
            .authProviderMethod,
            .redirectURI(
                redirectURL(
                    for: credentials.clientId,
                    in: authContext,
                    scope: scope
                ).absoluteString
            ),
        ]

        return try self.buildAuthUrl(
            baseURL: baseURL,
            secrets: secrets,
            credentials: credentials,
            deviceId: deviceId,
            additionalQueryItems: queryItems
        )
    }

    func buildWebViewAuthURL(
        baseURL: URL,
        oAuthProvider: OAuthProvider,
        authContext: AuthContext,
        secrets: PKCESecretsWallet,
        credentials: AppCredentials,
        scope: String?,
        deviceId: String,
        appearance: Appearance
    ) throws -> URL {
        guard let codeChallengeMethod = (try? secrets.codeChallengeMethod.rawValue) else {
            throw AuthFlowError.authOverdue
        }
        var queryItems: [URLQueryItem] = appearance.urlQueryItems
        queryItems += [
            .provider(oAuth: oAuthProvider),
            .codeChallengeMethod(codeChallengeMethod),
            .deviceId(deviceId),
            .prompt("login"),
            .oAuthVersion,
            .scope(scope ?? ""),
            .redirectURI(
                redirectURL(
                    for: credentials.clientId,
                    in: authContext
                ).absoluteString
            ),
        ]

        return try self.buildAuthUrl(
            baseURL: baseURL,
            secrets: secrets,
            credentials: credentials,
            deviceId: deviceId,
            additionalQueryItems: queryItems
        )
    }

    private func buildAuthUrl(
        baseURL: URL,
        secrets: PKCESecretsWallet,
        credentials: AppCredentials,
        deviceId: String,
        additionalQueryItems: [URLQueryItem]
    ) throws -> URL {
        guard
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        else {
            throw AuthFlowError.invalidAuthConfigTemplateURL
        }

        var queryItems = components.queryItems ?? []
        queryItems += try self.сommonQueryItems(
            clientId: credentials.clientId,
            secrets: secrets,
            deviceId: deviceId
        )
        queryItems += additionalQueryItems

        components.queryItems = queryItems
        if let url = components.url {
            return url
        }
        throw AuthFlowError.invalidAuthConfigTemplateURL
    }

    private func сommonQueryItems(
        clientId: String,
        secrets: PKCESecretsWallet,
        deviceId: String
    ) throws -> [URLQueryItem] {
        [
            .responseType("code"),
            .state(try secrets.state),
            .codeChallenge(try secrets.codeChallenge),
            .clientId(clientId),
        ]
    }
}

internal func redirectURL(for clientId: String, in context: AuthContext, scope: String? = nil) -> URL {
    var components = URLComponents.using(
        url: .serviceApplication(
            with: clientId,
            host: "\(Env.apiHost)/blank.html"
        )
    )

    let oAuth2Params = oAuth2Parameters(
        from: context,
        with: scope
    )

    if let oAuth2Params {
        components.queryItems = [
            .oAuth2Params(oAuth2Params),
        ]
    }

    return components.url!
}

internal func statsInfo(from authContext: AuthContext, shouldBeBase64Encoded: Bool) -> String? {
    struct StatsInfo: Encodable {
        let sessionId: String
        let flowSource: String
    }

    let statsInfo = StatsInfo(
        sessionId: authContext.uniqueSessionId,
        flowSource: authContext.flowSource
    )

    guard var jsonData = try? encoder.encode(statsInfo) else { return nil }

    if shouldBeBase64Encoded {
        jsonData = jsonData.base64EncodedData()
    }

    return String(
        data: jsonData ,
        encoding: .utf8
    )
}

internal func oAuth2Parameters(from authContext: AuthContext, with scope: String?) -> String? {
    struct OAuth2Parameters: Encodable {
        let scope: String?
        let statsInfo: String?
    }

    let oAuth2Parameters = OAuth2Parameters(
        scope: scope,
        statsInfo: statsInfo(from: authContext, shouldBeBase64Encoded: false)
    )

    guard let jsonData = try? encoder.encode(oAuth2Parameters) else { return nil }

    return String(
        data: jsonData.base64EncodedData(),
        encoding: .utf8
    )
}

extension Appearance {
    fileprivate var urlQueryItems: [URLQueryItem] {
        var result = [URLQueryItem]()
        self.colorSchemeQueryItem.map { result.append($0) }
        self.localeQueryItem.map { result.append($0) }
        return result
    }

    private var colorSchemeQueryItem: URLQueryItem? {
        func rawColorScheme(_ theme: Appearance.ColorScheme) -> String? {
            switch theme {
            case .system:
                return rawColorScheme(
                    theme.resolveSystemToActualScheme()
                )
            case .light:
                return "light"
            case .dark:
                return "dark"
            }
        }
        return rawColorScheme(self.colorScheme).map {
            .scheme($0)
        }
    }

    private var localeQueryItem: URLQueryItem? {
        self.locale.rawLocale.map {
            URLQueryItem(name: "lang_id", value: $0)
        }
    }
}

extension UIUserInterfaceStyle {
    fileprivate var colorScheme: Appearance.ColorScheme? {
        switch self {
        case .unspecified:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        @unknown default:
            return nil
        }
    }
}

extension URL {
    internal static func serviceApplication(with clientId: String, host: String = "") -> Self {
        Self(string: "vk\(clientId)://\(host)")!
    }
}

extension URLComponents {
    internal static func using(url: URL) -> Self {
        Self(string: url.absoluteString)!
    }
}

extension URLQueryItem {
    internal static let authProviderMethod = Self(name: "vkconnect_auth_provider_method", value: "external_auth")

    internal static func provider(oAuth: OAuthProvider) -> Self {
        Self(
            name: "provider",
            value: oAuth.type.rawValue
        )
    }

    internal static func codeChallengeMethod(_ codeChallengeMethod: String) -> Self {
        Self(
            name: "code_challenge_method",
            value: codeChallengeMethod
        )
    }

    internal static func deviceId(_ deviceId: String) -> Self {
        Self(
            name: "device_id",
            value: deviceId
        )
    }

    internal static func prompt(_ prompt: String) -> Self {
        Self(
            name: "prompt",
            value: prompt
        )
    }

    internal static func redirectURI(_ redirectURI: String) -> Self {
        Self(
            name: "redirect_uri",
            value: redirectURI
        )
    }

    internal static func responseType(_ responseType: String) -> Self {
        Self(
            name: "response_type",
            value: responseType
        )
    }

    internal static func state(_ state: String) -> Self {
        Self(
            name: "state",
            value: state
        )
    }

    internal static func codeChallenge(_ codeChallenge: String) -> Self {
        Self(
            name: "code_challenge",
            value: codeChallenge
        )
    }

    internal static func clientId(_ clientId: String) -> Self {
        Self(
            name: "client_id",
            value: clientId
        )
    }

    internal static func scheme(_ scheme: String) -> Self {
        Self(
            name: "scheme",
            value: scheme
        )
    }

    internal static func langId(_ langId: String) -> Self {
        Self(
            name: "lang_id",
            value: langId
        )
    }

    internal static func oAuth2Params(_ oAuth2Params: String?) -> Self {
        Self(
            name: "oauth2_params",
            value: oAuth2Params
        )
    }

    internal static let oAuthVersion = Self(name: "oauth_version", value: "2")

    internal static func scope(_ scope: String?) -> Self {
        Self(
            name: "scope",
            value: scope
        )
    }
}
