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

internal final class OneTapButtonWithOAuthListWidgetView: UIView {
    private enum Constants {
        static let spacing: CGFloat = 15
    }

    /// Кнопка авторизации
    private let oneTapButton: UIView

    /// Виджет с авторизациями сервисов
    private let oAuthListWidget: UIView

    /// Конфигурация
    private let configuration: Configuration

    /// Разделитель с текстом
    private lazy var separatorTextLabel: UILabel = {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 16
        paragraph.maximumLineHeight = 16
        paragraph.alignment = .center

        let label = UILabel()
        label.numberOfLines = 0

        label.attributedText = NSAttributedString(
            string: self.configuration.title,
            attributes: [
                .paragraphStyle: paragraph,
                .font: self.configuration.titleFont,
                .foregroundColor: self.configuration.titleColor.value,
            ]
        )

        return label
    }()

    internal init(
        configuration: Configuration
    ) {
        self.configuration = configuration
        self.oneTapButton = configuration.oneTapButton
        self.oAuthListWidget = configuration.oAuthListWidget

        super.init(frame: .zero)
        self.backgroundColor = .clear

        self.setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.update()
    }

    private func setupView() {
        self.addSubview(self.oneTapButton)
        self.addSubview(self.separatorTextLabel)
        self.addSubview(self.oAuthListWidget)

        self.oneTapButton.translatesAutoresizingMaskIntoConstraints = false
        self.separatorTextLabel.translatesAutoresizingMaskIntoConstraints = false
        self.oAuthListWidget.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.oneTapButton.topAnchor.constraint(
                equalTo: self.topAnchor
            ),
            self.oneTapButton.leadingAnchor.constraint(
                equalTo: self.leadingAnchor
            ),
            self.oneTapButton.trailingAnchor.constraint(
                equalTo: self.trailingAnchor
            ),

            self.separatorTextLabel.topAnchor.constraint(
                equalTo: self.oneTapButton.bottomAnchor, constant: Constants.spacing
            ),
            self.separatorTextLabel.leadingAnchor.constraint(
                equalTo: self.leadingAnchor
            ),
            self.separatorTextLabel.trailingAnchor.constraint(
                equalTo: self.trailingAnchor
            ),

            self.oAuthListWidget.topAnchor.constraint(
                equalTo: self.separatorTextLabel.bottomAnchor, constant: Constants.spacing
            ),
            self.oAuthListWidget.leadingAnchor.constraint(
                equalTo: self.leadingAnchor
            ),
            self.oAuthListWidget.trailingAnchor.constraint(
                equalTo: self.trailingAnchor
            ),
            self.oAuthListWidget.bottomAnchor.constraint(
                equalTo: self.bottomAnchor
            ),
        ])
    }

    private func update() {
        self.separatorTextLabel.textColor = self.configuration.titleColor.value
    }
}
