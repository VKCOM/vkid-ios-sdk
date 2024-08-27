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
@testable import VKID

protocol HumanReadableDescription {
    var rawDescription: String { get }
}

extension OneTapButton.Appearance.Title?: HumanReadableDescription {
    public var rawDescription: String {
        "Title " + (self ?? .vkid).rawType.rawValue
    }
}

extension OneTapButton.Appearance.Style: HumanReadableDescription {
    public var rawDescription: String {
        let logo = switch self.logo {
        case .vkidPrimary: "Primary"
        case .vkidSecondary: "Secondary"
        default:
            "unknown"
        }
        return "Style \(self.rawType.rawValue.capitalized) Image \(logo)"
    }
}

extension OneTapButton.Appearance.Theme: HumanReadableDescription {
    public var rawDescription: String {
        "Theme \(self.colorScheme.rawValue.description.capitalized)"
    }
}

extension OneTapButton.Layout.Height: HumanReadableDescription {
    var rawDescription: String {
        "Height \(Int(self.rawValue).description)"
    }
}

extension OneTapButton.Layout.Kind: HumanReadableDescription {
    var rawDescription: String {
        "Kind \(self.rawValue.description)"
    }
}

extension CGFloat: HumanReadableDescription {
    var rawDescription: String {
        "Corner radius \(Int(self).description)"
    }
}

extension [OAuthProvider]: HumanReadableDescription {
    var rawDescription: String {
        "Providers " + self.map {
            switch $0 {
            case .mail: "Mail"
            case.ok: "Ok"
            case.vkid: "VKID"
            default: "unknown"
            }
        }.joined(separator: " ")
    }
}

extension OneTapBottomSheet.TargetActionText: HumanReadableDescription {
    var rawDescription: String {
        self.title
    }
}

extension OneTapBottomSheet.Theme: HumanReadableDescription {
    var rawDescription: String {
        "Theme \(self.colorScheme.rawValue.description.capitalized)"
    }
}

extension OAuthListWidget.Theme: HumanReadableDescription {
    var rawDescription: String {
        "Theme \(self.colorScheme.rawValue.description.capitalized)"
    }
}
