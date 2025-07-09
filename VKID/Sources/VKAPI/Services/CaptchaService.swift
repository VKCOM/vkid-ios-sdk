//
// Copyright (c) 2025 - present, LLC “V Kontakte”
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
import VKCaptchaSDK
import VKIDCore

@_spi(VKIDDebug)
public enum CaptchaError: Error {
    case error(Error)
    case unknown
}

@_spi(VKIDDebug)
public protocol CaptchaService {
    func fetchDomainCaptcha(completion: @escaping (Result<Bool, CaptchaError>) -> Void)
    func fetchDefaultCaptcha(completion: @escaping (Result<Bool, CaptchaError>) -> Void)
    func fetchCombinedCaptcha(completion: @escaping (Result<Bool, CaptchaError>) -> Void)
}

internal final class CaptchaServiceImpl: CaptchaService {
    func fetchCombinedCaptcha(completion: @escaping (Result<Bool, CaptchaError>) -> Void) {
        self.deps.apiAuth.captchaCombined.execute(
            with: .init()
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response.value == 1))
            case .failure(let error):
                switch error {
                case .captchaError(let captchaError):
                    completion(.failure(.error(captchaError)))
                default:
                    completion(.failure(.unknown))
                }
            }
        }
    }

    func fetchDefaultCaptcha(completion: @escaping (Result<Bool, CaptchaError>) -> Void) {
        self.deps.apiAuth.captchaDefault.execute(
            with: .init()
        ) { result in
            switch result {
            case .success(let response):
                completion(.success(response.value == 1))
            case .failure(let error):
                switch error {
                case .captchaError(let captchaError):
                    completion(.failure(.error(captchaError)))
                default:
                    completion(.failure(.unknown))
                }
            }
        }
    }

    func fetchDomainCaptcha(completion: @escaping (Result<Bool, CaptchaError>) -> Void) {
        self.deps.apiAuth.captchaDomain.execute(
            with: .init()
        ) { result in
            switch result {
            case .success:
                completion(.success(true))
            case .failure(let error):
                switch error {
                case .captchaError(let captchaError):
                    completion(.failure(.error(captchaError)))
                default:
                    completion(.failure(.unknown))
                }
            }
        }
    }

    struct Dependencies: Dependency {
        let apiAuth: VKAPI<Auth>
    }

    /// Зависимости сервиса
    private let deps: Dependencies

    /// Инициализация сервиса.
    /// - Parameter deps: Зависимости.
    init(deps: Dependencies) {
        self.deps = deps
    }
}
