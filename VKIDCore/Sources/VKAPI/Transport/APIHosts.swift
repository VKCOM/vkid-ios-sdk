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

package protocol APIHostStorage: AnyObject {
    func string(forKey defaultName: String) -> String?
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: APIHostStorage {}

package final class APIHosts {
    private enum Constants {
        static let defaultAPIHost = "api.vk.ru"
        static let defaultAPIHosts = [
            defaultAPIHost,
            "internal-sdk.api.vk.ru",
            "api.l.vk.ru",
            "api.r.vk.com",
        ]
        static let activeAPIHostKey = "com.vkid.apiHost"
    }

    private let id: String
    private let oauth: String
    private let api: [String]
    private let storage: APIHostStorage?
    private let lock = NSLock()
    private var activeAPIHost: String

    package init(
        template: String? = nil,
        hostname: String,
        storage: APIHostStorage? = UserDefaults.standard
    ) {
        func format(host: VKAPIRequest.Host) -> String {
            guard let template, !template.isEmpty else {
                return "\(host.rawValue).\(hostname)"
            }
            return String(format: "\(template).\(hostname)", host.rawValue)
        }
        self.id = format(host: .id)
        self.oauth = format(host: .oauth)
        let api = format(host: .api)
        let apiHosts = api == Constants.defaultAPIHost
            ? Constants.defaultAPIHosts
            : [api]
        self.api = apiHosts
        self.storage = storage
        self.activeAPIHost = storage?
            .string(forKey: Constants.activeAPIHostKey)
            .flatMap { apiHosts.contains($0) ? $0 : nil }
            ?? apiHosts[0]
    }

    package func getHostBy(requestHost: VKAPIRequest.Host) -> String {
        switch requestHost {
        case .api:
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.activeAPIHost
        case .id:
            return self.id
        case .oauth:
            return self.oauth
        }
    }

    package func switchToNextAPIHost(after host: String) -> String? {
        self.lock.lock()
        defer { self.lock.unlock() }

        guard
            self.api.count > 1,
            let currentIndex = self.api.firstIndex(where: { $0.caseInsensitiveCompare(host) == .orderedSame })
        else {
            return nil
        }

        let nextIndex = self.api.index(after: currentIndex)
        let nextHost = nextIndex == self.api.endIndex ? self.api[0] : self.api[nextIndex]
        self.activeAPIHost = nextHost
        self.storage?.set(nextHost, forKey: Constants.activeAPIHostKey)
        return nextHost
    }
}
