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
import UIKit
import VKCaptchaSDK
import VKIDCore

internal final class CaptchaPresenter: VKCaptchaPresenter {
    var presentingViewController: UIViewController?
    let presenter: UIKitPresenter

    init() {
        self.presenter = .newUIWindow
    }

    func navigate(
        viewController: UIViewController,
        presentationStyle: VKCaptchaSDK.VKCaptchaPresentationStyle
    ) {
        self.presentingViewController = viewController
        self.presenter.present(viewController)
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        if let presentingViewController {
            self.presenter.dismiss(
                presentingViewController,
                animated: animated,
                completion: completion
            )
        }
    }
}

internal final class CaptchaInterceptor: VKAPIResponseInterceptor {
    struct Dependencies: Dependency {
        var logger: Logging
    }

    internal var userSessionManager: UserSessionManager?
    private var isPresenting: Synchronized<Bool> = Synchronized(wrappedValue: false)
    private let vkCaptchaHandler = VKCaptchaHandler()
    private let deps: Dependencies

    init(deps: Dependencies) {
        self.deps = deps
    }

    func intercept<T>(
        response: Result<T, VKAPIError>,
        from request: VKAPIRequest,
        completion: @escaping (VKAPIResponseInterceptionResult<T>) -> Void
    ) where T: VKAPIResponse {
        guard request.retryCount < 3,
              case .failure(let responseError) = response,
              case .captcha(let captchaData) = responseError
        else {
            completion(.continue(request: request, response: response))
            return
        }
        DispatchQueue.main.async {
            self.handleCaptcha(from: request, captchaData: captchaData, completion: completion)
        }
    }

    private func handleCaptcha<T>(
        from request: VKAPIRequest,
        captchaData: VKCaptchaData,
        completion: @escaping (VKAPIResponseInterceptionResult<T>) -> Void
    ) where T: VKAPIResponse {
        if self.isPresenting.wrappedValue == false {
            self.isPresenting.wrappedValue = true
            self.vkCaptchaHandler.openCaptcha(
                captchaData: captchaData
            ) { [weak self] result in
                switch result {
                case .success(let token):
                    var newRequest = request
                    switch token.type {
                    case .domain:
                        newRequest.headers[VKCaptchaConstants.domainCaptchaHeaderName] = token.value
                    case .default:
                        newRequest.parameters[VKCaptchaConstants.defaultCaptchaParamName] = token.value
                    @unknown default:
                        self?.deps.logger.error("Unknown captcha token type")
                        completion(.interrupt(error: .notImplementedCaptcha))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self?.isPresenting.wrappedValue = false
                        }
                        return
                    }
                    newRequest.retryCount = request.retryCount + 1
                    completion(.retry(request: newRequest))
                case .failure(let error):
                    completion(.interrupt(error: .captchaError(error)))
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.isPresenting.wrappedValue = false
                }
            }
        } else {
            // TODO: handle more than 2 captcha calls
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.handleCaptcha(from: request, captchaData: captchaData, completion: completion)
            }
        }
    }
}
