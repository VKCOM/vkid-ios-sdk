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

internal protocol OneTapBottomSheetAuthStateViewDelegate: AnyObject {
    func authStateViewDidTapOnRetryButton(_ view: OneTapBottomSheetAuthStateView)
}

final class OneTapBottomSheetAuthStateView: UIView {
    private let config: Configuration
    weak var delegate: OneTapBottomSheetAuthStateViewDelegate?

    private lazy var stateImageViewContainer: UIView = {
        let view = UIView()
        view.addSubview(self.stateIconImageView) {
            $0.pinSize(Constants.imageViewSize)
        }
        view.addSubview(self.activityIndicator) {
            $0.pinSize(Constants.activityIndicatorSize)
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: Constants.imageViewSize.width),
            view.heightAnchor.constraint(equalToConstant: Constants.imageViewSize.height),
            self.stateIconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            self.stateIconImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            self.activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            self.activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        return view
    }()

    private lazy var stateIconImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var activityIndicator: ActivityIndicatorView = {
        let spinner = ActivityIndicatorView(
            frame: CGRect(origin: .zero, size: Constants.activityIndicatorSize),
            lineWidth: Constants.spinnerLineWidth
        )
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.tintColor = .textAccentThemed
        spinner.alpha = 0
        return spinner
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = self.config.titleFont
        label.textColor = self.config.titleColor.value
        label.textAlignment = .center
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var retryButton: UIButton = {
        let button: UIButton
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.contentInsets = .init(
                top: Constants.buttonContentInsets.top,
                leading: Constants.buttonContentInsets.left,
                bottom: Constants.buttonContentInsets.bottom,
                trailing: Constants.buttonContentInsets.right
            )
            button = UIButton(configuration: config)
        } else {
            button = UIButton()
            button.contentEdgeInsets = Constants.buttonContentInsets
        }
        button.titleLabel?.font = self.config.retryButtonTitleFont
        button.layer.cornerRadius = self.config.retryButtonCornerRadius
        button.setTitle(self.config.texts.failedButtonText, for: .normal)
        button.setTitleColor(self.config.retryButtonTitleColor.value, for: .normal)
        button.backgroundColor = self.config.retryButtonColor.value
        button.addTarget(self, action: #selector(self.retryButtonTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0
        return button
    }()

    private var titleLabelToBottomEdgeConstraint: NSLayoutConstraint?
    private var retryButtonToBottomEdgeConstraint: NSLayoutConstraint?

    internal init(configuration: Configuration) {
        self.config = configuration
        super.init(frame: .zero)
        self.addControls()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addControls() {
        self.addSubview(self.stateImageViewContainer)
        self.addSubview(self.titleLabel)
        self.addSubview(self.retryButton)

        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.stateImageViewContainer.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: Constants.authStateViewTopInset
            ),
            self.stateImageViewContainer.centerXAnchor.constraint(
                equalTo: self.centerXAnchor
            ),
            self.titleLabel.topAnchor.constraint(
                equalTo: self.stateImageViewContainer.bottomAnchor,
                constant: Constants.titleInsets.top
            ),
            self.titleLabel.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: Constants.titleInsets.left
            ),
            self.titleLabel.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -Constants.titleInsets.right
            ),
            self.retryButton.topAnchor.constraint(
                equalTo: self.titleLabel.bottomAnchor,
                constant: Constants.retryButtonInsets.top
            ),
            self.retryButton.centerXAnchor.constraint(
                equalTo: self.centerXAnchor
            ),
            self.retryButton.leadingAnchor.constraint(
                greaterThanOrEqualTo: self.leadingAnchor,
                constant: Constants.retryButtonInsets.left
            ),
            self.retryButton.trailingAnchor.constraint(
                lessThanOrEqualTo: self.trailingAnchor,
                constant: Constants.retryButtonInsets.right
            ),
        ])

        self.titleLabelToBottomEdgeConstraint = self.titleLabel.bottomAnchor.constraint(
            equalTo: self.bottomAnchor,
            constant: -Constants.titleInsets.bottom
        )
        self.titleLabelToBottomEdgeConstraint?.isActive = true

        self.retryButtonToBottomEdgeConstraint = self.retryButton.bottomAnchor.constraint(
            equalTo: self.bottomAnchor,
            constant: -Constants.retryButtonInsets.bottom
        )
    }

    @objc
    private func retryButtonTap(_ sender: UIButton) {
        self.delegate?.authStateViewDidTapOnRetryButton(self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.apply(config: self.config)
    }

    private func apply(config: Configuration) {
        self.titleLabel.textColor = self.config.titleColor.value
        self.retryButton.setTitleColor(self.config.retryButtonTitleColor.value, for: .normal)
        self.retryButton.backgroundColor = self.config.retryButtonColor.value
    }
}

extension OneTapBottomSheetAuthStateView {
    internal func render(authState: OneTapBottomSheetContentViewController.AuthState) {
        switch authState {
        case .inProgress:
            self.retryButton.alpha = 0
            self.titleLabel.text = self.config.texts.loadingText
            self.stateIconImageView.alpha = 0
            self.activityIndicator.alpha = 1
            self.activityIndicator.startAnimating()
            self.retryButtonToBottomEdgeConstraint?.isActive = false
            self.titleLabelToBottomEdgeConstraint?.isActive = true
        case .success:
            self.retryButton.alpha = 0
            self.titleLabel.text = self.config.texts.successText
            self.stateIconImageView.image = self.config.successImage
            self.stateIconImageView.alpha = 1
            self.activityIndicator.alpha = 0
            self.activityIndicator.stopAnimating()
            self.retryButtonToBottomEdgeConstraint?.isActive = false
            self.titleLabelToBottomEdgeConstraint?.isActive = true
        case .failure:
            self.retryButton.alpha = 1
            self.titleLabel.text = self.config.texts.failedText
            self.stateIconImageView.image = self.config.failedImage
            self.stateIconImageView.alpha = 1
            self.activityIndicator.alpha = 0
            self.activityIndicator.stopAnimating()
            self.titleLabelToBottomEdgeConstraint?.isActive = false
            self.retryButtonToBottomEdgeConstraint?.isActive = true
        case .idle:
            break
        }

        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}

extension OneTapBottomSheetAuthStateView {
    private enum Constants {
        static let imageViewSize: CGSize = .init(width: 56, height: 56)
        static let activityIndicatorSize: CGSize = .init(width: 74, height: 74)
        static let spinnerLineWidth: CGFloat = 3.0
        static let authStateViewTopInset: CGFloat = 48.0
        static let buttonContentInsets: UIEdgeInsets = .init(
            top: 6,
            left: 16,
            bottom: 6,
            right: 16
        )
        static let titleInsets: UIEdgeInsets = .init(
            top: 12,
            left: 32,
            bottom: 48,
            right: 32
        )
        static let retryButtonInsets: UIEdgeInsets = .init(
            top: 16,
            left: 32,
            bottom: 48,
            right: 32
        )
    }
}
