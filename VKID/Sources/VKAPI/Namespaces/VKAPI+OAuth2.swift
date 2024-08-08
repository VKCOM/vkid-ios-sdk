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

internal struct OAuth2: VKAPINamespace {
    fileprivate enum GrantType: String {
        case authorizationCode = "authorization_code"
        case refreshToken = "refresh_token"
        case accessToken = "access_token"
    }

    struct ExchangeAuthCode: VKAPIMethod {
        struct Response: VKAPIResponse {
            let accessToken: String
            let expiresIn: TimeInterval
            let refreshToken: String
            let idToken: String
            let userId: Int
            let state: String
            let scope: String
        }

        struct Parameters: VKAPIDictionaryRepresentable {
            let code: String
            let codeVerifier: String
            let grantType = GrantType.authorizationCode.rawValue
            let redirectUri: String
            let state: String
            let deviceId: String
            let clientId: String
        }

        static func request(with parameters: Parameters, for userId: Int?) -> VKAPIRequest {
            VKAPIRequest(
                host: .id,
                path: "/oauth2/auth",
                httpMethod: .post,
                parameters: parameters.dictionaryRepresentation,
                authorization: .none
            )
        }
    }

    struct RefreshToken: VKAPIMethod {
        struct Response: VKAPIResponse, Encodable {
            let refreshToken: String
            let accessToken: String
            let state: String
            let expiresIn: TimeInterval
            let userId: Int
            let scope: String
        }

        struct Parameters: VKAPIDictionaryRepresentable {
            let grantType = GrantType.refreshToken.rawValue
            let refreshToken: String
            let clientId: String
            let deviceId: String
            let state: String
        }

        static func request(with parameters: Parameters, for userId: Int?) -> VKAPIRequest {
            VKAPIRequest(
                host: .id,
                path: "/oauth2/auth",
                httpMethod: .post,
                parameters: parameters.dictionaryRepresentation,
                authorization: .none
            )
        }
    }

    struct UserInfo: VKAPIMethod {
        struct User: Codable {
            let firstName: String?
            let lastName: String?
            let phone: String?
            let avatar: String?
            let email: String?
        }

        struct Response: VKAPIResponse, Encodable {
            let user: User
        }

        struct Parameters: VKAPIDictionaryRepresentable {
            let clientId: String
            let deviceId: String
        }

        static func request(with parameters: Parameters, for userId: Int?) -> VKAPIRequest {
            VKAPIRequest(
                host: .id,
                path: "/oauth2/user_info",
                httpMethod: .post,
                parameters: parameters.dictionaryRepresentation,
                authorization: .accessToken(userId: userId)
            )
        }
    }

    struct Logout: VKAPIMethod {
        struct Response: VKAPIResponse, Encodable {
            let response: Int
        }

        struct Parameters: VKAPIDictionaryRepresentable {
            let clientId: String
            let deviceId: String
            let accessToken: String
        }

        static func request(with parameters: Parameters, for userId: Int?) -> VKAPIRequest {
            var dictionary = parameters.dictionaryRepresentation
            dictionary.removeValue(forKey: "access_token")
            var request = VKAPIRequest(
                host: .id,
                path: "/oauth2/logout",
                httpMethod: .post,
                parameters: dictionary,
                authorization: .none
            )
            request.addBearerToken(parameters.accessToken)

            return request
        }
    }

    struct OAuth2Migration: VKAPIMethod {
        struct Response: VKAPIResponse {
            let code: String
            let deviceId: String
            let state: String
        }

        struct Parameters: VKAPIDictionaryRepresentable {
            let grantType = GrantType.accessToken.rawValue
            let responseType = "code"
            let codeChallenge: String
            let codeChallengeMethod: String
            let accessToken: String
            let clientId: String
            let deviceId: String
            let state: String
        }

        static func request(with parameters: Parameters, for userId: Int?) -> VKAPIRequest {
            VKAPIRequest(
                host: .id,
                path: "/oauth2/auth",
                httpMethod: .post,
                parameters: parameters.dictionaryRepresentation,
                authorization: .none
            )
        }
    }

    var exchangeAuthCode: ExchangeAuthCode { Never() }
    var refreshToken: RefreshToken { Never() }
    var userInfo: UserInfo { Never() }
    var logout: Logout { Never() }
    var oAuth2Migration: OAuth2Migration { Never() }
}

extension OAuth2.Logout.Response {
    var isSuccess: Bool {
        self.response == 1
    }
}
