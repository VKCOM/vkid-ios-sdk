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

package protocol URLRequestBuilding {
    func buildURLRequest(from request: VKAPIRequest) throws -> URLRequest
}

package final class URLRequestBuilder: URLRequestBuilding {
    private let apiHosts: APIHosts

    package init(apiHosts: APIHosts) {
        self.apiHosts = apiHosts
    }

    package func buildURLRequest(from request: VKAPIRequest) throws -> URLRequest {
        var urlRequest: URLRequest
        var components = self.urlComponents(for: request)

        switch request.httpMethod {
        case .post:
            var componentsWithoutQuery = components
            componentsWithoutQuery.queryItems = request.domainCaptcha ? [.init(name: "hitman", value: "ban")] : nil
            guard let url = componentsWithoutQuery.url else {
                throw VKAPIError.invalidRequest(reason: .invalidURL)
            }
            urlRequest = URLRequest(url: url)
            urlRequest.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        case .get:
            if request.domainCaptcha {
                components.queryItems?.append(.init(name: "hitman", value: "ban"))
            }
            guard let url = components.url else {
                throw VKAPIError.invalidRequest(reason: .invalidURL)
            }
            urlRequest = URLRequest(url: url)
        }

        urlRequest.httpMethod = request.httpMethod.rawValue
        urlRequest.allHTTPHeaderFields = urlRequest
            .allHTTPHeaderFields?
            .merging(
                request.headers,
                uniquingKeysWith: { $1 }
            )
        return urlRequest
    }

    private func urlComponents(for request: VKAPIRequest) -> URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = self.apiHosts.getHostBy(requestHost: request.host)
        components.path = request.path
        if !request.parameters.isEmpty {
            var queryItems = request.parameters
                .map { ($0.key, String(describing: $0.value)) }
                .map(URLQueryItem.init(name:value:))
            components.queryItems = queryItems
        }

        return components
    }
}
