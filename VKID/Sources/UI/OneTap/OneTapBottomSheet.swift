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

import Foundation
import UIKit
@_implementationOnly import VKIDCore

/// Конфигурация для модальной шторки авторизации
public struct OneTapBottomSheet: UIViewControllerElement {
    public typealias Factory = VKID

    /// Название сервиса в заголовке шторки.
    internal let serviceName: String

    /// Текстовки для целевого действия в шторке.
    internal let targetActionText: TargetActionText

    /// Конфигурация для OneTap.
    internal let oneTapButton: AuthButton

    /// Список альтернативных OAuth-провайдеров, которые будут отображаться
    /// в виджете под основной кнопкой.
    internal let alternativeOAuthProviders: [OAuthProvider]

    /// Цветовая тема шторки.
    internal let theme: Theme

    /// Нужно ли скрывать шторку автоматически в случае успешной авторизации
    internal let autoDismissOnSuccess: Bool

    /// Коллбэк о завершении авторизации.
    internal let onCompleteAuth: AuthResultCompletion?

    /// Инициализация конфигурации модальной шторки авторизации с кнопкой, виджетом и темой.
    /// - Parameters:
    ///   - serviceName: Название сервиса в заголовке шторки.
    ///   - targetActionText: Текстовки для целевого действия в шторке.
    ///   - oneTapButton: Конфигурация для OneTap.
    ///   - alternativeOAuthProviders: Список альтернативных OAuth-провайдеров, которые будут отображаться
    ///   в виджете под основной кнопкой.
    ///   - theme: Цветовая тема шторки.
    ///   - autoDismissOnSuccess:
    ///   Нужно ли скрывать шторку автоматически в случае успешной авторизации.
    ///   По умолчанию значение равно `true`.
    ///   - onCompleteAuth: Коллбэк о завершении авторизации.
    public init(
        serviceName: String,
        targetActionText: TargetActionText,
        oneTapButton: AuthButton,
        alternativeOAuthProviders: [OAuthProvider] = [],
        theme: Theme = .matchingColorScheme(.current),
        autoDismissOnSuccess: Bool = true,
        onCompleteAuth: AuthResultCompletion?
    ) {
        self.serviceName = serviceName
        self.targetActionText = targetActionText
        self.oneTapButton = oneTapButton
        self.alternativeOAuthProviders = alternativeOAuthProviders.filter {
            $0.type != .vkid
        }
        self.theme = theme
        self.autoDismissOnSuccess = autoDismissOnSuccess
        self.onCompleteAuth = onCompleteAuth
    }

    public func _uiViewController(factory: VKID) -> UIViewController {
        let oneTap = factory.ui(
            for: OneTapButton(
                primaryOAuthProvider: .vkid,
                alternativeOAuthProviders: self.alternativeOAuthProviders,
                appearance: .init(
                    title: .init(
                        primary: self.targetActionText.oneTapButtonTitle,
                        brief: self.targetActionText.oneTapButtonTitle
                    ),
                    style: .primary(),
                    theme: .matchingColorScheme(self.theme.colorScheme)
                ),
                layout: .regular(
                    height: self.oneTapButton.height,
                    cornerRadius: self.oneTapButton.cornerRadius
                ),
                presenter: .newUIWindow,
                onTap: nil,
                onCompleteAuth: nil
            )
        )
        .uiView()
        let contentController = OneTapBottomSheetContentViewController(
            vkid: factory,
            theme: self.theme,
            oneTapButton: oneTap,
            serviceName: self.serviceName,
            targetActionText: self.targetActionText,
            autoDismissOnSuccess: self.autoDismissOnSuccess,
            onCompleteAuth: self.onCompleteAuth
        )

        let sheet = BottomSheetViewController(
            contentViewController: contentController,
            layoutConfiguration: .init(
                cornerRadius: 14,
                edgeInsets: .init(
                    top: 0,
                    left: 8,
                    bottom: 8,
                    right: 8
                )
            )
        )

        return sheet
    }
}

extension OneTapBottomSheet {
    /// Текстовки для целевого действия в шторке
    public struct TargetActionText {
        /// Заголовок для целевого действия в шторке, максимально 3 строки. Например, "Войдите в сервис или зарегистрируйтесь"
        public let title: String

        /// Детальное описание целевого действия, максимально 3 - 4 строки. Например, "После этого вам станут доступны все возможности сервиса. Ваши данные будут надёжно защищены."
        public let subtitle: String

        internal let oneTapButtonTitle: String

        /// Войти
        public static var signIn: TargetActionText {
            TargetActionText(
                title: "vkconnect_auth_floatingonetap_header_sign_in_to_service".localized,
                subtitle: "vkconnect_auth_floatingonetap_description".localized,
                oneTapButtonTitle: "vkconnect_auth_floatingonetap_btn_unauth_sign_in_to_service".localized
            )
        }

        /// Войти в учетную запись указанного сервиса
        public static func signInToService(_ serviceName: String) -> TargetActionText {
            TargetActionText(
                title: "vkconnect_auth_floatingonetap_header_sign_in_to_account".localizedWithFormat(serviceName),
                subtitle: "vkconnect_auth_floatingonetap_description".localized,
                oneTapButtonTitle: "vkconnect_auth_floatingonetap_btn_unauth_sign_in_to_account".localized
            )
        }

        /// Зарегистрироваться на событие
        public static var registerForEvent: TargetActionText {
            TargetActionText(
                title: "vkconnect_auth_floatingonetap_header_registration_for_event".localized,
                subtitle: "vkconnect_auth_floatingonetap_description".localized,
                oneTapButtonTitle: "vkconnect_auth_floatingonetap_btn_unauth_registration_for_event".localized
            )
        }

