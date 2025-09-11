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
import VKIDCore

final class UserSessionInfoTableViewCell: UITableViewCell {
    enum Constants {
        static let badgeImageSize: CGFloat = 20
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

    private let leftBadgeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = Constants.badgeImageSize / 2
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
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let footerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss dd.MM.yyyy"
        return dateFormatter
    }()

    var regularAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 16, weight: .bold),
        .foregroundColor: UIColor(resource: .colorTextPrimary),
    ]

    var lightAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 16, weight: .light),
        .foregroundColor: UIColor(resource: .colorTextSecondary),
    ]

    var lightMutedAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 16, weight: .light),
        .foregroundColor: UIColor(resource: .colorTextTertiary),
    ]

    var smallLightAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 12, weight: .light),
        .foregroundColor: UIColor(resource: .colorTextSecondary),
    ]

    var userSession: SessionData?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(session: SessionData) {
        self.userSession = session

        self.updateTextAttributes()
        self.updateImageView()
        self.updateBadgeImageView()
    }

    private func updateImageView() {
        guard let url = self.userSession?.user?.avatarURL else { return }

        self.leftImageView.loadImage(with: url) { [weak self] result in
            guard
                let self,
                let imageResult = try? result.get(),
                imageResult.url == self.userSession?.user?.avatarURL
            else {
                return
            }
            self.leftImageView.image = imageResult.image
        }
    }

    private func updateBadgeImageView() {
        guard let provider = self.userSession?.oAuthProvider else { return }

        var image: UIImage?

        switch provider {
        case OAuthProvider.vkid:
            image = UIImage(resource: .vkIdLogo)
        case OAuthProvider.ok:
            image = UIImage(resource: .okRuLogo)
        case OAuthProvider.mail:
            image = UIImage(resource: .mailLogo)
        default:
            break
        }

        self.leftBadgeImageView.image = image
    }

    private func updateTextAttributes() {
        guard let session = self.userSession else { return }

        let name = "\(session.user?.firstName ?? "") \(session.user?.lastName ?? "")"
        let id = " | ID: \(session.id.value)"
        let creationDate = "Дата авторизации: \(dateFormatter.string(from: session.creationDate))"

        let mutableAttributedTitleString = NSMutableAttributedString()
        mutableAttributedTitleString.append(
            NSAttributedString(string: name, attributes: self.regularAttributes)
        )
        mutableAttributedTitleString.append(
            NSAttributedString(string: id, attributes: self.lightAttributes)
        )

        let mutableAttributedDetailString = NSMutableAttributedString()

        if let userPhone = session.user?.phone {
            mutableAttributedDetailString.append(
                NSAttributedString(string: "\(userPhone)\n", attributes: self.lightAttributes)
            )
        } else {
            mutableAttributedDetailString.append(
                NSAttributedString(string: "Нет телефона\n", attributes: self.lightMutedAttributes)
            )
        }

        if let userEmail = session.user?.email {
            mutableAttributedDetailString.append(
                NSAttributedString(string: "\(userEmail)", attributes: self.lightAttributes)
            )
        } else {
            mutableAttributedDetailString.append(
                NSAttributedString(string: "Нет почты", attributes: self.lightMutedAttributes)
            )
        }

        let mutableAttributedFooterString = NSAttributedString(
            string: creationDate, attributes: self.smallLightAttributes
        )

        self.titleLabel.attributedText = mutableAttributedTitleString
        self.detailLabel.attributedText = mutableAttributedDetailString
        self.footerLabel.attributedText = mutableAttributedFooterString
    }

    private func setupSubviews() {
        self.addSubview(self.titleLabel)
        self.addSubview(self.detailLabel)
        self.addSubview(self.leftImageView)
        self.addSubview(self.leftBadgeImageView)
        self.addSubview(self.footerLabel)

        NSLayoutConstraint.activate([
            // MARK: - ImageView
            self.leftImageView.centerYAnchor.constraint(
                equalTo: self.centerYAnchor
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

            // MARK: - BadgeImageView
            self.leftBadgeImageView.bottomAnchor.constraint(
                equalTo: self.leftImageView.bottomAnchor,
                constant: 2
            ),
            self.leftBadgeImageView.heightAnchor.constraint(
                equalToConstant: Constants.badgeImageSize
            ),
            self.leftBadgeImageView.widthAnchor.constraint(
                equalToConstant: Constants.badgeImageSize
            ),
            self.leftBadgeImageView.trailingAnchor.constraint(
                equalTo: self.leftImageView.trailingAnchor,
                constant: 2
            ),

            // MARK: - Title
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

            // MARK: - Detail
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

            // MARK: - Footer
            self.footerLabel.topAnchor.constraint(
                equalTo: self.detailLabel.bottomAnchor,
                constant: 4
            ),

            self.footerLabel.leadingAnchor.constraint(
                equalTo: self.leftImageView.trailingAnchor,
                constant: 8
            ),
            self.footerLabel.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -16
            ),
            self.footerLabel.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: -8
            ),
        ])
    }
}
