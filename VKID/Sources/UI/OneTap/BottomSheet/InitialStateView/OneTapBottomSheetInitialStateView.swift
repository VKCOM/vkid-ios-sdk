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

internal class OneTapBottomSheetInitialStateView: UIView {
    private let config: Configuration
    private let authButton: UIView
    private var portraitConstraints: [NSLayoutConstraint]?
    private var landscapeConstraints: [NSLayoutConstraint]?
    private var landscapeBodyWidth: CGFloat = 254
    private var imageViewLeadingConstraint: NSLayoutConstraint?
    private var imageViewTrailingConstraint: NSLayoutConstraint?

    internal init(configuration: Configuration) {
        self.config = configuration
        self.authButton = configuration.authButton
        super.init(frame: .zero)
        self.setupUI()
        self.apply(config: configuration)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var vkIdImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.attributedText = self.attributedText(
            text: self.config.title,
            font: self.config.titleFont,
            minimumLineHeight: 24)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.attributedText = self.attributedText(
            text: self.config.subtitle,
            font: self.config.subtitleFont,
            minimumLineHeight: 20,
            kern: 0.15
        )
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private func attributedText(
        text: String,
        font: UIFont,
        minimumLineHeight: CGFloat,
        kern: NSNumber = 0
    ) -> NSAttributedString{
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = minimumLineHeight
        paragraph.maximumLineHeight = minimumLineHeight
        paragraph.alignment = .center
        return NSAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraph,
                .font: font,
                .kern: kern,
            ]
        )
    }

    private func setupUI() {
        self.addSubview(self.vkIdImageView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.subtitleLabel)
        self.addSubview(self.authButton)
        self.authButton.translatesAutoresizingMaskIntoConstraints = false
        self.portraitConstraints = [
            self.vkIdImageView.widthAnchor.constraint(equalToConstant: 192),
            self.vkIdImageView.heightAnchor.constraint(equalToConstant: 120),
            self.vkIdImageView.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: 0
            ),
            self.vkIdImageView.centerXAnchor.constraint(
                equalTo: self.centerXAnchor
            ),
            self.titleLabel.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: Constants.portraitTextContainerInsets.left
            ),
            self.titleLabel.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: Constants.portraitTextContainerInsets.right
            ),
            self.titleLabel.topAnchor.constraint(
                equalTo: self.vkIdImageView.bottomAnchor,
                constant: Constants.portraitTextContainerInsets.top
            ),
            self.titleLabel.bottomAnchor.constraint(
                equalTo: self.subtitleLabel.topAnchor,
                constant: -12
            ),
            self.subtitleLabel.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: Constants.portraitTextContainerInsets.left
            ),
            self.subtitleLabel.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: Constants.portraitTextContainerInsets.right
            ),
            self.authButton.leadingAnchor.constraint(
                equalTo: self.leadingAnchor
            ),
            self.authButton.trailingAnchor.constraint(
                equalTo: self.trailingAnchor
            ),
            self.authButton.bottomAnchor.constraint(
                equalTo: self.bottomAnchor
            ),
            self.subtitleLabel.bottomAnchor.constraint(
                equalTo: self.authButton.topAnchor,
                constant: Constants.portraitTextContainerInsets.bottom
            ),
        ]
        let (imageWidth, imageHeight) = self.config.bottomSheetWidth.imageSize
        let aspectRatioConstraint = NSLayoutConstraint(
            item: self.vkIdImageView,
            attribute: .width,
            relatedBy: .equal,
            toItem: self.vkIdImageView,
            attribute: .height,
            multiplier: CGFloat(imageWidth / imageHeight),
            constant: 0
        )
        let imageViewLeadingConstraint = self.vkIdImageView.leadingAnchor.constraint(
            equalTo: self.leadingAnchor, constant: 0
        )
        self.imageViewLeadingConstraint = imageViewLeadingConstraint
        let imageViewTrailingConstraint = self.titleLabel.leadingAnchor.constraint(
            equalTo: self.vkIdImageView.trailingAnchor,
            constant: Constants.landscapeTextContainerInsets.left
        )
        
        self.imageViewTrailingConstraint = imageViewTrailingConstraint
        landscapeConstraints = [
            imageViewLeadingConstraint,
            aspectRatioConstraint,
            self.vkIdImageView.heightAnchor.constraint(equalToConstant: CGFloat(imageHeight)),
            self.vkIdImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.heightAnchor.constraint(
                lessThanOrEqualToConstant: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - Constants.cardVerticalPadding
            ),
            self.titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            self.titleLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: landscapeBodyWidth),
            self.subtitleLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: landscapeBodyWidth),
            imageViewTrailingConstraint,
            self.titleLabel.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: Constants.landscapeTextContainerInsets.right
            ),
            self.subtitleLabel.topAnchor.constraint(
                equalTo: self.titleLabel.bottomAnchor,
                constant: Constants.titleAndSubtitlePadding
            ),
            self.subtitleLabel.leadingAnchor.constraint(
                equalTo: self.titleLabel.leadingAnchor,
            ),
            self.subtitleLabel.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: Constants.landscapeTextContainerInsets.right
            ),
            self.authButton.leadingAnchor.constraint(
                equalTo: self.titleLabel.leadingAnchor
            ),
            self.authButton.widthAnchor.constraint(equalToConstant: landscapeBodyWidth),
            self.authButton.trailingAnchor.constraint(
                equalTo: self.trailingAnchor
            ),
            self.authButton.bottomAnchor.constraint(
                equalTo: self.bottomAnchor
            ),
            self.subtitleLabel.bottomAnchor.constraint(
                greaterThanOrEqualTo: self.authButton.topAnchor,
                constant: Constants.landscapeTextContainerInsets.bottom
            ),
        ]
        self.updateOrientationChanges()
        self.updateContentConstraintsIfNeeded()
    }

    private func updateContentConstraintsIfNeeded() {
        let targetSize = CGSize(width: landscapeBodyWidth, height: UIView.layoutFittingCompressedSize.height)
        let titleLabelHeight = self.titleLabel.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let subtitleLabelHeight = self.subtitleLabel.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        self.authButton.setNeedsLayout()
        self.authButton.layoutIfNeeded()
        let buttonHeight = self.authButton.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        if UIScreen.main.bounds.height < CGFloat(
            Constants.cardVerticalPadding +
            titleLabelHeight +
            Constants.titleAndSubtitlePadding +
            subtitleLabelHeight +
            (-Constants.landscapeTextContainerInsets.bottom) +
            buttonHeight
        ) {
            self.landscapeBodyWidth = 294
            self.imageViewTrailingConstraint?.constant = 2
            self.imageViewLeadingConstraint?.constant = -20
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.apply(config: self.config)
    }

    private func apply(config: Configuration) {
        self.titleLabel.textColor = config.titleColor.value
        self.subtitleLabel.textColor = config.subtitleColor.value
        if UIDevice.current.orientation.isLandscape {
            self.vkIdImageView.image = config.vkIdLandscapeImage.value
            self.titleLabel.attributedText = self.attributedText(
                text: self.config.title,
                font: self.config.titleFont.withSize(self.config.titleFont.pointSize - 6),
                minimumLineHeight: 22)
            self.subtitleLabel.attributedText = self.attributedText(
                text: self.config.subtitle,
                font: self.config.subtitleFont.withSize(
                    self.config.subtitleFont.pointSize - 3
                ),
                minimumLineHeight: 16,
                kern: 0.2)
        } else {
            self.vkIdImageView.image = config.vkIdImage.value
            self.titleLabel.attributedText = self.attributedText(
                text: self.config.title,
                font: self.config.titleFont,
                minimumLineHeight: 24)
            self.subtitleLabel.attributedText = self.attributedText(
                text: self.config.subtitle,
                font: self.config.subtitleFont,
                minimumLineHeight: 20,
                kern: 0.15)
        }
    }

    func viewWillTransition(with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self else { return }
            self.updateOrientationChanges()
            self.apply(config: self.config)
        })
        (self.authButton as? OneTapButtonWithOAuthListWidgetView)?.viewWillTransition(with: coordinator)
    }

    private func updateOrientationChanges() {
        guard let portraitConstraints, let landscapeConstraints else {
            return
        }
        if UIDevice.current.orientation.isLandscape {
            NSLayoutConstraint.deactivate(portraitConstraints)
            NSLayoutConstraint.activate(landscapeConstraints)
        } else {
            NSLayoutConstraint.deactivate(landscapeConstraints)
            NSLayoutConstraint.activate(portraitConstraints)
        }
    }
}

extension OneTapBottomSheetInitialStateView {
    enum Constants {
        static let portraitTextContainerInsets = UIEdgeInsets(
            top: 16,
            left: 0,
            bottom: -24,
            right: 0
        )
        static let landscapeTextContainerInsets = UIEdgeInsets(
            top: 20,
            left: 22,
            bottom: -16,
            right: 0
        )
        static let cardVerticalPadding: CGFloat = 48
        static let titleAndSubtitlePadding: CGFloat = 8
    }
}
