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
import VKID
import VKIDCore

final class AuthViewController: VKIDDemoViewController {
    var debugSettings: DebugSettingsStorage!

    private enum Constants {
        static let authButtonSize = CGSize(width: 220, height: 40)
    }

    private lazy var termsOfAgreementLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label
            .text =
            "Нажимая “Войти через VK ID”, вы принимаете пользовательское соглашение и политику конфиденциальности"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = label.textColor.withAlphaComponent(0.3)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var authButton: UIView = {
        guard let vkid = self.vkid else {
            fatalError("No vkid provided")
        }
        let oneTap = OneTapButton(
            layout: .regular(
                height: .medium(.h44),
                cornerRadius: 8
            ),
            presenter: .uiViewController(self),
            onCompleteAuth: nil
        )
        return vkid.ui(for: oneTap).uiView()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.addTermsOfAgreement()
        self.addAuthButton()
        self.addDebugSettingsButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.vkid?.add(observer: self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.vkid?.remove(observer: self)
    }

    private func addTermsOfAgreement() {
        self.view.addSubview(self.termsOfAgreementLabel)

        NSLayoutConstraint.activate([
            self.termsOfAgreementLabel.bottomAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
            ),
            self.termsOfAgreementLabel.leadingAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            self.termsOfAgreementLabel.trailingAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            ),
        ])
    }

    private func addAuthButton() {
        self.view.addSubview(self.authButton)
        self.authButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.authButton.leadingAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            self.authButton.trailingAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            ),
            self.authButton.bottomAnchor.constraint(equalTo: self.termsOfAgreementLabel.topAnchor, constant: -8),
            self.authButton.topAnchor.constraint(greaterThanOrEqualTo: self.descriptionLabel.bottomAnchor),
        ])
    }

    private func addDebugSettingsButton() {
        let bt = UIBarButtonItem(
            title: "Debug",
            style: .plain,
            target: self,
            action: #selector(self.onOpenDebugSettings(sender:))
        )
        self.navigationItem.rightBarButtonItem = bt
    }

    @objc
    private func onOpenDebugSettings(sender: AnyObject) {
        let tableStyle: UITableView.Style = {
            if #available(iOS 13.0, *) {
                return .insetGrouped
            } else {
                return .grouped
            }
        }()
        let settings = DebugSettingsViewController(style: tableStyle)
        let navigation = UINavigationController(rootViewController: settings)
        self.present(navigation, animated: true)
        settings.render(viewModel: self.buildDebugSettings())
        self.debugSettingsVC = settings
    }
}

extension AuthViewController: VKIDObserver {
    func vkid(_ vkid: VKID, didLogoutFrom session: UserSession, with result: LogoutResult) {}

    func vkid(_ vkid: VKID, didStartAuthUsing oAuth: OAuthProvider) {}

    func vkid(_ vkid: VKID, didCompleteAuthWith result: AuthResult, in oAuth: OAuthProvider) {
        do {
            let session = try result.get()
            print("Auth succeeded with\n\(session)")
            self.showAlert(message: session.debugDescription)
        } catch AuthError.cancelled {
            print("Auth cancelled by user")
        } catch {
            print("Auth failed with error: \(error)")
            self.showAlert(message: "Ошибка авторизации")
        }
    }
}
