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

import Foundation
import UIKit
@_spi(VKIDDebug)
import VKID

final class CaptchaViewController: VKIDDemoViewController {
    private lazy var defaultCaptchaButton: UIButton = {
        let bt = UIButton(type: .system)
        bt.setTitle(
            "Show default captcha",
            for: .normal
        )
        bt.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        if #available(iOS 13.0, *) {
            bt.setTitleColor(.label, for: .normal)
        } else {
            bt.setTitleColor(.black, for: .normal)
        }
        bt.addTarget(
            self,
            action: #selector(self.onOpenDefaultCaptcha(sender:)),
            for: .touchUpInside
        )

        bt.translatesAutoresizingMaskIntoConstraints = false
        return bt
    }()

    private lazy var domainCaptchaButton: UIButton = {
        let bt = UIButton(type: .system)
        bt.setTitle(
            "Show domain captcha",
            for: .normal
        )
        bt.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        if #available(iOS 13.0, *) {
            bt.setTitleColor(.label, for: .normal)
        } else {
            bt.setTitleColor(.black, for: .normal)
        }
        bt.addTarget(
            self,
            action: #selector(self.onOpenDomainCaptcha(sender:)),
            for: .touchUpInside
        )

        bt.translatesAutoresizingMaskIntoConstraints = false
        return bt
    }()

    private lazy var combinedCaptchaButton: UIButton = {
        let bt = UIButton(type: .system)
        bt.setTitle(
            "Show both captchas",
            for: .normal
        )
        bt.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        if #available(iOS 13.0, *) {
            bt.setTitleColor(.label, for: .normal)
        } else {
            bt.setTitleColor(.black, for: .normal)
        }
        bt.addTarget(
            self,
            action: #selector(self.onOpenCombinedCaptcha(sender:)),
            for: .touchUpInside
        )

        bt.translatesAutoresizingMaskIntoConstraints = false
        return bt
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.defaultCaptchaButton)
        self.view.addSubview(self.domainCaptchaButton)
        self.view.addSubview(self.combinedCaptchaButton)
        NSLayoutConstraint.activate([
            self.defaultCaptchaButton.topAnchor.constraint(
                greaterThanOrEqualTo: self.descriptionLabel.bottomAnchor,
                constant: 32
            ),
            self.defaultCaptchaButton.centerXAnchor.constraint(
                equalTo: self.view.centerXAnchor
            ),
            self.domainCaptchaButton.topAnchor.constraint(
                equalTo: self.defaultCaptchaButton.bottomAnchor, constant: 16
            ),
            self.domainCaptchaButton.centerXAnchor.constraint(
                equalTo: self.view.centerXAnchor
            ),
            self.combinedCaptchaButton.topAnchor.constraint(
                equalTo: self.domainCaptchaButton.bottomAnchor, constant: 16
            ),
            self.combinedCaptchaButton.centerXAnchor.constraint(
                equalTo: self.view.centerXAnchor
            ),
            self.combinedCaptchaButton.bottomAnchor.constraint(
                lessThanOrEqualTo: self.view.safeAreaLayoutGuide.bottomAnchor,
                constant: -48
            ),
        ])
    }

    @objc
    private func onOpenDefaultCaptcha(sender: AnyObject) {
        self.defaultCaptchaButton.isEnabled = false
        self.vkid?.fetchDefaultCaptcha { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                switch result {
                case .success:
                    self.showAlert(message: "Успешное прохождение 'Default Captcha'")
                case .failure(let error):
                    self.showAlert(message: "Ошибка прохождения 'Default' капчи: \(error)")
                }
                self.defaultCaptchaButton.isEnabled = true
            }
        }
    }

    @objc
    private func onOpenDomainCaptcha(sender: AnyObject) {
        self.domainCaptchaButton.isEnabled = false
        self.vkid?.fetchDomainCaptcha { result in
            switch result {
            case .success:
                self.showAlert(message: "Успешное прохождение 'Domain Captcha'")
            case .failure(let error):
                self.showAlert(message: "Ошибка прохождения 'Domain' капчи: \(error)")
            }
            self.domainCaptchaButton.isEnabled = true
        }
    }

    @objc
    private func onOpenCombinedCaptcha(sender: AnyObject) {
        self.combinedCaptchaButton.isEnabled = false
        self.vkid?.fetchCombinedCaptcha { result in
            switch result {
            case .success:
                self.showAlert(message: "Успешное прохождение 'Combined Captcha'")
            case .failure(let error):
                self.showAlert(message: "Ошибка прохождения 'Combined' капчи: \(error)")
            }
            self.combinedCaptchaButton.isEnabled = true
        }
    }
}
