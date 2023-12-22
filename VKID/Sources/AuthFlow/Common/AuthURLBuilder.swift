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

internal protocol AuthURLBuilder {
    func buildProviderAuthURL(
        from templateURLString: String,
        with secrets: PKCESecrets,
        credentials: AppCredentials
    ) throws -> URL

    func buildWebViewAuthURL(
        from templateURLString: String,
        for oAuth: OAuthProvider,
        with secrets: PKCESecrets,
        credentials: AppCredentials,
        appearance: Appearance
    ) throws -> URL
}

internal final class AuthURLBuilderImpl: AuthURLBuilder {
    func buildProviderAuthURL(
        from templateURLString: String,
        with secrets: PKCESecrets,
        credentials: AppCredentials
    ) throws -> URL {
        let queryItems: [URLQueryItem] = [
            .authProviderMethod,
            .init(
                name: "client_id",
                value: credentials.clientId
            ),
        ]
        return try self.buildAuthUrl(
            from: templateURLString,
            with: secrets,
            credentials: credentials,
            additionalQueryItems: queryItems
        )
    }

    func buildWebViewAuthURL(
        from templateURLString: String,
        for provider: OAuthProvider,
        with secrets: PKCESecrets,
        credentials: AppCredentials,
        appearance: Appearance
    ) throws -> URL {
        var queryItems: [URLQueryItem] = appearance.urlQueryItems
        queryItems.append(.sdkOauthJson(oAuth: provider))

        return try self.buildAuthUrl(
            from: templateURLString,
            with: secrets,
            credentials: credentials,
            additionalQueryItems: queryItems
        )
    }

    private func buildAuthUrl(
        from templateURLString: String,
        with secrets: PKCESecrets,
        credentials: AppCredentials,
        additionalQueryItems: [URLQueryItem]
    ) throws -> URL {
        guard
            let encodedTemplate = templateURLString
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                var components = URLComponents(string: encodedTemplate)
        else {
            throw AuthFlowError.invalidAuthConfigTemplateURL
        }

        var queryItems = components
            .queryItems?
            .filter { !$0.isTemplate }
            ?? []
        queryItems += self.сommonQueryItems(
            clientId: credentials.clientId,
            secrets: secrets
        )
        queryItems += additionalQueryItems

        components.queryItems = queryItems
        if let url = components.url {
            return url
        }
        throw AuthFlowError.invalidAuthConfigTemplateURL
    }

    private func сommonQueryItems(clientId: String, secrets: PKCESecrets) -> [URLQueryItem] {
        [
            .init(
                name: "redirect_uri",
                value: redirectURL(for: clientId).absoluteString
            ),
            .init(
                name: "response_type",
                value: "code"
            ),
            .init(
                name: "state",
                value: secrets.state
            ),
            .init(
                name: "code_challenge",
                value: secrets.codeChallenge
            ),
            .init(
                name: "code_challenge_method",
                value: secrets.codeChallengeMethod.rawValue
            ),
        ]
    }
}

internal func redirectURL(for clientId: String) -> URL {
    URL(string: "vk\(clientId)://vk.com/blank.html")!
}

extension URLQueryItem {
    internal var isTemplate: Bool {
        if let value {
            return value.contains("{\(self.name)}")
        }
        return false
    }
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
                return UIScreen
                    .main
                    .traitCollection
                    .userInterfaceStyle
                    .colorScheme
                    .flatMap(rawColorScheme(_:))
            case .light:
                return "bright_light"
            case .dark:
                return "space_gray"
            }
        }
        return rawColorScheme(self.colorScheme).map {
            URLQueryItem(name: "scheme", value: $0)
        }
    }

    private var localeQueryItem: URLQueryItem? {
        func rawLocale(_ locale: Appearance.Locale) -> String? {
            switch locale {
            case .system:
                return preferredLocale().flatMap(rawLocale(_:))
            case .ru:
                return "0"
            case .uk:
                return "1"
            case .en:
                return "3"
            case .es:
                return "4"
            case .de:
                return "6"
            case .pl:
                return "15"
            case .fr:
                return "16"
            case .tr:
                return "82"
            }
        }
        return rawLocale(self.locale).map {
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

extension URLQueryItem {
    internal static let authProviderMethod = Self(name: "vkconnect_auth_provider_method", value: "external_auth")

    internal static func sdkOauthJson(oAuth: OAuthProvider) -> Self {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        struct SDKOAuth: Encodable {
            struct OAuth: Encodable {
                let oauth: String
            }

            let name: String = "sdk_oauth"
            let params: OAuth

            init(oauth: String) {
                self.params = OAuth(oauth: oauth)
            }
        }

        return Self(
            name: "action",
            value: try? encoder.encode(
                SDKOAuth(
                    oauth: oAuth.type.rawValue
                )
            ).base64EncodedString()
        )
    }
}

private func preferredLocale() -> Appearance.Locale? {
    guard let lang = NSLocale.preferredLanguages.first?.prefix(2) else {
        return nil
    }
    switch lang {
    case "ru":
        return .ru
    case "uk":
        return .uk
    case "en":
        return .en
    case "es":
        return .es
    case "de":
        return .de
    case "pl":
        return .pl
    case "fr":
        return .fr
    case "tr":
        return .tr
    default:
        return nil
    }
}
