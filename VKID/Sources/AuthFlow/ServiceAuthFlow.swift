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
import UIKit
import VKIDCore

internal final class ServiceAuthFlow: Component, AuthFlow {
    struct Dependencies: Dependency {
        var webViewAuthFlow: AuthFlow
        var authByProviderFlow: AuthFlow
        var appStateProvider: AppStateProvider
    }

    let deps: Dependencies
    private var appStateObserver: AnyObject?

    init(deps: Dependencies) {
        self.deps = deps
    }

    func authorize(
        with presenter: UIKitPresenter,
        completion: @escaping AuthFlowResultCompletion
    ) {
        self.deps.authByProviderFlow.authorize(with: presenter) { result in
            switch result {
            case .success(let success):
                completion(.success(success))
            case .failure:
                switch self.deps.appStateProvider.state {
                case .active:
                    self.deps.webViewAuthFlow.authorize(
                        with: presenter,
                        completion: completion
                    )
                default:
                    self.startWebViewAuthOnAppActivated(
                        with: presenter,
                        completion: completion
                    )
                }
            }
        }
    }

    private func startWebViewAuthOnAppActivated(
        with presenter: UIKitPresenter,
        completion: @escaping AuthFlowResultCompletion
    ) {
        self.appStateObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue
                .main
                .asyncAfter(
                    deadline: .now() + 0.5
                ) {
                    guard let self else {
                        completion(.failure(.authorizationFailed))
                        return
                    }
                    self.appStateObserver.map(NotificationCenter.default.removeObserver)
                    self.appStateObserver = nil
                    self.deps.webViewAuthFlow.authorize(
                        with: presenter,
                        completion: completion
                    )
                }
        }
    }

    deinit {
        self.appStateObserver.map(NotificationCenter.default.removeObserver)
    }
}
