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

/// Конфигурация виджета списка OAuth-ов
public struct OAuthListWidget: UIViewElement {
    public typealias Factory = VKID

    /// Список oauth-ов, который будет отображен в виджете
    internal var oAuthProviders: [OAuthProvider]

    /// Конфигурация кнопок с oauth-ами
    internal let buttonConfiguration: ButtonConfiguration

    /// Цветовая тема виджета
    internal let theme: Theme

    /// Объект, отвечающий за отображение экранов авторизации
    internal let presenter: UIKitPresenter

    /// Колбэк с результатом авторизации
    internal let onCompleteAuth: AuthResultCompletion?

    /// Инициализация конфигурации виджета
    /// - Parameters:
    ///   - oAuthProviders: Список oauth-ов, который будет отображен в виджете
    ///   - buttonConfiguration: Конфигурация кнопок с oauth-ами
    ///   - theme: Цветовая тема виджета
    ///   - presenter: Объект, отвечающий за отображение экранов авторизации
    ///   - onCompleteAuth: Колбэк с результатом авторизации
    public init(
        oAuthProviders: [OAuthProvider],
        buttonConfiguration: ButtonConfiguration = .init(
            height: .medium(),
            cornerRadius: LayoutConstants.defaultCornerRadius
        ),
        theme: Theme = .matchingColorScheme(.current),
        presenter: UIKitPresenter = .newUIWindow,
        onCompleteAuth: AuthResultCompletion?
    ) {
        self.oAuthProviders = oAuthProviders
        self.buttonConfiguration = buttonConfiguration
        self.theme = theme
        self.presenter = presenter
        self.onCompleteAuth = onCompleteAuth
    }

    public func _uiView(factory: Factory) -> UIView {
        let oAuthButtons = self.oAuthProviders.map { provider in
            self.oAuthButton(
                for: provider,
                using: factory,
                config: self.buttonConfiguration,
                theme: self.theme,
                presenter: self.presenter,
                onCompleteAuth: self.onCompleteAuth
            )
        }
        return OAuthListWidgetView(oAuthButtons: oAuthButtons)
    }

    private func oAuthButton(
        for provider: OAuthProvider,
        using factory: Factory,
        config: ButtonConfiguration,
        theme: Theme,
        presenter: UIKitPresenter,
        onCompleteAuth: AuthResultCompletion?
    ) -> UIView {
        let oneTap = OneTapButton(
            primaryOAuthProvider: provider,
            appearance: .appearance(
                for: provider,
                colorScheme: theme.colorScheme
            ),
            layout: .regular(
                height: config.height,
                cornerRadius: config.cornerRadius
            ),
            presenter: presenter,
            onTap: nil,
            onCompleteAuth: onCompleteAuth
        )
        return factory.ui(for: oneTap).uiView()
    }
}

extension OAuthListWidget {
    /// Тема, определяющая внешний вид OAuth виджета
    public struct Theme {
        internal let colorScheme: Appearance.ColorScheme

        public static func matchingColorScheme(_ scheme: Appearance.ColorScheme) -> Self {
            .init(colorScheme: scheme)
        }
    }
}

extension OAuthListWidget {
    /// Конфигурацция кнопки OAuth виджета
    public struct ButtonConfiguration {
        public let height: OneTapButton.Layout.Height
        public let cornerRadius: CGFloat
        public init(
            height: OneTapButton.Layout.Height,
            cornerRadius: CGFloat
        ) {
            self.height = height
            self.cornerRadius = cornerRadius
        }
    }
}
