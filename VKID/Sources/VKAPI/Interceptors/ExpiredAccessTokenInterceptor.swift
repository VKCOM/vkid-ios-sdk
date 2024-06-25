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
import VKIDCore

internal final class ExpiredAccessTokenInterceptor: VKAPIResponseInterceptor {
    var userSessionManager: UserSessionManager?

    func intercept<T>(
        response: Result<T, VKAPIError>,
        from request: VKAPIRequest,
        completion: @escaping (VKAPIResponseInterceptionResult<T>) -> Void
    ) where T: VKAPIResponse {
        guard request.retryCount < 1,
              case .accessToken(let id) = request.authorization,
              case .failure(let responseError) = response,
              case .invalidAccessToken = responseError
        else {
            completion(.continue(request: request, response: response))
            return
        }
        var userSession: UserSession
        if let id {
            if let session = self.userSessionManager?.userSession(by: .init(value: id)) {
                userSession = session
            } else {
                completion(.interrupt(error: responseError))
                return
            }
        } else if let currentAuthorizedSession = self.userSessionManager?.currentAuthorizedSession {
            userSession = currentAuthorizedSession
        } else {
            completion(.interrupt(error: responseError))
            return
        }
        userSession.getFreshAccessToken(forceRefresh: true) { result in
            switch result {
            case .success((let accessToken, _)):
                var mutableRequest = request
                mutableRequest.retryCount += 1
                mutableRequest.addBearerToken(accessToken.value)
                completion(.retry(request: mutableRequest))
            case.failure:
                completion(.interrupt(error: responseError))
            }
        }
    }
}
