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

internal struct AuthCodeResponse: Codable, Equatable {
    let oauth: OAuthResponse
    let user: UserData

    struct UserData: Codable, Equatable {
        let id: Int
        let firstName: String
        let lastName: String
        let email: String?
        let avatar: URL?
    }

    struct OAuthResponse: Codable, Equatable {
        internal let code: String
        internal let state: String
    }
}

internal protocol AuthCodeResponseParser {
    func parseAuthCodeResponse(from url: URL) throws -> AuthCodeResponse
    func parseCallbackMethod(from url: URL) throws -> String?
}

internal final class AuthCodeResponseParserImpl: AuthCodeResponseParser {
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    func parseAuthCodeResponse(from url: URL) throws -> AuthCodeResponse {
        guard
            let queryItems = queryItems(from: url),
            let payload = queryItems
                .first(where: { $0.name == "payload" })?
                .value
        else {
            throw AuthFlowError.invalidAuthCallbackURL
        }
        guard let payloadData = payload.data(using: .utf8) else {
            throw AuthFlowError.invalidAuthCodePayloadJSON
        }

        do {
            return try self.jsonDecoder.decode(
                AuthCodeResponse.self,
                from: payloadData
            )
        } catch {
            throw AuthFlowError.invalidAuthCodePayloadJSON
        }
    }

    func parseCallbackMethod(from url: URL) throws -> String? {
        guard
            let queryItems = queryItems(from: url),
            let method = queryItems
                .first(where: { $0.name == URLQueryItem.authProviderMethod.name })?
                .value
        else {
            throw AuthFlowError.invalidAuthCallbackURL
        }

        return method
    }

    private func queryItems(from url: URL) -> [URLQueryItem]? {
        let components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        )

        return components?.queryItems
    }
}
