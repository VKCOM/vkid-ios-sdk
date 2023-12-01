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
import VKIDCore

internal final class OneTapBottomSheetContentViewController: UIViewController, BottomSheetContent {
    public weak var contentDelegate: BottomSheetContentDelegate?

    private let oneTapButton: UIView
    private let serviceName: String
    private let targetActionText: OneTapBottomSheet.TargetActionText
    private let theme: OneTapBottomSheet.Theme
    private let autoDismissOnSuccess: Bool
    private let onCompleteAuth: AuthResultCompletion?

    internal init(
        vkid: VKID,
        theme: OneTapBottomSheet.Theme,
        oneTapButton: UIView,
        serviceName: String,
        targetActionText: OneTapBottomSheet.TargetActionText,
        autoDismissOnSuccess: Bool,
        onCompleteAuth: AuthResultCompletion?,
        contentDelegate: BottomSheetContentDelegate? = nil
    ) {
        self.theme = theme
        self.oneTapButton = oneTapButton
        self.serviceName = serviceName
        self.targetActionText = targetActionText
        self.autoDismissOnSuccess = autoDismissOnSuccess
        self.onCompleteAuth = onCompleteAuth
        self.contentDelegate = contentDelegate
        super.init(nibName: nil, bundle: nil)
        vkid.add(observer: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var initialStateView: OneTapBottomSheetInitialStateView = {
        let view = OneTapBottomSheetInitialStateView(
            configuration:
            .init(
                authButton: oneTapButton,
                title: targetActionText.title,
                titleColor: self.theme.colors.title,
                titleFont: .systemFont(ofSize: 20, weight: .medium),
                subtitle: self.targetActionText.subtitle,
                subtitleColor: self.theme.colors.subtitle,
                subtitleFont: .systemFont(ofSize: 16, weight: .regular)
            )
        )

        return view
    }()

    private lazy var topBar: UIView = {
        let bar = OneTapBottomSheetTopBar(
            configuration: .init(
                title: self.serviceName,
                titleColor: self.theme.colors.topBarTitle,
                logoIDColor: self.theme.colors.topBarLogo,
                logoIcon: self.theme.images.topBarLogo,
                closeButtonIcon: self.theme.images.topBarCloseButton
            ) { [weak self] in
                guard let self else {
                    return
                }
                self.onClose()
            }
        )
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.addArrangedSubview(self.initialStateView)
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.alignment = .fill

        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }

    private func setupUI() {
        self.view.backgroundColor = .clear
        self.contentStackView.clipsToBounds = false
        self.view.addSubview(self.topBar)
        self.view.addSubview(self.contentStackView)
        NSLayoutConstraint.activate([
            self.topBar.topAnchor.constraint(
                equalTo: self.view.topAnchor,
                constant: Constants.topBarInsets.top
            ),
            self.topBar.leadingAnchor.constraint(
                equalTo: self.view.leadingAnchor,
                constant: Constants.topBarInsets.left
            ),
            self.topBar.trailingAnchor.constraint(
                equalTo: self.view.trailingAnchor,
                constant: -Constants.topBarInsets.right
            ),
            self.contentStackView.leadingAnchor.constraint(
                equalTo: self.view.leadingAnchor,
                constant: Constants.contentStackViewInsets.left
            ),
            self.contentStackView.trailingAnchor.constraint(
                equalTo: self.view.trailingAnchor,
                constant: -Constants.contentStackViewInsets.right
            ),
            self.contentStackView.topAnchor.constraint(
                equalTo: self.topBar.bottomAnchor
            ),
            self.contentStackView.bottomAnchor.constraint(
                equalTo: self.view.bottomAnchor,
                constant: -Constants.contentStackViewInsets.bottom
            ),
        ])
    }

    private func onClose() {
        self.dismiss(animated: true)
    }

    func preferredContentSize(withParentContainerSize parentSize: CGSize) -> CGSize {
        let headerSize = self.topBar.systemLayoutSizeFitting(
            parentSize - Constants.topBarInsets,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        let stackViewDiffSize = CGSize(
            width: Constants.contentStackViewInsets.left + Constants.contentStackViewInsets.right,
            height: headerSize.height + Constants.topBarInsets.top + Constants.contentStackViewInsets.bottom
        )
        let stackViewSize = self.contentStackView.systemLayoutSizeFitting(
            parentSize - stackViewDiffSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        return CGSize(
            width: headerSize.width + Constants.topBarInsets.left + Constants.topBarInsets.right,
            height: headerSize.height + Constants.topBarInsets.top +
                stackViewSize.height + Constants.contentStackViewInsets.bottom
        )
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.apply(theme: self.theme)
    }

    private func apply(theme: OneTapBottomSheet.Theme) {
        self.view.backgroundColor = theme.colors.background.value
    }
}

extension OneTapBottomSheetContentViewController {
    enum Constants {
        static let contentStackViewInsets = UIEdgeInsets(
            top: 16,
            left: 16,
            bottom: 16,
            right: 16
        )

        static let topBarInsets = UIEdgeInsets(
            top: 2,
            left: 16,
            bottom: 0,
            right: 2
        )
    }
}

extension OneTapBottomSheetContentViewController: VKIDObserver {
    func vkid(_ vkid: VKID, didStartAuthUsing oAuth: OAuthProvider) {}

    func vkid(_ vkid: VKID, didCompleteAuthWith result: AuthResult, in oAuth: OAuthProvider) {
        switch result {
        case .success:
            guard self.autoDismissOnSuccess else {
                self.onCompleteAuth?(result)
                return
            }
            DispatchQueue
                .main
                .asyncAfter(deadline: .now() + 0.5) { [weak self, onComplete = self.onCompleteAuth] in
                    if self?.isBeingDismissed == false {
                        self?.dismiss(animated: true) {
                            onComplete?(result)
                        }
                    } else {
                        onComplete?(result)
                    }
                }
        case .failure:
            self.onCompleteAuth?(result)
        }
    }
}
