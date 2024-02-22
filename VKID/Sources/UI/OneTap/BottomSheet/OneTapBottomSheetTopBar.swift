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
@_implementationOnly import VKIDCore

internal final class OneTapBottomSheetTopBar: UIView {
    internal struct Configuration {
        var title: String
        var titleColor: any Color
        var logoIDColor: any Color
        var logoIcon: any Image
        var closeButtonIcon: any Image
        var onClose: () -> Void
    }

    private var configuration: Configuration
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.imageEdgeInsets = UIEdgeInsets(
            top: 12,
            left: 12,
            bottom: 12,
            right: 12
        )
        button.addTarget(
            self,
            action: #selector(self.onCloseClicked(sender:)),
            for: .touchUpInside
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    } ()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textAlignment = .left
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.03
        label.attributedText = NSAttributedString(
            string: " · " + self.configuration.title,
            attributes: [
                .kern: -0.08,
                .paragraphStyle: paragraph,
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            ]
        )
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    } ()

    private lazy var logoView: UIImageView = {
        let view = UIImageView(image: self.configuration.logoIcon.value)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    } ()

    internal init(configuration: Configuration) {
        self.configuration = configuration
        super.init(frame: .zero)
        self.setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.apply(configuration: self.configuration)
    }

    @objc
    private func onCloseClicked(sender: Any) {
        self.configuration.onClose()
    }

    private func setupUI() {
        self.addSubview(self.logoView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.closeButton)

        self.closeButton.buildConstraint {
            $0.pinSize(.init(width: 48, height: 48))
        }
        self.logoView.buildConstraint {
            $0.pinSize(.init(width: 33, height: 16))
        }

        NSLayoutConstraint.activate([
            self.heightAnchor.constraint(
                equalToConstant: 50
            ),
            self.logoView.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: 16
            ),
            self.logoView.trailingAnchor.constraint(
                equalTo: self.titleLabel.leadingAnchor
            ),
            self.logoView.centerYAnchor.constraint(
                equalTo: self.centerYAnchor
            ),
            self.titleLabel.trailingAnchor.constraint(
                equalTo: self.closeButton.leadingAnchor
            ),
            self.titleLabel.centerYAnchor.constraint(
                equalTo: self.centerYAnchor
            ),
            self.closeButton.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -2
            ),
            self.closeButton.centerYAnchor.constraint(
                equalTo: self.centerYAnchor
            ),
        ])

        self.backgroundColor = .clear
        self.apply(configuration: self.configuration)
    }

    private func apply(configuration: Configuration) {
        self.closeButton.setImage(
            configuration.closeButtonIcon.value,
            for: .normal
        )
        self.titleLabel.textColor = configuration.titleColor.value
        self.logoView.image = self.configuration.logoIcon.value
    }
}
