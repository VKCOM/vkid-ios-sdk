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

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 24
        paragraph.maximumLineHeight = 24
        paragraph.alignment = .center
        label.attributedText = NSAttributedString(
            string: self.config.title,
            attributes: [
                .paragraphStyle: paragraph,
                .font: self.config.titleFont,
            ]
        )
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 20
        paragraph.maximumLineHeight = 20
        paragraph.alignment = .center
        label.attributedText = NSAttributedString(
            string: self.config.subtitle,
            attributes: [
                .paragraphStyle: paragraph,
                .font: self.config.subtitleFont,
            ]
        )
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private func setupUI() {
        self.addSubview(self.titleLabel)
        self.addSubview(self.subtitleLabel)
        NSLayoutConstraint.activate([
            self.titleLabel.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: Constants.textContainerInsets.left
            ),
            self.titleLabel.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: Constants.textContainerInsets.right
            ),
            self.titleLabel.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: Constants.textContainerInsets.top
            ),
            self.titleLabel.bottomAnchor.constraint(
                equalTo: self.subtitleLabel.topAnchor,
                constant: -8
            ),
            self.subtitleLabel.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: Constants.textContainerInsets.left
            ),
            self.subtitleLabel.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: Constants.textContainerInsets.right
            ),
        ])

        self.addSubview(self.authButton)
        self.authButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
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
                constant: Constants.textContainerInsets.bottom
            ),
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.apply(config: self.config)
    }

    private func apply(config: Configuration) {
        self.titleLabel.textColor = config.titleColor.value
        self.subtitleLabel.textColor = config.subtitleColor.value
    }
}

extension OneTapBottomSheetInitialStateView {
    private enum Constants {
        static let textContainerInsets = UIEdgeInsets(
            top: 22,
            left: 32,
            bottom: -36,
            right: -32
        )
    }
}
