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

    private let vkid: VKID
    private let oneTapButton: UIView
    private let serviceName: String
    private let targetActionText: OneTapBottomSheet.TargetActionText
    private let theme: OneTapBottomSheet.Theme
    private let autoDismissOnSuccess: Bool
    private let onCompleteAuth: AuthResultCompletion?
    private let presenter: UIKitPresenter?
    private var result: AuthResult?

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
        contentDelegate: BottomSheetContentDelegate? = nil,
        presenter: UIKitPresenter? = nil
    ) {
        self.vkid = vkid
        self.theme = theme
        self.oneTapButton = oneTapButton
        self.serviceName = serviceName
        self.targetActionText = targetActionText
        self.autoDismissOnSuccess = autoDismissOnSuccess
        self.onCompleteAuth = onCompleteAuth
        self.contentDelegate = contentDelegate
        self.presenter = presenter
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
                vkIdImage: self.theme.images.logo,
                authButton: self.oneTapButton,
                title: self.targetActionText.title,
                titleColor: self.theme.colors.title,
                titleFont: .systemFont(ofSize: 23, weight: .semibold),
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
                failedButtonTitleFont: .systemFont(ofSize: 15, weight: .medium),
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
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 48),
            button.heightAnchor.constraint(equalToConstant: 48),
        ])
        return button
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
        self.apply(theme: self.theme)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.vkid.rootContainer.productAnalytics.screenProceed
            .context { ctx in
                ctx.screen = .floatingOneTap
                return ctx
            }
            .send(
                .init(
                    themeType: self.theme.colorScheme,
                    textType: self.targetActionText.rawType.rawValue
                )
            )
    }

    @objc
    private func onCloseClicked(sender: Any) {
        if let presenter, let parent {
            presenter.dismiss(parent) {
                self.onCompleteAuth?(.failure(.cancelled))
            }
        } else {
            self.dismiss(animated: true) {
                self.onCompleteAuth?(.failure(.cancelled))
            }
        }
    }

    private func setupUI() {
        self.view.backgroundColor = .clear
        self.view.addSubview(self.contentPlaceholderView)
        self.view.addSubview(self.closeButton)

        NSLayoutConstraint.activate([
            self.closeButton.topAnchor.constraint(
                equalTo: self.view.topAnchor,
                constant: 4
            ),
            self.closeButton.trailingAnchor.constraint(
                equalTo: self.view.trailingAnchor,
                constant: -4
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
            equalTo: self.view.topAnchor,
            constant: Constants.contentPlaceholderInsets.top
        )
        verticalSpacer.priority = .defaultLow
        verticalSpacer.isActive = true

        self.contentPlaceholderView.addSubview(self.initialStateView) {
            $0.pinToEdges()
        }
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
        self.closeButton.setImage(
            self.theme.images.topBarCloseButton.value,
            for: .normal
        )
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

            self.vkid.rootContainer.productAnalytics.dataLoading
                .context { ctx in
                    ctx.screen = .floatingOneTap
                    return ctx
                }
                .send()

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
            top: 24,
            left: 24,
            bottom: 24,
            right: 24
        )
    }
}

extension OneTapBottomSheetContentViewController: OneTapBottomSheetAuthStateViewDelegate {
    func authStateViewDidTapOnRetryButton(_ view: OneTapBottomSheetAuthStateView) {
        guard let oAuth = self.currentOAuthProivder, !vkid.isAuthorizing else { return }
        self.result = nil
        self.vkid.authorize(
            authContext: .init(launchedBy: .oneTapBottomSheetRetry),
            authConfig: .init(),
            oAuthProviderConfig: .init(primaryProvider: oAuth),
            presenter: .newUIWindow,
            completion: { _ in }
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
        if self.result == nil {
            self.result = result
            switch result {
            case .success:
                self.handleSuccessResult(result)
            case .failure(let error):
                switch error {
                case .cancelled: self.authState = .idle
                case .authCodeExchangedOnYourBackend:
                    self.handleSuccessResult(result)
                    return
                case .unknown, .codeVerifierNotProvided: self.authState = .failure
                case .authAlreadyInProgress: break
                }
                self.onCompleteAuth?(result)
            }
        }
    }

    func handleSuccessResult(_ result: AuthResult) {
        if self.authState != .success {
            self.result = result
            self.authState = .success
            guard self.autoDismissOnSuccess else {
                self.onCompleteAuth?(result)
                return
            }
            DispatchQueue
                .main
                .asyncAfter(deadline: .now() + 0.1) { [weak self, onComplete = self.onCompleteAuth] in
                    if self?.isBeingDismissed == false {
                        if let presenter = self?.presenter, let parent = self?.parent {
                            presenter.dismiss(parent) {
                                onComplete?(result)
                            }
                        } else {
                            self?.dismiss(animated: true) {
                                onComplete?(result)
                            }
                        }
                    } else {
                        onComplete?(result)
                    }
                }
        }
    }
}
