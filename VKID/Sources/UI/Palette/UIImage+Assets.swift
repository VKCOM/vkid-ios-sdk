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

import UIKit

extension UIImage {
    internal static let logoPrimary = UIImage.moduleNamed("vk_id_logo_primary")
    internal static let logoSecondary = UIImage.moduleNamed("vk_id_logo_secondary")
    internal static let okRuLogoSecondary = UIImage.moduleNamed("ok_ru_logo_secondary")
    internal static let mailRuLogoSecondary = UIImage.moduleNamed("mail_ru_logo_secondary")
    internal static let closeDark = UIImage.moduleNamed("dismiss_24_dark")
    internal static let closeLight = UIImage.moduleNamed("dismiss_24_light")
    internal static let logoLight = UIImage.moduleNamed("logo_vkid_light")
    internal static let logoDark = UIImage.moduleNamed("logo_vkid_dark")
    internal static let errorOutline = UIImage.moduleNamed("error_outline_56")
    internal static let checkCircleOutline = UIImage.moduleNamed("check_circle_outline_56")
}

extension UIImage {
    fileprivate static func moduleNamed(_ named: String) -> UIImage {
        UIImage(
            named: named,
            in: .resources,
            compatibleWith: nil
        )!
    }
}
