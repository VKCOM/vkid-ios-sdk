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

extension OneTapControl {
    internal struct Configuration {
        var primaryTitle: String
        var briefTitle: String
        var titleFont: UIFont?
        var titleColor: any Color

        var borderColor: any Color
        var borderWidth: CGFloat

        var backgroundColor: any Color
        var activityIndicatorColor: any Color

        var cornerRadius: CGFloat
        var buttonHeight: CGFloat

        var logoSize: CGSize
        var logoImage: UIImage

        var isLogoOnlyLayout: Bool

        internal init(
            primaryTitle: String,
            briefTitle: String,
            titleFont: UIFont? = nil,
            titleColor: some Color,
            borderColor: some Color,
            borderWidth: CGFloat,
            backgroundColor: some Color,
            activityIndicatorColor: some Color,
            cornerRadius: CGFloat,
            buttonHeight: CGFloat,
            logoSize: CGSize,
            logoImage: UIImage,
            isLogoOnlyLayout: Bool
        ) {
            self.primaryTitle = primaryTitle
            self.briefTitle = briefTitle
            self.titleFont = titleFont
            self.titleColor = titleColor
            self.borderColor = borderColor
            self.borderWidth = borderWidth
            self.backgroundColor = backgroundColor
            self.activityIndicatorColor = activityIndicatorColor
            self.cornerRadius = cornerRadius
            self.buttonHeight = buttonHeight
            self.logoSize = logoSize
            self.logoImage = logoImage
            self.isLogoOnlyLayout = isLogoOnlyLayout
        }

        internal init(
            appearance: OneTapButton.Appearance,
            layout: OneTapButton.Layout
        ) {
            let logoSize: CGSize
            let fontSize: CGFloat
            switch layout.height {
            case .small:
                logoSize = CGSize(width: 24.0, height: 24.0)
                fontSize = 14.0
            case .medium:
                logoSize = CGSize(width: 28.0, height: 28.0)
                fontSize = 16.0
            case .large:
                logoSize = CGSize(width: 28.0, height: 28.0)
                fontSize = 17.0
            }

            let titleFont: UIFont = .systemFont(ofSize: fontSize, weight: .semibold)
            let theme: OneTapButton.Appearance.Theme = appearance.theme

            switch appearance.style.rawStyle {
            case .primary:
                self.init(
                    primaryTitle: appearance.title.primary,
                    briefTitle: appearance.title.brief,
                    titleFont: titleFont,
                    titleColor: UIColor.white,
                    borderColor: theme.colors.secondary,
                    borderWidth: 0,
                    backgroundColor: theme.colors.primary,
                    activityIndicatorColor: UIColor.white,
                    cornerRadius: layout.cornerRadius,
                    buttonHeight: layout.height.rawValue,
                    logoSize: logoSize,
                    logoImage: appearance.style.logo.image,
                    isLogoOnlyLayout: layout.kind == .logoOnly
                )
            case .secondary:
                self.init(
                    primaryTitle: appearance.title.primary,
                    briefTitle: appearance.title.brief,
                    titleFont: titleFont,
                    titleColor: DynamicColor(
                        light: .black,
                        dark: .white
                    ),
                    borderColor: theme.colors.secondary,
                    borderWidth: 1,
                    backgroundColor: UIColor.clear,
                    activityIndicatorColor: DynamicColor(
                        light: .iconMediumLight,
                        dark: .iconMediumDark
                    ),
                    cornerRadius: layout.cornerRadius,
                    buttonHeight: layout.height.rawValue,
                    logoSize: logoSize,
                    logoImage: appearance.style.logo.image,
                    isLogoOnlyLayout: layout.kind == .logoOnly
                )
            }
        }
    }
}
