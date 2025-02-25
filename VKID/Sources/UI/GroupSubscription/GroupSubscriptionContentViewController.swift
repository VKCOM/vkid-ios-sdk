//
// Copyright (c) 2025 - present, LLC “V Kontakte”
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
import VKIDCore

internal struct GroupConfiguration {
    let groupId: Int
    let groupAvatar: URL?
    let vkLogo: UIImage
    let title: String
    let subtitle: String
    let members: [GroupMemberInfo]
    let countOfMembers: Int
    let countOfFriends: Int
    let buttonConfig: GroupSubscriptionSheet.ButtonConfiguration
    let theme: GroupSubscriptionSheet.Theme
    let isVerified: Bool
    let subscribe: (@escaping (Result<Bool, VKAPIError>) -> Void) -> Void
    let onSubscribeCompletion: GroupSubscriptionCompletion?
}

internal final class GroupSubscriptionContentViewController: UIViewController, BottomSheetContent {
    private var groupConfiguration: GroupConfiguration
    var contentDelegate: BottomSheetContentDelegate?

    private var imageHeightConstraint: NSLayoutConstraint?
    private var imageWidthConstraint: NSLayoutConstraint?
    private var imageAndTitleSpacingConstraint: NSLayoutConstraint?
    private var verifiedImageViewConstraint: NSLayoutConstraint?
    private var error: VKAPIError? = nil
    private var vkidAnalitycs: GroupSubscriptionAnalytics
    private var authorizer: Authorizer
    private var result: Result<Void, GroupSubscriptionError>?
    private var isSuccess: Bool = false

    private var state: GroupSubscriptionState = .preview {
        didSet {
            guard oldValue != self.state else {
                return
            }
            self.render(state: self.state)
        }
    }

    internal init(
        groupConfiguration: GroupConfiguration,
        contentDelegate: (any VKIDCore.BottomSheetContentDelegate)? = nil,
        vkidAnalitycs: GroupSubscriptionAnalytics,
        authorizer: Authorizer
    ) {
        self.contentDelegate = contentDelegate
        self.groupConfiguration = groupConfiguration
        self.vkidAnalitycs = vkidAnalitycs
        self.authorizer = authorizer
        super.init(nibName: nil, bundle: nil)
        self.view.addSubview(self.contentPlaceholderView) {
            $0.pinToEdges()
        }
        self.apply(config: self.groupConfiguration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func preferredContentSize(withParentContainerSize parentSize: CGSize) -> CGSize {
        self.view.systemLayoutSizeFitting(
            parentSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.apply(config: self.groupConfiguration)
    }

    private func apply(config: GroupConfiguration) {
        let colors = self.groupConfiguration.theme.colors
        self.contentPlaceholderView.backgroundColor = colors.background.value
        self.vkLogo.image = self.groupConfiguration.theme.images.vkidLogo.value
        self.groupTitle.textColor = colors.title.value
        self.groupSubtitle.textColor = colors.subtitle.value
        self.groupImageView.applyAvatarStyle(
            borderColor: colors.background.value
        )
        self.avatars.subviews.forEach { avatar in
            if let imageView = avatar as? UIImageView {
                imageView.applyAvatarStyle(
                    borderColor: colors.background.value
                )
            }
        }
        self.membersInfoLabel.textColor = colors.subtitle.value
        self.primaryButton.titleLabel?.textColor = colors.primaryButtonTitle.value
        self.primaryButton.backgroundColor = colors.primaryButtonBackground.value
        self.secondaryButton.titleLabel?.textColor = colors.retryButtonTitle.value
        self.secondaryButton.backgroundColor = colors.retryButtonBackground.value
        self.contentPlaceholderView.backgroundColor = colors.background.value
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || navigationController?.isBeingDismissed ?? false, !self.isSuccess {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                [
                    onSubscribeCompletion = self.groupConfiguration.onSubscribeCompletion,
                    result = self.result ?? .failure(.closedByUser)
                ] in
                onSubscribeCompletion?(result)
            }
        }
    }

    private lazy var contentPlaceholderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = self.groupConfiguration.theme.colors.background.value
        view.addSubview(self.closeButton)
        view.addSubview(self.groupImageView)
        view.addSubview(self.vkLogo)
        view.addSubview(self.titleContainer)
        view.addSubview(self.groupSubtitle)
        view.addSubview(self.membersView)
        view.addSubview(self.buttonsView)
        self.imageAndTitleSpacingConstraint = self.titleContainer.topAnchor.constraint(
            equalTo: self.groupImageView.bottomAnchor, constant: 16
        )
        self.imageAndTitleSpacingConstraint?.isActive = true
        NSLayoutConstraint.activate([
            self.closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            self.closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),

            self.groupImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            self.groupImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            self.titleContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            self.titleContainer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            self.titleContainer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            self.groupSubtitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            self.groupSubtitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            self.groupSubtitle.topAnchor.constraint(equalTo: self.titleContainer.bottomAnchor, constant: 12),

            self.membersView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            self.membersView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            self.membersView.topAnchor.constraint(equalTo: self.groupSubtitle.bottomAnchor, constant: 8),

            self.buttonsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            self.buttonsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            self.buttonsView.topAnchor.constraint(equalTo: self.membersView.bottomAnchor, constant: 20),

            self.buttonsView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24),

            self.groupImageView.trailingAnchor.constraint(equalTo: self.vkLogo.trailingAnchor, constant: 0),
            self.groupImageView.bottomAnchor.constraint(equalTo: self.vkLogo.bottomAnchor, constant: 0),
        ])

