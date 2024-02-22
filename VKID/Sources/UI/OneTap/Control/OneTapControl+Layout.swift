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
@_implementationOnly import VKIDCore

extension OneTapControl {
    /// Layout для основного состояния кнопки. logo и title центрируются совместно
    /// [ --- [ logo ] - [ title] --- ] или [ --- logo --- ]
    internal struct RegularAdaptiveLayout: Layout {
        private let layoutHelper: LayoutHelper

        internal var logo: Layout
        internal var title: Layout
        internal var activityIndicator: Layout
        internal var logoSize: CGSize

        init(logo: Layout, title: Layout, activityIndicator: Layout, logoSize: CGSize) {
            self.logo = logo
            self.title = title
            self.activityIndicator = activityIndicator
            self.logoSize = logoSize

            self.layoutHelper = LayoutHelper(
                title: title,
                logoSize: logoSize
            )
        }

        func layout(in frame: CGRect) {
            let margin = self.layoutHelper.marginFromBorders(for: frame.size)
            let titleSize = self.title.sizeThatFits(
                .init(
                    width: self.layoutHelper.titleAvailableWidth(for: frame.size, margin: margin),
                    height: frame.size.height
                )
            )

            if titleSize.width == .zero {
                let logoFrame = CGRect(
                    origin: .init(
                        x: floor(
                            (frame.size.width - self.logoSize.width) / 2
                        ),
                        y: floor(
                            (frame.size.height - self.logoSize.height) / 2
                        )
                    ),
                    size: self.logoSize
                )
                let logoCentralFrame = CGRect(
                    origin: .init(
                        x: logoFrame.midX,
                        y: logoFrame.midY
                    ),
                    size: .zero
                )

                self.logo.layout(in: logoFrame)
                self.title.layout(in: logoCentralFrame)
                self.activityIndicator.layout(in: logoCentralFrame)
            } else {
                let logoWithTitleWidth = self.logoSize.width + margin + titleSize.width

                let logoXOffset = floor(
                    (frame.size.width - logoWithTitleWidth) / 2
                )

                let logoFrame = CGRect(
                    origin: .init(
                        x: logoXOffset,
                        y: floor(
                            (frame.size.height - self.logoSize.height) / 2
                        )
                    ),
                    size: self.logoSize
                )

                self.logo.layout(in: logoFrame)
                self.title.layout(in: .init(
                    origin: .init(
                        x: logoFrame.maxX + margin,
                        y: floor(
                            (frame.size.height - titleSize.height) / 2
                        )
                    ),
                    size: titleSize
                ))
                self.activityIndicator.layout(in: .init(
                    origin: .init(
                        x: frame.size.width - margin - self.logoSize.width / 2,
                        y: floor(
                            frame.size.height / 2
                        )
                    ),
                    size: .zero
                ))
            }
        }

        func sizeThatFits(_ size: CGSize) -> CGSize {
            self.layoutHelper.sizeThatFits(size)
        }
    }
}

extension OneTapControl {
    /// Layout для анимированного состояния кнопки.
    /// logo и activityIndicator - по краям, title - по центру.
    /// [ - [ activityIndicator ] --- [ title ] --- [ activityIndicator ] - ] или [ --- activityIndicator --- ]
    internal struct RegularActivityIndicatingLayout: Layout {
        private let layoutHelper: LayoutHelper

        internal var logo: Layout
        internal var title: Layout
        internal var activityIndicator: Layout
        internal var logoSize: CGSize

        init(logo: Layout, title: Layout, activityIndicator: Layout, logoSize: CGSize) {
            self.logo = logo
            self.title = title
            self.activityIndicator = activityIndicator
            self.logoSize = logoSize

            self.layoutHelper = LayoutHelper(
                title: title,
                logoSize: logoSize
            )
        }

        func layout(in frame: CGRect) {
            let margin = self.layoutHelper.marginFromBorders(for: frame.size)
            let titleSize = self.title.sizeThatFits(
                .init(
                    width: self.layoutHelper.titleAvailableWidth(for: frame.size, margin: margin),
                    height: frame.size.height
                )
            )

            if titleSize.width == .zero {
                let activityIndicatorFrame = CGRect(
                    origin: .init(
                        x: floor(
                            (frame.size.width - self.logoSize.width) / 2
                        ),
                        y: floor(
                            (frame.size.height - self.logoSize.height) / 2
                        )
                    ),
                    size: self.logoSize
                )
                let activityIndicatorCentralFrame = CGRect(
                    origin: .init(
                        x: activityIndicatorFrame.midX,
                        y: activityIndicatorFrame.midY
                    ),
                    size: .zero
                )

                self.logo.layout(in: activityIndicatorCentralFrame)
                self.title.layout(in: activityIndicatorCentralFrame)
                self.activityIndicator.layout(in: activityIndicatorFrame)
            } else {
                let titleAvailableWidth = self.layoutHelper.titleAvailableWidth(
                    for: frame.size,
                    margin: margin
                )
                let titleXOffset = floor(
                    (titleAvailableWidth - titleSize.width) / 2
                )

                let logoFrame = CGRect(
                    origin: .init(
                        x: margin,
                        y: floor(
                            (frame.size.height - self.logoSize.height) / 2
                        )
                    ),
                    size: self.logoSize
                )

                self.logo.layout(in: logoFrame)
                self.title.layout(in: .init(
                    origin: .init(
                        x: logoFrame.maxX + margin + titleXOffset,
                        y: floor(
                            (frame.size.height - titleSize.height) / 2
                        )
                    ),
                    size: titleSize
                ))
                self.activityIndicator.layout(in: .init(
                    origin: .init(
                        x: frame.size.width - self.logoSize.height - margin,
                        y: floor(
                            (frame.size.height - self.logoSize.height) / 2
                        )
                    ),
                    size: self.logoSize
                ))
            }
        }

