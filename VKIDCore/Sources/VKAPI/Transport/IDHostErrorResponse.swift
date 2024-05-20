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

internal enum IDHostError: String, UnknownCaseDecodable {
    case invalidRequest = "invalid_request"
    case invalidScope = "invalid_scope"
    case serverError = "server_error"
    case temporarilyUnavailable = "temporarily_unavailable"
    case invalidToken = "invalid_token"
    case slowDown = "slow_down"
    case accessDenied = "access_denied"
    case invalidClient = "invalid_client"
    case unknown
}

internal enum ErrorReason: String, UnknownCaseDecodable {
    case invalidRefreshToken = "refresh_token is missing or invalid"
    case unknown
}

internal struct IDHostErrorResponse: Decodable {
    let error: IDHostError
    let errorDescription: ErrorReason

    var apiError: VKAPIError {
        switch self.error {
        case .invalidRequest where self.errorDescription == .invalidRefreshToken:
            return .invalidRequest(reason: .invalidRefreshToken)
        case .invalidRequest:
            return .invalidRequest(reason: .unknown)
        case .serverError:
            return .serverError
        case .temporarilyUnavailable:
            return .temporarilyUnavailable
        case .invalidToken:
            return .invalidAccessToken
        case .slowDown:
            return .slowDown
        case .accessDenied:
            return .accessDenied
        case .invalidScope, .invalidClient, .unknown:
            return .unknown
        }
    }
}
