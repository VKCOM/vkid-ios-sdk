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

protocol OAuth2MigrationService {
    func migrate(
        accessToken: String,
        pkceSecrets: PKCESecretsWallet,
        completion: @escaping(Result<AuthCodeResponse, Error>) -> Void
    )
}

internal final class OAuth2MigrationServiceImpl: OAuth2MigrationService, Dependency {
    struct Dependencies: Dependency {
        let api: VKAPI<OAuth2>
        let appCredentials: AppCredentials
        let deviceId: DeviceId
    }

    private let deps: Dependencies

    internal init(deps: Dependencies) {
        self.deps = deps
    }

    func migrate(
        accessToken: String,
        pkceSecrets: PKCESecretsWallet,
        completion: @escaping(Result<AuthCodeResponse, any Error>) -> Void
    ) {
        do {
            let state = try pkceSecrets.state
            let codeChallengeMethod = try pkceSecrets.codeChallengeMethod.rawValue
            let codeChallenge = try pkceSecrets.codeChallenge
            self.deps
                .api
                .oAuth2Migration
                .execute(with: .init(
                    codeChallenge: codeChallenge,
                    codeChallengeMethod: codeChallengeMethod,
                    accessToken: accessToken,
                    clientId: self.deps.appCredentials.clientId,
                    deviceId: self.deps.deviceId.description,
                    state: state
                )) { result in
                    switch result {
                    case .success(let response):
                        completion(.success(.init(from: response)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
        } catch let error {
            completion(.failure(error))
        }
    }
}

extension AuthCodeResponse {
    fileprivate init(from response: OAuth2.OAuth2Migration.Response) {
        self.init(code: response.code,
                  state: response.state,
                  serverProvidedDeviceId: response.deviceId)
    }
}
