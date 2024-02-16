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

public struct SSLPinnedDomain {
    public let domain: String
    public let pins: Set<Data>

    /// Создает SSLPinnedDomain с указанными `domain` и `pins`
    /// - Parameters:
    ///   - domain: домен для пининга
    ///   - pins: base64-encoded SHA-256 хеши публичных ключей сертификатов
    public init(domain: String, pins: Set<String>) {
        self.domain = domain
        self.pins = Set(
            pins.compactMap {
                Data(base64Encoded: $0, options: .ignoreUnknownCharacters)
            }
        )
    }
}

public struct SSLPinningConfiguration {
    private let domains: [String: SSLPinnedDomain]

    public init(domains: [SSLPinnedDomain]) {
        self.domains = domains.reduce(into: [:]) { partialResult, domain in
            partialResult[domain.domain] = domain
        }
    }

    public static let pinningDisabled = Self(domains: [])

    public func isDomainPinned(_ domain: String) -> Bool {
        if let pinned = self.domains[domain] {
            return !pinned.pins.isEmpty
        }
        if domain.isSubdomain, let rootDomain = domain.rootDomain {
            return self.isDomainPinned(rootDomain)
        }
        return false
    }

    public func isValidPin(_ pin: Data, for domain: String) -> Bool {
        if let pinned = self.domains[domain] {
            return pinned.pins.contains(pin)
        }
        if domain.isSubdomain, let rootDomain = domain.rootDomain {
            return self.isValidPin(pin, for: rootDomain)
        }
        return false
    }
}

extension String {
    fileprivate var isSubdomain: Bool {
        let components = self.components(separatedBy: ".")
        return components.count > 2
    }

    fileprivate var rootDomain: String? {
        let components = self.components(separatedBy: ".")
        if components.count >= 2 {
            return components.suffix(2).joined(separator: ".")
        }
        return nil
    }
}
