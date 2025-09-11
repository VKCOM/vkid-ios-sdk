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

internal enum APIError: Error {
    case invalidResponse
    case invalidRequest
}

internal struct API {
    private var debugSettings: DebugSettingsStorage
    private var host: String {
        if let template = self.debugSettings.customDomainTemplate, !template.isEmpty {
            return String(format: "\(template).vk.ru", "id")
        }
        return "id.vk.ru"
    }

    private var session = URLSession.shared

    enum ExchangeAuthCode {
        static internal let path = "/oauth2/auth"

        struct Response: Decodable {
            let accessToken: String
            let expiresIn: TimeInterval
            let refreshToken: String
            let idToken: String
            let userId: Int
            let state: String
            let scope: String
        }

        struct Parameters: DictionaryRepresentable, Encodable {
            let code: String
            let codeVerifier: String
            let grantType = "authorization_code"
            let redirectUri: String
            let state: String
            let deviceId: String
            let clientId: String
            let serviceToken: String
        }
    }

    public init(debugSettings: DebugSettingsStorage) {
        self.debugSettings = debugSettings
    }

    func exchangeAuthCode(
        _ parameters: ExchangeAuthCode.Parameters,
        completion: @escaping (Result<ExchangeAuthCode.Response, Error>) -> Void
    ) {
        var components = self.urlComponents(
            path: ExchangeAuthCode.path,
            parameters: parameters.dictionaryRepresentation
        )
        let data = components.percentEncodedQuery?.data(using: .utf8)
        components.queryItems = nil
        guard
            let url = components.url,
            let request = self.createURLRequest(url: url, method: "POST", data: data)
        else {
            completion(.failure(APIError.invalidRequest))
            return
        }
        self.execute(request: request, completion: completion)
    }

    private func urlComponents(path: String, parameters: [String: Any]) -> URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = self.host
        components.path = path
        components.queryItems = parameters
            .map { ($0.key, String(describing: $0.value)) }
            .map(URLQueryItem.init(name:value:))

        return components
    }

    private func createURLRequest(url: URL, method: String, data: Data? = nil) -> URLRequest? {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = data

        return request
    }

    private func execute(
        request: URLRequest,
        completion: @escaping (Result<ExchangeAuthCode.Response, Error>) -> Void
    ) {
        let task = self.session.dataTask(with: request) { data, response, error in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            guard
                let data,
                let exchangeAuthCodeResponse = try? decoder.decode(ExchangeAuthCode.Response.self, from: data)
            else {
                DispatchQueue.main.async {
                    completion(.failure(APIError.invalidResponse))
                }
                return
            }
            DispatchQueue.main.async {
                completion(.success(exchangeAuthCodeResponse))
            }
        }
        task.resume()
    }
}
