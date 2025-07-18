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

internal struct Auth: VKAPINamespace {
    struct GetAnonymousToken: VKAPIMethod {
        struct Response: VKAPIResponse {
            let token: String
            let expiredAt: Date
        }

        struct Parameters: VKAPIDictionaryRepresentable {
            let anonymousToken: String?
            let clientId: String
            let clientSecret: String
        }

        static func request(with parameters: Parameters, for userId: Int?) -> VKAPIRequest {
            VKAPIRequest(
                host: .oauth,
                path: "/oauth/get_anonym_token",
                httpMethod: .post,
                parameters: parameters.dictionaryRepresentation,
                authorization: .none
            )
        }
    }

    struct GetAuthProviders: VKAPIMethod {
        struct Response: VKAPIResponse {
            let items: [Provider]
        }

        struct Provider: Decodable {
            let appId: Int
            let weight: Int
            let universalLink: URL
            let isProvider: Bool
        }

        struct Parameters: VKAPIDictionaryRepresentable {
            let extended = true
        }

        static func request(with parameters: Parameters, for userId: Int?) -> VKAPIRequest {
            VKAPIRequest(
                host: .api,
                path: "/method/auth.getVKConnectSettings",
                httpMethod: .post,
                parameters: parameters.dictionaryRepresentation,
                authorization: .anonymousToken
            )
        }
    }

    struct LegacyLogout: VKAPIMethod {
        typealias Response = SingleValueContainer<Int>

        struct Parameters: VKAPIDictionaryRepresentable {
            let clientId: String
            let accessToken: String
        }

        static func request(with parameters: Parameters, for userId: Int?) -> VKAPIRequest {
            VKAPIRequest(
                host: .api,
                path: "/method/auth.logout",
                httpMethod: .post,
                parameters: parameters.dictionaryRepresentation,
                authorization: .none
            )
        }
    }

    struct CaptchaDomain: VKAPIMethod {
        struct Response: VKAPIResponse {
            let items: [Provider]
        }

        struct Provider: Decodable {
            let appId: Int
            let weight: Int
            let universalLink: URL
            let isProvider: Bool
        }

        struct Parameters: VKAPIDictionaryRepresentable {
            let extended = true
        }

        static func request(with parameters: Parameters, for userId: Int?) -> VKAPIRequest {
            VKAPIRequest(
                host: .api,
                path: "/method/auth.getVKConnectSettings",
                httpMethod: .post,
                parameters: parameters.dictionaryRepresentation,
                authorization: .anonymousToken,
                domainCaptcha: true
            )
        }
    }

    struct CaptchaDefault: VKAPIMethod {
        static func request(with parameters: Parameters, for userId: Int?) -> VKIDCore.VKAPIRequest {
            VKAPIRequest(
                host: .api,
                path: "/method/captcha.force",
                httpMethod: .get,
                parameters: parameters.dictionaryRepresentation,
                authorization: .none,
                onlyVersionGenericHeader: true
            )
        }

        typealias Response = SingleValueContainer<Int>

        struct Parameters: VKAPIDictionaryRepresentable {}
    }

    struct CaptchaCombined: VKAPIMethod {
        static func request(with parameters: Parameters, for userId: Int?) -> VKIDCore.VKAPIRequest {
            VKAPIRequest(
                host: .api,
                path: "/method/captcha.force",
                httpMethod: .get,
                parameters: parameters.dictionaryRepresentation,
                authorization: .none,
                domainCaptcha: true,
                onlyVersionGenericHeader: true
            )
        }

        typealias Response = SingleValueContainer<Int>

        struct Parameters: VKAPIDictionaryRepresentable {}
    }

    var captchaDomain: CaptchaDomain { Never() }
    var captchaDefault: CaptchaDefault { Never() }
    var captchaCombined: CaptchaCombined { Never() }
    var legacyLogout: LegacyLogout { Never() }
    var getAuthProviders: GetAuthProviders { Never() }
    var getAnonymousToken: GetAnonymousToken { Never() }
}
