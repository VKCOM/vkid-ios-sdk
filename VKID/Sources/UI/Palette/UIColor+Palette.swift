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

extension UIColor {
    internal static let azure = UIColor.moduleNamed("azure")
    internal static let gray100 = UIColor.moduleNamed("gray100")
    internal static let backgroundLight = UIColor.moduleNamed("background_light")
    internal static let backgroundDark = UIColor.moduleNamed("background_dark")
    internal static let iconMediumLight = UIColor.moduleNamed("icon_medium_light")
    internal static let iconMediumDark = UIColor.moduleNamed("icon_medium_dark")
    internal static let textSecondaryDark = UIColor.moduleNamed("color_text_secondary_dark")
    internal static let textSecondaryLight = UIColor.moduleNamed("color_text_secondary_light")
    internal static let textPrimaryLight = UIColor.moduleNamed("color_text_primary_light")
    internal static let textPrimaryDark = UIColor.moduleNamed("color_text_primary_dark")
    internal static let backgroundModalDark = UIColor.moduleNamed("color_background_modal_dark")
    internal static let backgroundModalLight = UIColor.moduleNamed("color_background_modal_light")
    internal static let backgroundSecondaryAlphaDark = UIColor.moduleNamed("color_background_secondary_alpha_dark")
    internal static let backgroundSecondaryAlphaLight = UIColor.moduleNamed("color_background_secondary_alpha_light")
    internal static let textAccentThemed = UIColor.moduleNamed("color_text_accent_themed")
}

extension UIColor {
    fileprivate static func moduleNamed(_ named: String) -> UIColor {
        UIColor(
            named: named,
            in: .resources,
            compatibleWith: nil
        )!
    }
}
