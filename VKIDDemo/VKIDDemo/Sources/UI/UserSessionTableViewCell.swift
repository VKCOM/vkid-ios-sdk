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

import UIKit
import VKID

final class UserSessionInfoTableViewCell: UITableViewCell {
    enum Constants {
        static let imageSize: CGFloat = 40
        static let identifier: String = .init(describing: UserSessionInfoTableViewCell.self)
    }

    private let leftImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = Constants.imageSize / 2
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var regularAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 16, weight: .bold),
        .foregroundColor: UIColor.black,
    ]

    var lightAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 16, weight: .light),
        .foregroundColor: UIColor.gray.withAlphaComponent(0.6),
    ]

    var userSession: UserSession?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.calculateColors()
        self.setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.calculateColors()
        self.updateTextAttributes()
    }

    func apply(session: UserSession) {
        self.userSession = session

        self.updateTextAttributes()
        self.updateImageView()
    }

    private func calculateColors() {
        if traitCollection.userInterfaceStyle == .light {
            self.regularAttributes[.foregroundColor] = UIColor.black
            self.lightAttributes[.foregroundColor] = UIColor.darkGray.withAlphaComponent(0.6)
        } else {
            self.regularAttributes[.foregroundColor] = UIColor.white
            self.lightAttributes[.foregroundColor] = UIColor.lightGray.withAlphaComponent(0.6)
        }
    }

    private func updateImageView() {
        guard let url = self.userSession?.user.avatarURL else { return }

        self.leftImageView.loadImage(with: url) { [weak self] result in
            guard
                let self,
                let imageResult = try? result.get(),
                imageResult.url == self.userSession?.user.avatarURL
            else {
                return
            }
            self.leftImageView.image = imageResult.image
        }
    }

    private func updateTextAttributes() {
        guard let session = self.userSession else { return }

        let name = "\(session.user.firstName) \(session.user.lastName)"
        let id = " ID: \(session.user.id.value)"
        let detail = "\(session.user.phone ?? "-") | \(session.user.email ?? "-")"

        let mutableAttributedTitleString = NSMutableAttributedString()
        mutableAttributedTitleString.append(
            NSAttributedString(string: name, attributes: self.regularAttributes)
        )
        mutableAttributedTitleString.append(
            NSAttributedString(string: id, attributes: self.lightAttributes)
        )

        let mutableAttributedDetailString = NSAttributedString(
            string: detail, attributes: lightAttributes
        )

        self.titleLabel.attributedText = mutableAttributedTitleString
        self.detailLabel.attributedText = mutableAttributedDetailString
    }

    private func setupSubviews() {
        self.addSubview(self.leftImageView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.detailLabel)

        NSLayoutConstraint.activate([
            // MARK: - Header
            self.leftImageView.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: 8
            ),
            self.leftImageView.heightAnchor.constraint(
                equalToConstant: Constants.imageSize
            ),
            self.leftImageView.widthAnchor.constraint(
                equalToConstant: Constants.imageSize
            ),
            self.leftImageView.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: 16
            ),

            // MARK: - ImageView
            self.titleLabel.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: 8
            ),
            self.titleLabel.leadingAnchor.constraint(
                equalTo: self.leftImageView.trailingAnchor,
                constant: 8
            ),
            self.titleLabel.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -16
            ),

            // MARK: - Title
            self.detailLabel.topAnchor.constraint(
                equalTo: self.titleLabel.bottomAnchor,
                constant: 4
            ),
            self.detailLabel.leadingAnchor.constraint(
                equalTo: self.leftImageView.trailingAnchor,
                constant: 8
            ),
            self.detailLabel.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -16
            ),
            self.detailLabel.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: -8
            ),
        ])
    }
}
