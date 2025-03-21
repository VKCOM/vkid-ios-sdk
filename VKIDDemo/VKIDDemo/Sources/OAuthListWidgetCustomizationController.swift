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

final class OAuthListWidgetCustomizationController: VKIDDemoViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let widget = OAuthListWidget(
            oAuthProviders: [.vkid, .ok, .mail],
            authConfiguration: AuthConfiguration(
                flow: self.createFlow(
                    secrets: self.providedAuthSecrets
                ),
                scope: Scope(self.debugSettings.scope),
                forceWebViewFlow: self.debugSettings.forceWebBrowserFlow
            ),
            buttonConfiguration: .init(
                height: .large(.h56),
                cornerRadius: 28
            ),
            theme: .matchingColorScheme(.system),
            presenter: .uiViewController(self)
        ) { result in
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
        if let widgetView = self.vkid?.ui(for: widget).uiView() {
            widgetView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(widgetView)
            NSLayoutConstraint.activate([
                widgetView.topAnchor.constraint(greaterThanOrEqualTo: self.descriptionLabel.bottomAnchor, constant: 32),
                widgetView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
                widgetView.trailingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -16
                ),
                widgetView.bottomAnchor.constraint(
                    lessThanOrEqualTo: self.view.safeAreaLayoutGuide.bottomAnchor,
                    constant: -48
                ),
            ])
        }
    }
}