        /// Подать заявку
        public static var applyFor: TargetActionText {
            TargetActionText(
                title: "vkconnect_auth_floatingonetap_header_submit_applications".localized,
                subtitle: "vkconnect_auth_floatingonetap_description".localized,
                oneTapButtonTitle: "vkconnect_auth_floatingonetap_btn_unauth_submit_applications".localized
            )
        }

        /// Оформить заказ
        public static var orderCheckout: TargetActionText {
            TargetActionText(
                title: "vkconnect_auth_floatingonetap_header_make_order_without_service".localized,
                subtitle: "vkconnect_auth_floatingonetap_description".localized,
                oneTapButtonTitle: "vkconnect_auth_floatingonetap_btn_unauth_make_order_without_service".localized
            )
        }

        /// Оформить заказ в указанном сервисе
        public static func orderCheckoutAtService(_ serviceName: String) -> TargetActionText {
            TargetActionText(
                title: "vkconnect_auth_floatingonetap_header_make_order_with_service".localizedWithFormat(serviceName),
                subtitle: "vkconnect_auth_floatingonetap_description".localized,
                oneTapButtonTitle: "vkconnect_auth_floatingonetap_btn_unauth_make_order_with_service".localized
            )
        }

        fileprivate init(
            title: String,
            subtitle: String,
            oneTapButtonTitle: String
        ) {
            self.title = title
            self.subtitle = subtitle
            self.oneTapButtonTitle = oneTapButtonTitle
        }
    }
}

extension OneTapBottomSheet {
    /// Конфигурация кнопки авторизации в шторке
    public struct AuthButton {
        /// Детерминированная высота кнопки
        public let height: OneTapButton.Layout.Height

        /// Радиус скругления контуров кнопки
        public let cornerRadius: CGFloat

        public init(
            height: OneTapButton.Layout.Height = .medium(),
            cornerRadius: CGFloat = 8.0
        ) {
            self.height = height
            self.cornerRadius = cornerRadius
        }
    }
}

extension OneTapBottomSheet {
    /// Тема, определяющая внешний вид шторки
    public struct Theme {
        internal struct Colors {
            internal var background: any Color
            internal var title: any Color
            internal var subtitle: any Color
            internal var topBarTitle: any Color
            internal var topBarLogo: any Color
            internal var retryButtonBackground: any Color
            internal var retryButtonTitle: any Color
        }

        internal struct Images {
            internal var topBarLogo: any Image
            internal var topBarCloseButton: any Image
        }

        internal var colors: Colors
        internal var images: Images
        internal var colorScheme: Appearance.ColorScheme

        /// Создает тему, соответствующую указанной цветовой схеме
        /// - Parameter scheme: цветовая схема
        /// - Returns: тема для шторки авторизации
        public static func matchingColorScheme(_ scheme: Appearance.ColorScheme) -> Self {
            switch scheme {
            case .system:
                let light = self.matchingColorScheme(.light)
                let dark = self.matchingColorScheme(.dark)
                return .init(
                    colors: .init(
                        background: DynamicColor(
                            light: light.colors.background.value,
                            dark: dark.colors.background.value
                        ),
                        title: DynamicColor(
                            light: light.colors.title.value,
                            dark: dark.colors.title.value
                        ),
                        subtitle: DynamicColor(
                            light: light.colors.subtitle.value,
                            dark: dark.colors.subtitle.value
                        ),
                        topBarTitle: DynamicColor(
                            light: light.colors.topBarTitle.value,
                            dark: dark.colors.topBarTitle.value
                        ),
                        topBarLogo: DynamicColor(
                            light: light.colors.topBarLogo.value,
                            dark: dark.colors.topBarLogo.value
                        ),
                        retryButtonBackground: DynamicColor(
                            light: light.colors.retryButtonBackground.value,
                            dark: dark.colors.retryButtonBackground.value
                        ),
                        retryButtonTitle: DynamicColor(
                            light: light.colors.retryButtonTitle.value,
                            dark: dark.colors.retryButtonTitle.value
                        )
                    ),
                    images: .init(
                        topBarLogo: DynamicImage(
                            light: light.images.topBarLogo.value,
                            dark: dark.images.topBarLogo.value
                        ),
                        topBarCloseButton: DynamicImage(
                            light: light.images.topBarCloseButton.value,
                            dark: dark.images.topBarCloseButton.value
                        )
                    ),
                    colorScheme: scheme
                )
            case .light:
                return .init(
                    colors: .init(
                        background: UIColor.backgroundModalLight,
                        title: UIColor.textPrimaryLight,
                        subtitle: UIColor.textSecondaryLight,
                        topBarTitle: UIColor.textSecondaryLight,
                        topBarLogo: UIColor.textPrimaryLight,
                        retryButtonBackground: UIColor.backgroundSecondaryAlphaLight,
                        retryButtonTitle: UIColor.textAccentThemed
                    ),
                    images: .init(
                        topBarLogo: UIImage.logoLight,
                        topBarCloseButton: UIImage.closeLight
                    ),
                    colorScheme: scheme
                )
            case .dark:
                return .init(
                    colors: .init(
                        background: UIColor.backgroundModalDark,
                        title: UIColor.textPrimaryDark,
                        subtitle: UIColor.textSecondaryDark,
                        topBarTitle: UIColor.textSecondaryDark,
                        topBarLogo: UIColor.textPrimaryDark,
                        retryButtonBackground: UIColor.backgroundSecondaryAlphaDark,
                        retryButtonTitle: UIColor.white
                    ),
                    images: .init(
                        topBarLogo: UIImage.logoDark,
                        topBarCloseButton: UIImage.closeDark
                    ),
                    colorScheme: scheme
                )
            }
        }
    }
}
