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

internal class OneTapControl: UIControl {
    private lazy var logoImage: UIImageView = {
        let img = UIImageView(image: self.config.logoImage)
        img.frame = .zero
        return img
    }()

    private lazy var titleLabel: OneTapTitleLabel = {
        let label = OneTapTitleLabel(
            primaryTitle: self.config.primaryTitle,
            briefTitle: self.config.briefTitle
        )
        label.font = self.config.titleFont
        return label
    }()

    private lazy var activityIndicator: ActivityIndicatorView = {
        let spinner = ActivityIndicatorView(frame: .zero)
        spinner.alpha = 0.0
        return spinner
    }()

    private lazy var regularAdaptiveLayout: Layout = OneTapControl.RegularAdaptiveLayout(
        logo: self.logoImage,
        title: self.titleLabel,
        activityIndicator: self.activityIndicator,
        logoSize: self.config.logoSize
    )

    private lazy var regularActivityIndicatingLayout: Layout = OneTapControl.RegularActivityIndicatingLayout(
        logo: self.logoImage,
        title: self.titleLabel,
        activityIndicator: self.activityIndicator,
        logoSize: self.config.logoSize
    )

    private lazy var logoOnlyLayout: Layout = OneTapControl.LogoOnlyLayout(
        logo: self.logoImage,
        title: self.titleLabel,
        activityIndicator: self.activityIndicator,
        logoSize: self.config.logoSize,
        buttonSize: CGSize(
            width: self.config.buttonHeight,
            height: self.config.buttonHeight
        )
    )

    private lazy var logoOnlyActivityIndicatingLayout: Layout = OneTapControl.LogoOnlyActivityIndicatingLayout(
        logo: self.logoImage,
        title: self.titleLabel,
        activityIndicator: self.activityIndicator,
        logoSize: self.config.logoSize,
        buttonSize: CGSize(
            width: self.config.buttonHeight,
            height: self.config.buttonHeight
        )
    )

    private var layout: Layout {
        if self.config.isLogoOnlyLayout {
            if self.isAnimating {
                return self.logoOnlyActivityIndicatingLayout
            } else {
                return self.logoOnlyLayout
            }
        } else {
            if self.isAnimating {
                return self.regularActivityIndicatingLayout
            } else {
                return self.regularAdaptiveLayout
            }
        }
    }

    private let config: Configuration

    private lazy var highlightAnimator: UIViewPropertyAnimator = .init(
        duration: 0.07,
        curve: .easeInOut
    )

    private lazy var unhighlightAnimator: UIViewPropertyAnimator = .init(
        duration: 0.3,
        curve: .easeInOut
    )

    internal var onTap: ((OneTapControl) -> Void)?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal init(configuration: Configuration) {
        self.config = configuration
        super.init(frame: .zero)
        self.addControls()
        self.apply(configuration: configuration)
        self.addTarget(
            self,
            action: #selector(self.onTouchUpInside(sender:)),
            for: .touchUpInside
        )
    }

    private func addControls() {
        self.addSubview(self.logoImage)
        self.addSubview(self.titleLabel)
        self.addSubview(self.activityIndicator)
    }

    private func apply(configuration: Configuration) {
        self.backgroundColor = configuration.backgroundColor.value
        self.layer.borderColor = configuration.borderColor.value.cgColor
        self.layer.cornerRadius = configuration.cornerRadius
        self.layer.borderWidth = configuration.borderWidth

        self.titleLabel.textColor = self.config.titleColor.value
        self.activityIndicator.tintColor = self.config.activityIndicatorColor.value
    }

    private func highlightWithAnimation() {
        self.unhighlightAnimator.stopAnimation(true)
        self.highlightAnimator.addAnimations {
            self.alpha = 0.6
        }
        self.highlightAnimator.startAnimation()
    }

    private func unhighlightWithAnimation() {
        self.highlightAnimator.stopAnimation(true)
        self.unhighlightAnimator.addAnimations {
            self.alpha = 1.0
        }
        self.unhighlightAnimator.startAnimation()
    }

    @objc
    private func onTouchUpInside(sender: UIControl) {
        self.onTap?(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layout.layout(in: self.bounds)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let result = self.layout.sizeThatFits(
            CGSize(
                width: size.width,
                height: self.config.buttonHeight
            )
        )
        return result
    }

    override var intrinsicContentSize: CGSize {
        self.sizeThatFits(
            CGSize(
                width: UIView.layoutFittingExpandedSize.width,
                height: self.config.buttonHeight
            )
        )
    }

    override var bounds: CGRect {
        get {
            super.bounds
        }
        set {
            let actualSize = self.layout.sizeThatFits(
                .init(
                    width: newValue.size.width,
                    height: self.config.buttonHeight
                )
            )
            super.bounds = .init(
                origin: newValue.origin,
                size: actualSize
            )
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.highlightWithAnimation()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.unhighlightWithAnimation()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.unhighlightWithAnimation()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.apply(configuration: self.config)
    }
}

extension OneTapControl: ActivityIndicating {
    var isAnimating: Bool {
        self.activityIndicator.isAnimating
    }

    func startAnimating() {
        guard !self.isAnimating else {
            return
        }
        self.activityIndicator.startAnimating()
        UIView.animate(withDuration: 0.2) {
            self.activityIndicator.alpha = 1.0
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }

    func stopAnimating() {
        guard self.isAnimating else {
            return
        }
        self.activityIndicator.stopAnimating()
        UIView.animate(withDuration: 0.2) {
            self.activityIndicator.alpha = 0.0
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
}
