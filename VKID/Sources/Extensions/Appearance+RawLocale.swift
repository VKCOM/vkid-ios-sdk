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

extension Appearance.Locale {
    static var preferredLocale: Self? {
        guard let lang = NSLocale.preferredLanguages.first?.prefix(2) else {
            return nil
        }
        switch lang {
        case "ru":
            return .ru
        case "uk":
            return .uk
        case "en":
            return .en
        case "es":
            return .es
        case "de":
            return .de
        case "pl":
            return .pl
        case "fr":
            return .fr
        case "tr":
            return .tr
        default:
            return nil
        }
    }

    internal var rawLocale: String? {
        switch self {
        case .system:
            return Self.preferredLocale.flatMap { $0.rawLocale }
        case .ru:
            return "0"
        case .uk:
            return "1"
        case .en:
            return "3"
        case .es:
            return "4"
        case .de:
            return "6"
        case .pl:
            return "15"
        case .fr:
            return "16"
        case .tr:
            return "82"
        }
    }
}
