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

internal final class RequestAuthorizationInterceptor: VKAPIRequestInterceptor {
    struct Dependencies {
        let anonymousTokenService: AnonymousTokenService
    }

    var userSessionManager: UserSessionManager?

    private var deps: Dependencies

    init(deps: Dependencies) {
        self.deps = deps
    }

    func intercept(
        request: VKAPIRequest,
        completion: @escaping (Result<VKAPIRequest, VKAPIError>) -> Void
    ) {
        func signRequest(
            _ request: VKAPIRequest,
            token: String,
            completion: @escaping (Result<VKAPIRequest, VKAPIError>) -> Void
        ) {
            var mutableRequest = request
            mutableRequest.addBearerToken(token)
            completion(.success(mutableRequest))
        }
        switch request.authorization {
        case .accessToken(let id):
            var userSession: UserSession
            if let id {
                if let session = self.userSessionManager?
                    .userSession(by: .init(value: id))
                {
                    userSession = session
                } else {
                    completion(.failure(.authorizedRequestWithoutSession))
                    return
                }
            } else if let currentAuthorizedSession = self.userSessionManager?.currentAuthorizedSession {
                userSession = currentAuthorizedSession
            } else {
                completion(.failure(.authorizedRequestWithoutSession))
                return
            }
            userSession.getFreshAccessToken { _ in
                signRequest(request,
                            token: userSession.accessToken.value,
                            completion: completion)
            }
        case .anonymousToken:
            self.deps.anonymousTokenService.getFreshToken { result in
                switch result {
                case .success(let token):
                    signRequest(request,
                                token: token.value,
                                completion: completion)
                case .failure(let error):
                    completion(.failure(.failedToGetAnonymousToken(error)))
                    return
                }
            }
        case .none:
            completion(.success(request))
            return
        }
    }
}