        return view
    }()

    private lazy var vkLogo: UIImageView = {
        var logo = UIImageView(frame: .init(x: 0, y: 0, width: 28, height: 28))
        logo.image = self.groupConfiguration.theme.images.vkidLogo.value
        logo.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logo.widthAnchor.constraint(equalToConstant: 28),
            logo.heightAnchor.constraint(equalToConstant: 28),
        ])
        logo.applyAvatarStyle(
            borderColor: self.groupConfiguration.theme.colors.background.value
        )
        return logo
    }()

    private lazy var groupImageView: UIImageView = {
        let imageView = UIImageView(frame: .init(x: 0, y: 0, width: 72, height: 72))

        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 72)
        self.imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 72)
        self.imageWidthConstraint?.isActive = true
        self.imageHeightConstraint?.isActive = true
        imageView.applyAvatarStyle(
            borderColor: self.groupConfiguration.theme.colors.background.value
        )
        if let groupAvatar = self.groupConfiguration.groupAvatar {
            imageView.loadImage(with: groupAvatar) { result in
                switch result {
                case .success((let image, _)):
                    imageView.image = image
                default: break
                }
            }
        }

        return imageView
    }()

    private lazy var groupTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 28
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byTruncatingTail
        var font: UIFont = .systemFont(ofSize: 23, weight: .semibold)
        var attributedString = NSMutableAttributedString(attributedString: NSAttributedString(
            string: self.groupConfiguration.title,
            attributes: [
                .paragraphStyle: paragraph,
                .font: font,
                .foregroundColor: self.groupConfiguration.theme.colors.title.value,
            ]
        ))
        label.attributedText = attributedString
        label.numberOfLines = 2
        return label
    }()

    private lazy var titleContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.addSubview(self.groupTitle)
        view.addSubview(self.verifiedImageView)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: self.groupTitle.topAnchor),
            view.bottomAnchor.constraint(equalTo: self.groupTitle.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: self.groupTitle.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.verifiedImageView.trailingAnchor),
            self.verifiedImageView.centerYAnchor.constraint(equalTo: self.groupTitle.centerYAnchor),
            self.groupTitle.trailingAnchor.constraint(equalTo: self.verifiedImageView.leadingAnchor, constant: -6),
        ])

        return view
    }()

    private lazy var verifiedImageView: UIImageView = {
        let imageView = UIImageView(frame: .init(
            x: 0,
            y: 0,
            width: self.groupConfiguration.isVerified ? 20 : 0,
            height: self.groupConfiguration.isVerified ? 20 : 0
        ))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = .verified
        let constraint = imageView.widthAnchor.constraint(
            equalToConstant: self.groupConfiguration.isVerified ? 20 : 0
        )
        self.verifiedImageViewConstraint = constraint
        NSLayoutConstraint.activate([
            constraint,
            imageView.heightAnchor.constraint(equalToConstant: self.groupConfiguration.isVerified ? 20 : 0),
        ])
        imageView.isHidden = !self.groupConfiguration.isVerified
        return imageView
    }()

    private lazy var groupSubtitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 20
        paragraph.maximumLineHeight = 20
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byTruncatingTail
        var font: UIFont = .systemFont(ofSize: 16, weight: .regular)
        label.attributedText = NSAttributedString(
            string: self.groupConfiguration.subtitle,
            attributes: [
                .paragraphStyle: paragraph,
                .font: font,
                .kern: 0.15,
                .foregroundColor: self.groupConfiguration.theme.colors.subtitle,
            ]
        )
        label.numberOfLines = 3
        return label
    }()

    private lazy var avatars: UIView = {
        let view = UIView()
        let maxAvatars = 3
        view.translatesAutoresizingMaskIntoConstraints = false
        var counter = 0
        var members = self.groupConfiguration.members
        var membersImages: [UIImageView] = []
        var constraints: [NSLayoutConstraint] = []

        view.backgroundColor = .clear
        constraints.append(view.heightAnchor.constraint(equalToConstant: 24))

        while counter < maxAvatars, members.count > counter {
            let member = members[counter]
            let imageView = UIImageView(frame: .init(x: 0, y: 0, width: 24, height: 24))
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.applyAvatarStyle(
                borderColor: self.groupConfiguration.theme.colors.background.value
            )
            imageView.backgroundColor = .clear
            imageView.image = .avatar
            if let url = member.avatarURL {
                imageView.loadImage(with: url) { result in
                    switch result {
                    case .success((let image, let url)):
                        if url == member.avatarURL {
                            imageView.image = image
                        }
                    case .failure(let error): break
                    }
                }
            }
            membersImages.append(imageView)
            constraints.append(imageView.heightAnchor.constraint(equalToConstant: 24))
            constraints.append(imageView.widthAnchor.constraint(equalToConstant: 24))
            constraints.append(imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor))
            view.addSubview(imageView)
            if counter > 0 {
                constraints.append(
                    imageView.trailingAnchor.constraint(
                        equalTo: membersImages[counter-1].leadingAnchor,
                        constant: 4
                    )
                )
            }
            counter+=1
        }
        if counter > 0 {
            constraints += [
                view.leadingAnchor.constraint(equalTo: membersImages[counter-1].leadingAnchor, constant: 0),
                view.trailingAnchor.constraint(equalTo: membersImages[0].trailingAnchor, constant: 0),
            ]
        } else {
            constraints.append(view.widthAnchor.constraint(equalToConstant: 0))
        }
        NSLayoutConstraint.activate(constraints)

        return view
    }()

    private lazy var membersInfoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.minimumLineHeight = 20
        paragraph.maximumLineHeight = 20
        paragraph.lineBreakMode = .byTruncatingTail
        let regularFont: UIFont = .systemFont(ofSize: 15, weight: .regular)
        let boldFont: UIFont = .systemFont(ofSize: 15, weight: .medium)
        let formatter = SubscriberCountFormatter()
        let subscribersNumber = formatter.format(subscriberCount: self.groupConfiguration.countOfMembers)
        let subscribersString = "followers"
            .localizedWithFormat(self.groupConfiguration.countOfMembers)
            .replacingOccurrences(of: String(self.groupConfiguration.countOfMembers), with: subscribersNumber)
        let friendsString: String
        if self.groupConfiguration.countOfFriends > 0 {
            let friendsNumber = formatter.format(subscriberCount: self.groupConfiguration.countOfFriends)
            let friends = "friends"
                .localizedWithFormat(self.groupConfiguration.countOfFriends)
                .replacingOccurrences(of: String(self.groupConfiguration.countOfFriends), with: friendsNumber)
            friendsString = " · \(friends)"
        } else {
            friendsString = ""
        }

        let string = "\(subscribersString)\(friendsString)"
        var resultString = NSMutableAttributedString(
            string: string,
            attributes: [
                .paragraphStyle: paragraph,
                .font: regularFont,
                .kern: 0.15,
                .foregroundColor: self.groupConfiguration.theme.colors.subtitle.value,
            ]
        )
        resultString.addAttribute(.font, value: boldFont, range: (string as NSString).range(of: subscribersNumber))
        label.numberOfLines = 1
        label.attributedText = resultString

        return label
    }()

    private lazy var membersView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.addSubview(self.avatars)
        view.addSubview(self.membersInfoLabel)

        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 36),
            view.topAnchor.constraint(equalTo: self.membersInfoLabel.topAnchor),
            view.bottomAnchor.constraint(equalTo: self.membersInfoLabel.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: self.avatars.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.membersInfoLabel.trailingAnchor),
            self.avatars.trailingAnchor.constraint(equalTo: self.membersInfoLabel.leadingAnchor,constant: -8),
            view.centerYAnchor.constraint(equalTo: self.avatars.centerYAnchor),
        ])

        return view
    }()

    private lazy var primaryButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(
            self.groupConfiguration.theme.colors.primaryButtonTitle.value,
            for: .normal
        )
        button.setTitle("vkid_group_subscription_primary".localized, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = self.groupConfiguration.buttonConfig.cornerRadius
        button.backgroundColor = self.groupConfiguration.theme.colors.primaryButtonBackground.value
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(
                equalToConstant: self.groupConfiguration.buttonConfig.height.rawValue
            ),
        ])
        button.addTarget(
            self,
            action: #selector(self.onPrimaryButtonTouchUpInside(sender:)),
            for: .touchUpInside
        )
        return button
    }()

    private lazy var secondaryButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(
            self.groupConfiguration.theme.colors.retryButtonTitle.value,
            for: .normal
        )
        button.setTitle("vkid_group_subscription_secondary".localized, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = self.groupConfiguration.buttonConfig.cornerRadius
        button.backgroundColor = self.groupConfiguration.theme.colors.retryButtonBackground.value
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: self.groupConfiguration.buttonConfig.height.rawValue),
        ])
        button.addTarget(
            self,
            action: #selector(self.onSecondaryButtonTouchUpInside(sender:)),
            for: .touchUpInside
        )
        return button
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(self.groupConfiguration.theme.images.closeButton.value, for: .normal)
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44),
        ])
        button.addTarget(
            self,
            action: #selector(self.onCloseButtonTouchUpInside(sender:)),
            for: .touchUpInside
        )
        return button
    }()

    private lazy var buttonsView: UIView = {
        let buttonsWrapper = UIView()
        buttonsWrapper.translatesAutoresizingMaskIntoConstraints = false
        buttonsWrapper.backgroundColor = .clear
        buttonsWrapper.addSubview(self.activityIndicator)
        buttonsWrapper.addSubview(self.primaryButton)
        buttonsWrapper.addSubview(self.secondaryButton)
        NSLayoutConstraint.activate([
            buttonsWrapper.topAnchor.constraint(equalTo: self.primaryButton.topAnchor),
            buttonsWrapper.bottomAnchor.constraint(equalTo: self.secondaryButton.bottomAnchor),

            self.primaryButton.bottomAnchor.constraint(equalTo: self.secondaryButton.topAnchor, constant: -12),

            buttonsWrapper.leadingAnchor.constraint(equalTo: self.primaryButton.leadingAnchor),
            buttonsWrapper.leadingAnchor.constraint(equalTo: self.secondaryButton.leadingAnchor),
            buttonsWrapper.trailingAnchor.constraint(equalTo: self.primaryButton.trailingAnchor),
            buttonsWrapper.trailingAnchor.constraint(equalTo: self.secondaryButton.trailingAnchor),

            self.primaryButton.centerXAnchor.constraint(equalTo: self.activityIndicator.centerXAnchor),
            self.primaryButton.centerYAnchor.constraint(equalTo: self.activityIndicator.centerYAnchor),
        ])

        return buttonsWrapper
    }()

    private lazy var activityIndicator: ActivityIndicatorView = {
        let size = self.groupConfiguration.buttonConfig.height.rawValue * 0.65
        let activityIndicator = ActivityIndicatorView(
            frame: .init(x: 0, y: 0, width: size, height: size),
            lineWidth: 2
        )
        activityIndicator.tintColor = self.groupConfiguration.theme.colors.activityIndicatorColor.value
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.widthAnchor.constraint(equalToConstant: size),
            activityIndicator.heightAnchor.constraint(equalToConstant: size),
        ])
        return activityIndicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.vkidAnalitycs.sendAnalytics(
            groupId: self.groupConfiguration.groupId,
            themeType: self.groupConfiguration.theme.colorScheme,
            authorizer: self.authorizer,
            eventType: .modalViewShown
        )
    }

    @objc
    private func onPrimaryButtonTouchUpInside(sender: UIControl) {
        switch self.state {
        case .preview:
            self.state = .previewInProgress
            self.vkidAnalitycs.sendAnalytics(
                groupId: self.groupConfiguration.groupId,
                themeType: self.groupConfiguration.theme.colorScheme,
                authorizer: self.authorizer,
                eventType: .subscribe
            )
        case .retry:
            self.state = .retryInProgress
            self.vkidAnalitycs.sendAnalytics(
                groupId: self.groupConfiguration.groupId,
                themeType: self.groupConfiguration.theme.colorScheme,
                authorizer: self.authorizer,
                eventType: .errorRetry
            )
        default:
            break
        }
        self.groupConfiguration.subscribe { [weak self] result in
            guard let self else { return }
            switch result {
            case.success(let success):
                self.isSuccess = success
                if !success {
                    self.state = .retry
                    self.vkidAnalitycs.sendAnalytics(
                        groupId: self.groupConfiguration.groupId,
                        themeType: self.groupConfiguration.theme.colorScheme,
                        authorizer: self.authorizer,
                        eventType: .errorShown
                    )
                }
            case .failure(let error):
                self.error = error
                self.state = .retry
                self.vkidAnalitycs.sendAnalytics(
                    groupId: self.groupConfiguration.groupId,
                    themeType: self.groupConfiguration.theme.colorScheme,
                    authorizer: self.authorizer,
                    eventType: .errorShown
                )
            }
        }
    }

    @objc
    private func onSecondaryButtonTouchUpInside(sender: UIControl) {
        let subscriptionError: GroupSubscriptionError = switch self.error {
        case nil: self.state == .retry ? .failedSubscription : .canceledByUser
        case .invalidAccessToken:.invalidAccessToken
        default: .unknown
        }
        self.result = .failure(subscriptionError)
        if self.state == .preview {
            self.vkidAnalitycs.sendAnalytics(
                groupId: self.groupConfiguration.groupId,
                themeType: self.groupConfiguration.theme.colorScheme,
                authorizer: self.authorizer,
                eventType: .nextTimeTap
            )
        } else {
            self.vkidAnalitycs.sendAnalytics(
                groupId: self.groupConfiguration.groupId,
                themeType: self.groupConfiguration.theme.colorScheme,
                authorizer: self.authorizer,
                eventType: .errorCancelTap
            )
        }
        self.dismiss(animated: true)
    }

    @objc
    private func onCloseButtonTouchUpInside(sender: UIControl) {
        self.result = .failure(.closedByUser)
        if self.state == .preview {
            self.vkidAnalitycs.sendAnalytics(
                groupId: self.groupConfiguration.groupId,
                themeType: self.groupConfiguration.theme.colorScheme,
                authorizer: self.authorizer,
                eventType: .closeTap
            )
        } else {
            self.vkidAnalitycs.sendAnalytics(
                groupId: self.groupConfiguration.groupId,
                themeType: self.groupConfiguration.theme.colorScheme,
                authorizer: self.authorizer,
                eventType: .errorCloseTap
            )
        }
        self.dismiss(animated: true)
    }

    private func render(state: GroupSubscriptionState) {
        func setInProgress() {
            self.primaryButton.isEnabled = false
            self.secondaryButton.isEnabled = false
            self.primaryButton.setTitle(nil, for: .normal)
            self.activityIndicator.startAnimating()
            self.activityIndicator.isHidden = false
            self.buttonsView.bringSubviewToFront(self.activityIndicator)
            self.verifiedImageView.isHidden = true
            self.verifiedImageViewConstraint?.constant = 0
        }
        switch state {
        case .preview:
            self.primaryButton.isEnabled = true
            self.secondaryButton.isEnabled = true
            self.buttonsView.sendSubviewToBack(self.activityIndicator)
            self.activityIndicator.isHidden = true
            self.contentDelegate?.bottomSheetContentDidInvalidateContentSize(self)
        case .previewInProgress:
            setInProgress()
            self.contentDelegate?.bottomSheetContentDidInvalidateContentSize(self)
        case .retry:
            UIView.transition(
                with: self.contentPlaceholderView,
                duration: 0.25,
                options: [
                    .layoutSubviews,
                    .curveEaseInOut,
                ]
            ) {
                self.primaryButton.isEnabled = true
                self.secondaryButton.isEnabled = true
                self.primaryButton.setTitle("vkid_group_subscription_fail_primary".localized, for: .normal)
                self.secondaryButton.setTitle("vkid_group_subscription_fail_secondary".localized, for: .normal)
                self.groupImageView.image = self.groupConfiguration.theme.images.failImage.value
                self.groupImageView.applyAvatarStyle(borderColor: .clear)
                self.vkLogo.isHidden = true
                self.imageWidthConstraint?.constant = 56
                self.imageHeightConstraint?.constant = 56
                self.imageAndTitleSpacingConstraint?.constant = 20
                self.groupTitle.text = "vkid_group_subscription_fail_title".localized
                self.groupSubtitle.text = "vkid_group_subscription_fail_description".localized
                self.groupSubtitle.textAlignment = .center
                self.buttonsView.sendSubviewToBack(self.activityIndicator)
                self.membersView.removeFromSuperview()
                self.activityIndicator.isHidden = true
                self.buttonsView.topAnchor.constraint(
                    equalTo: self.groupSubtitle.bottomAnchor,
                    constant: 32
                ).isActive = true
                self.contentDelegate?.bottomSheetContentDidInvalidateContentSize(self)
            }
        case .retryInProgress:
            setInProgress()
            self.contentDelegate?.bottomSheetContentDidInvalidateContentSize(self)
        }
    }
}

extension GroupSubscriptionContentViewController {
    fileprivate enum GroupSubscriptionState {
        case preview
        case previewInProgress
        case retry
        case retryInProgress
    }
}

extension UIImageView {
    fileprivate func applyAvatarStyle(borderColor: UIColor) {
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = 2
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.masksToBounds = true
    }
}
