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

enum AnalyticsMappings {
    static func colorSchemeToText(colorScheme: Appearance.ColorScheme) -> String {
        switch colorScheme {
        case .system:
            colorScheme.resolveSystemToActualScheme().rawValue
        case .light, .dark:
            colorScheme.rawValue
        }
    }

    static func textTypeToText(textType: String) -> String? {
        if let textType = OneTapButton.Appearance.Title.RawType(rawValue: textType) {
            return self.oneTapButtonTitleToText(text: textType)
        } else if let textType = OneTapBottomSheet.TargetActionText.RawType(rawValue: textType) {
            return self.oneTapBottomSheetTargetActionToText(text: textType)
        } else {
            return nil
        }
    }

    static func oneTapButtonTitleToText(text: OneTapButton.Appearance.Title.RawType) -> String? {
        switch text {
        case .signUp:
            "appoint"
        case .get:
            "receive"
        case .open:
            "open"
        case .calculate:
            "calculate"
        case .order:
            "order"
        case .makeOrder:
            "service_order_placing"
        case .submitRequest:
            "request"
        case .participate:
            "take_part"
        case .vkid:
            "default"
        case .ok, .mail, .custom:
            nil
        }
    }

    static func oneTapBottomSheetTargetActionToText(text: OneTapBottomSheet.TargetActionText.RawType) -> String {
        switch text {
        case .signIn:
            "service_sign_in"
        case .signInToService:
            "account_sign_in"
        case .registerForEvent:
            "event_reg"
        case .applyFor:
            "request"
        case .orderCheckout:
            "vkid_order_placing"
        case .orderCheckoutAtService:
            "service_order_placing"
        }
    }
}
