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

public struct VKAPIRequest {
    public typealias Parameters = [String: Any]
    public typealias Headers = [String: String]

    public enum HTTPMethod: String, Equatable {
        case post = "POST"
        case get = "GET"
    }

    /// Хост, на который будет отправлен запрос
    public enum Host: String {
        case id, api, oauth
    }

    public enum Authorization {
        case none
        case anonymousToken
        case accessToken
    }

    public let id: UUID = .init()
    public let host: Host
    public let path: String
    public let httpMethod: HTTPMethod
    public var parameters: Parameters
    public var headers: Headers
    public let authorization: Authorization
    public var retryCount: Int = 0

    public init(
        host: Host,
        path: String,
        httpMethod: HTTPMethod,
        parameters: Parameters = .init(),
        headers: Headers = .init(),
        authorization: Authorization
    ) {
        self.host = host
        self.path = path
        self.httpMethod = httpMethod
        self.parameters = parameters
        self.headers = headers
        self.authorization = authorization
    }
}

extension VKAPIRequest {
    public mutating func add(parameters: Parameters) {
        self.parameters = self.parameters.merging(
            parameters,
            uniquingKeysWith: { $1 }
        )
    }

    public mutating func add(headers: Headers, overwriteIfAlreadyExists: Bool = true) {
        self.headers = self.headers.merging(
            headers,
            uniquingKeysWith: { overwriteIfAlreadyExists ? $1 : $0 }
        )
    }
}
