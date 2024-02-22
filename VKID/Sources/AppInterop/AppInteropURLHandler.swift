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
@_implementationOnly import VKIDCore

internal protocol AppInteropURLHandler: AnyObject {
    func open(url: URL) -> Bool
}

internal protocol AppInteropURLOpening {
    func openApp(
        universalLink: URL,
        fallbackDeepLink: URL?,
        completion: @escaping (Bool) -> Void
    )
}

internal final class AppInteropCompositeHandler: AppInteropURLOpening, AppInteropURLHandler {
    private var handlers: [AppInteropURLHandler] = []

    func open(url: URL) -> Bool {
        self.handlers.contains { item in
            item.open(url: url)
        }
    }

    internal func attach(handler: AppInteropURLHandler) {
        guard !self.handlers.contains(byReference: handler) else {
            return
        }
        self.handlers.append(handler)
    }

    internal func detach(handler: AppInteropURLHandler) {
        self.handlers.removeByReference(handler)
    }

    func openApp(
        universalLink: URL,
        fallbackDeepLink: URL?,
        completion: @escaping (Bool) -> Void
    ) {
        UIApplication.shared.open(
            universalLink,
            options: [.universalLinksOnly: true],
            completionHandler: { success in
                if success {
                    completion(true)
                } else {
                    guard let deepLink = fallbackDeepLink else {
                        completion(false)
                        return
                    }
                    UIApplication.shared.open(
                        deepLink,
                        options: [:],
                        completionHandler: { success in
                            completion(success)
                        }
                    )
                }
            }
        )
    }
}

internal final class ClosureBasedURLHandler: AppInteropURLHandler {
    private let closure: (URL) -> Bool

    init(closure: @escaping (URL) -> Bool) {
        self.closure = closure
    }

    func open(url: URL) -> Bool {
        self.closure(url)
    }
}