        func sizeThatFits(_ size: CGSize) -> CGSize {
            self.layoutHelper.sizeThatFits(size)
        }
    }
}

extension OneTapControl {
    /// Layout для кнопки-иконки в обычном состоянии
    /// [ --- logo --- ]
    internal struct LogoOnlyLayout: Layout {
        var logo: Layout
        var title: Layout
        var activityIndicator: Layout
        var logoSize: CGSize
        var buttonSize: CGSize

        func layout(in frame: CGRect) {
            let logoFrame = CGRect(
                origin: .init(
                    x: floor(
                        (frame.size.width - self.logoSize.width) / 2
                    ),
                    y: floor(
                        (frame.size.height - self.logoSize.height) / 2
                    )
                ),
                size: self.logoSize
            )
            let logoCentralFrame = CGRect(
                origin: .init(
                    x: logoFrame.midX,
                    y: logoFrame.midY
                ),
                size: .zero
            )

            self.logo.layout(in: logoFrame)
            self.title.layout(in: logoCentralFrame)
            self.activityIndicator.layout(in: logoCentralFrame)
        }

        func sizeThatFits(_ size: CGSize) -> CGSize {
            .init(
                width: max(size.width, self.buttonSize.width),
                height: max(size.height, self.buttonSize.height)
            )
        }
    }

    /// Layout для кнопки-иконки в анимированном состоянии
    /// [ --- activityIndicator --- ]
    internal struct LogoOnlyActivityIndicatingLayout: Layout {
        var logo: Layout
        var title: Layout
        var activityIndicator: Layout
        var logoSize: CGSize
        var buttonSize: CGSize

        func layout(in frame: CGRect) {
            let activityIndicatorFrame = CGRect(
                origin: .init(
                    x: floor(
                        (frame.size.width - self.logoSize.width) / 2
                    ),
                    y: floor(
                        (frame.size.height - self.logoSize.height) / 2
                    )
                ),
                size: self.logoSize
            )
            let activityIndicatorCentralFrame = CGRect(
                origin: .init(
                    x: activityIndicatorFrame.midX,
                    y: activityIndicatorFrame.midY
                ),
                size: .zero
            )

            self.logo.layout(in: activityIndicatorCentralFrame)
            self.title.layout(in: activityIndicatorCentralFrame)
            self.activityIndicator.layout(in: activityIndicatorFrame)
        }

        func sizeThatFits(_ size: CGSize) -> CGSize {
            .init(
                width: max(size.width, self.buttonSize.width),
                height: max(size.height, self.buttonSize.height)
            )
        }
    }
}

extension OneTapControl {
    fileprivate struct LayoutHelper {
        enum Constants {
            static let minimumMargin: CGFloat = 4.0
        }

        internal var title: Layout
        internal var logoSize: CGSize

        func sizeThatFits(_ size: CGSize) -> CGSize {
            let minimalSize = self.minimalSize(for: size)
            let titleAvailableWidth = size.width - 2 * minimalSize.width
            let titleSize = self.title.sizeThatFits(
                .init(width: titleAvailableWidth, height: size.height)
            )

            if titleSize.width == .zero {
                return .init(
                    width: max(size.width, minimalSize.width),
                    height: max(size.height, minimalSize.height)
                )
            } else {
                return .init(
                    width: 2 * minimalSize.width + max(titleSize.width, titleAvailableWidth),
                    height: max(minimalSize.height, size.height)
                )
            }
        }

        func minimalSize(for size: CGSize) -> CGSize {
            self.logoSize + 2 * self.marginFromBorders(for: size)
        }

        func marginFromBorders(for size: CGSize) -> CGFloat {
            let result = floor(
                (size.height - self.logoSize.width) / 2
            )
            return max(result, Constants.minimumMargin)
        }

        func titleAvailableWidth(for size: CGSize, margin: CGFloat) -> CGFloat {
            size.width - 2 * (self.logoSize.width + 2 * margin)
        }
    }
}
