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

struct ButtonBaseConfiguration {
    var height: OneTapButton.Layout.Height = .medium()
    var cornerRadius: CGFloat = LayoutConstants.defaultCornerRadius
}

struct OneTapButtonConfiguration {
    var buttonBaseConfiguration: ButtonBaseConfiguration = .init()
    var alternativeProviders: [OAuthProvider] = []
    var theme: OneTapButton.Appearance.Theme = .matchingColorScheme(.light)
    var title: OneTapButton.Appearance.Title? = .vkid
    var style: OneTapButton.Appearance.Style = .primary()
    var kind: OneTapButton.Layout.Kind = .regular
}

extension OneTapButtonConfiguration {
    var appearance: OneTapButton.Appearance {
        if let title = self.title {
            return OneTapButton.Appearance(
                title: title,
                style: self.style,
                theme: self.theme
            )
        } else {
            return OneTapButton.Appearance(
                style: self.style,
                theme: self.theme
            )
        }
    }

    var oneTapButtonLayout: OneTapButton.Layout {
        OneTapButton.Layout(
            kind: self.kind,
            height: self.buttonBaseConfiguration.height,
            cornerRadius: self.buttonBaseConfiguration.cornerRadius
        )
    }
}

extension OneTapButtonConfiguration {
    func createOneTapButton() -> OneTapButton {
        OneTapButton(
            authConfiguration: .init(),
            oAuthProviderConfiguration: .init(),
            appearance: self.appearance,
            layout: self.oneTapButtonLayout,
            presenter: .newUIWindow,
            onTap: nil,
            onCompleteAuth: nil
        )
    }
}
