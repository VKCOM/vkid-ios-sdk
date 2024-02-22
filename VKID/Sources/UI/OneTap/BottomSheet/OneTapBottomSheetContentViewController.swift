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

internal final class OneTapBottomSheetContentViewController: UIViewController, BottomSheetContent {
    public weak var contentDelegate: BottomSheetContentDelegate?

    private let vkid: VKID
    private let oneTapButton: UIView
    private let serviceName: String
    private let targetActionText: OneTapBottomSheet.TargetActionText
    private let theme: OneTapBottomSheet.Theme
    private let autoDismissOnSuccess: Bool
    private let onCompleteAuth: AuthResultCompletion?

    private var currentOAuthProivder: OAuthProvider?

    private var authState: AuthState = .idle {
        didSet {
            guard oldValue != self.authState else {
                return
            }
            self.render(authState: self.authState)
        }
    }

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
        self.vkid = vkid
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

    deinit {
        self.vkid.remove(observer: self)
    }

    private lazy var initialStateView: OneTapBottomSheetInitialStateView = {
        let view = OneTapBottomSheetInitialStateView(
            configuration:
            .init(
                authButton: self.oneTapButton,
                title: self.targetActionText.title,
                titleColor: self.theme.colors.title,
                titleFont: .systemFont(ofSize: 20, weight: .medium),
                subtitle: self.targetActionText.subtitle,
                subtitleColor: self.theme.colors.subtitle,
                subtitleFont: .systemFont(ofSize: 16, weight: .regular)
            )
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var authStateView: OneTapBottomSheetAuthStateView = {
        let view = OneTapBottomSheetAuthStateView(
            configuration:
            .init(
                titleColor: self.theme.colors.subtitle,
                titleFont: .systemFont(ofSize: 16, weight: .regular),
                successImage: .checkCircleOutline,
                failedImage: .errorOutline,
                failedButtonColor: self.theme.colors.retryButtonBackground,
                failedButtonTitleColor: self.theme.colors.retryButtonTitle,
                failedButtonTitleFont: .systemFont(ofSize: 14, weight: .medium),
                failedButtonCornerRadius: 10,
                texts: .init(
                    loadingText: "vkid_sheet_state_auth_in_progress".localized,
                    successText: "vkid_sheet_state_auth_success".localized,
                    failedText: "vkid_sheet_state_auth_failed".localized,
                    failedButtonText: "vkid_sheet_state_auth_failed_retry".localized
                )
            )
        )
        view.delegate = self

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

    private lazy var contentPlaceholderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }

    private func setupUI() {
        self.view.backgroundColor = .clear

        self.view.addSubview(self.topBar)
        self.view.addSubview(self.contentPlaceholderView)

        NSLayoutConstraint.activate([
            self.topBar.topAnchor.constraint(
                equalTo: self.view.topAnchor
            ),
            self.topBar.leadingAnchor.constraint(
                equalTo: self.view.leadingAnchor
            ),
            self.topBar.trailingAnchor.constraint(
                equalTo: self.view.trailingAnchor
            ),
            self.contentPlaceholderView.leadingAnchor.constraint(
                equalTo: self.view.leadingAnchor,
                constant: Constants.contentPlaceholderInsets.left
            ),
            self.contentPlaceholderView.trailingAnchor.constraint(
                equalTo: self.view.trailingAnchor,
                constant: -Constants.contentPlaceholderInsets.right
            ),
            self.contentPlaceholderView.bottomAnchor.constraint(
                equalTo: self.view.bottomAnchor,
                constant: -Constants.contentPlaceholderInsets.bottom
            ),
        ])

        let verticalSpacer = self.contentPlaceholderView.topAnchor.constraint(
            equalTo: self.topBar.bottomAnchor
        )
        verticalSpacer.priority = .defaultLow
        verticalSpacer.isActive = true

        self.contentPlaceholderView.addSubview(self.initialStateView) {
            $0.pinToEdges()
        }
    }

    private func onClose() {
        self.dismiss(animated: true)
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
        self.apply(theme: self.theme)
    }

    private func apply(theme: OneTapBottomSheet.Theme) {
        self.view.backgroundColor = theme.colors.background.value
    }

    private func render(authState: AuthState) {
        switch authState {
        case .idle:
            UIView.transition(
                with: self.contentPlaceholderView,
                duration: 0.25,
                options: [
                    .layoutSubviews,
                    .curveEaseInOut,
                    .transitionCrossDissolve,
                ]
            ) {
                self.authStateView.removeFromSuperview()
                self.contentPlaceholderView.addSubview(self.initialStateView) {
                    $0.pinToEdges()
                }
                self.contentDelegate?.bottomSheetContentDidInvalidateContentSize(self)
            }
        case .inProgress:
            do { // Actualize layout before animation start to avoid glitches
                self.contentPlaceholderView.addSubview(self.authStateView) {
                    $0.pinToEdges()
                }
                self.contentPlaceholderView.sendSubviewToBack(self.authStateView)
                self.contentPlaceholderView.layoutIfNeeded()
            }

            UIView.transition(
                with: self.contentPlaceholderView,
                duration: 0.25,
                options: [
                    .layoutSubviews,
                    .curveEaseInOut,
                    .transitionCrossDissolve,
                ]
            ) {
                self.initialStateView.removeFromSuperview()
                self.authStateView.render(authState: .inProgress)
                self.contentDelegate?.bottomSheetContentDidInvalidateContentSize(self)
            }
        case .success, .failure:
            UIView.transition(
                with: self.initialStateView,
                duration: 0.25,
                options: [
                    .layoutSubviews,
                    .curveEaseInOut,
                ]
            ) {
                self.authStateView.render(authState: authState)
                self.contentDelegate?.bottomSheetContentDidInvalidateContentSize(self)
            } completion: { completed in
                if completed {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(
                        authState == .success ? .success : .error
                    )
                }
            }
        }
    }
}

extension OneTapBottomSheetContentViewController {
    enum AuthState {
        case idle
        case inProgress
        case success
        case failure
    }

    enum Constants {
        static let contentPlaceholderInsets = UIEdgeInsets(
            top: 16,
            left: 16,
            bottom: 16,
            right: 16
        )
    }
}

extension OneTapBottomSheetContentViewController: OneTapBottomSheetAuthStateViewDelegate {
    func authStateViewDidTapOnRetryButton(_ view: OneTapBottomSheetAuthStateView) {
        guard let oAuth = self.currentOAuthProivder, !vkid.isAuthorizing else { return }

        self.vkid.authorize(
            with: .init(oAuthProvider: oAuth),
            using: .newUIWindow,
            completion: { [onCompleteAuth = self.onCompleteAuth] result in
                onCompleteAuth?(result)
            }
        )
    }
}

extension OneTapBottomSheetContentViewController: VKIDObserver {
    func vkid(_ vkid: VKID, didLogoutFrom session: UserSession, with result: LogoutResult) {}

    func vkid(_ vkid: VKID, didStartAuthUsing oAuth: OAuthProvider) {
        self.authState = .inProgress
        self.currentOAuthProivder = oAuth
    }

    func vkid(_ vkid: VKID, didCompleteAuthWith result: AuthResult, in oAuth: OAuthProvider) {
        switch result {
        case .success:
            self.authState = .success
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
        case .failure(let error):
            switch error {
            case .cancelled: self.authState = .idle
            case .unknown: self.authState = .failure
            case .authAlreadyInProgress: break
            }
            self.onCompleteAuth?(result)
        }
    }
}
