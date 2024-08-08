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

/// Конфигурация OneTapButton
public struct OneTapButton: UIViewElement {
    public typealias Factory = VKID

    /// Определяет замыкание, вызывающееся при нажатии на кнопку
    public typealias OnTapCallback = (ActivityIndicating) -> Void

    /// Внешний вид кнопки.
    internal let appearance: Appearance

    /// Оформление кнопки.
    internal let layout: Layout

    /// Объект, отвечающий за отображение экранов авторизации.
    internal let presenter: UIKitPresenter?

    /// Замыкание, вызывающееся при нажатии на кнопку.
    internal let onTap: OnTapCallback?

    /// Замыкание, вызывающееся при завершении авторизации.
    internal let onCompleteAuth: AuthResultCompletion?

    /// Конфигурация авторизации
    internal let authConfig: AuthConfiguration

    /// Конфигурация OAuth провайдеров, используемых в кнопке
    internal let oAuthProviderConfig: OAuthProviderConfiguration

    /// Экран на котором находится кнопка
    internal let screen: AuthContext.Screen

    /// Инициализация конфигурации с ручной обработкой нажатия на кнопку.
    /// - Parameters:
    ///   - appearance: Определяет основные визуальные свойства кнопки.
    ///   - layout: Оформление кнопки.
    ///   - onTap: Замыкание, вызывающееся при нажатии на кнопку.
    public init(
        appearance: Appearance = Appearance(),
        layout: Layout = .regular(),
        onTap: OnTapCallback?
    ) {
        self.init(
            authConfiguration: AuthConfiguration(),
            oAuthProviderConfiguration: OAuthProviderConfiguration(),
            appearance: appearance,
            layout: layout,
            presenter: nil,
            onTap: onTap,
            onCompleteAuth: nil
        )
    }

    /// Инициализация конфигурации с запуском авторизации при нажатии на кнопку.
    /// - Parameters:
    ///   - appearance: Определяет основные визуальные свойства кнопки.
    ///   - layout: Оформление кнопки.
    ///   - presenter: Объект, отвечающий за отображение экранов авторизации.
    ///   - authConfiguration: Конфигурация авторизации.
    ///   - onCompleteAuth: Колбэк о завершении авторизации.
    public init(
        appearance: Appearance = Appearance(),
        layout: Layout = .regular(),
        presenter: UIKitPresenter = .newUIWindow,
        authConfiguration: AuthConfiguration = AuthConfiguration(),
        onCompleteAuth: AuthResultCompletion?
    ) {
        self.init(
            authConfiguration: authConfiguration,
            oAuthProviderConfiguration: OAuthProviderConfiguration(),
            appearance: appearance,
            layout: layout,
            presenter: presenter,
            onTap: nil,
            onCompleteAuth: onCompleteAuth
        )
    }

    /// Создает конфигурацию OneTap кнопки с виджетом для дополнительных oauth-провайдеров.
    /// В данной конфигурации кастомизация OneTap ограничена: можно задать только высоту, радиус закругления углов и цветовую тему.
    /// Данные параметры будут применены как для основной OneTap кнопки так и для кнопок альтернативных OAuth-провайдеров.
    /// - Parameters:
    ///   - height: Детерменированная высота кнопок.
    ///   - cornerRadius: Радиус закругления углов кнопок.
    ///   - theme: Цветовая тема кнопок.
    ///   - authConfiguration: Конфигурация авторизации.
    ///   - oAuthProviderConfiguration: Конфигурация OAuth провайдеров, используемых в кнопке.
    ///   - presenter: Объект, отвечающий за отображение экранов авторизации.
    ///   - onCompleteAuth: Колбэк о завершении авторизации.
    public init(
        height: Layout.Height = .medium(),
        cornerRadius: CGFloat = LayoutConstants.defaultCornerRadius,
        theme: Appearance.Theme = .matchingColorScheme(.current),
        authConfiguration: AuthConfiguration = AuthConfiguration(),
        oAuthProviderConfiguration: OAuthProviderConfiguration,
        presenter: UIKitPresenter = .newUIWindow,
        onCompleteAuth: AuthResultCompletion?
    ) {
        self.init(
            authConfiguration: authConfiguration,
            oAuthProviderConfiguration: oAuthProviderConfiguration,
            appearance: .init(
                style: .primary(),
                theme: theme
            ),
            layout: .regular(
                height: height,
                cornerRadius: cornerRadius
            ),
            presenter: presenter,
            onTap: nil,
            onCompleteAuth: onCompleteAuth
        )
    }

    internal init(
        authConfiguration: AuthConfiguration,
        oAuthProviderConfiguration: OAuthProviderConfiguration,
        screen: AuthContext.Screen = .nowhere,
        appearance: Appearance = Appearance(),
        layout: Layout = .regular(),
        presenter: UIKitPresenter?,
        onTap: OnTapCallback?,
        onCompleteAuth: AuthResultCompletion?
    ) {
        self.authConfig = authConfiguration
        self.oAuthProviderConfig = oAuthProviderConfiguration
        self.appearance = appearance
        self.layout = layout
        self.presenter = presenter
        self.onTap = onTap
        self.onCompleteAuth = onCompleteAuth
        self.screen = screen
    }

    public func _uiView(factory: Factory) -> UIView {
        let control = self.makeOneTapControl(using: factory)
        if self.oAuthProviderConfig.alternativeProviders.isEmpty {
            return control
        }

        let oAuthListWidget = self.makeOAuthListWidgetView(using: factory)
        return OneTapButtonWithOAuthListWidgetView(
            configuration: .init(
                title: "vkconnect_auth_via_providers_legal".localized,
                titleColor: DynamicColor(
                    light: .textSecondaryLight,
                    dark: .textSecondaryDark
                ),
                titleFont: .systemFont(ofSize: 16),
                oneTapButton: control,
                oAuthListWidget: oAuthListWidget
            )
        )
    }

    private func makeOneTapControl(using factory: Factory) -> UIView {
        let control = OneTapControl(
            configuration: .init(
                appearance: self.appearance,
                layout: self.layout
            )
        )

        control.didMoveToSuperView = {
            self.sendShowAnalytics(using: factory)
        }

        if let onTap = self.onTap {
            control.onTap = onTap
        } else if let presenter = self.presenter {
            control.onTap = { control in
                guard !factory.isAuthorizing else {
                    return
                }

                control.startAnimating()

                factory.authorize(
                    authContext: AuthContext(
                        screen: self.screen,
                        launchedBy: .oneTapButton(
                            provider: self.oAuthProviderConfig.primaryProvider,
                            kind: self.layout.kind
                        )
                    ),
                    authConfig: self.authConfig,
                    oAuthProviderConfig: self.oAuthProviderConfig,
                    presenter: presenter
                ) { result in
                    self.onCompleteAuth?(result)

                    control.stopAnimating()
                }
            }
        }

        return control
    }

    private func makeOAuthListWidgetView(using factory: Factory) -> UIView {
        factory.ui(
            for: OAuthListWidget(
                oAuthProviders: self.oAuthProviderConfig.alternativeProviders,
                authConfiguration: self.authConfig,
                buttonConfiguration: .init(
                    height: self.layout.height,
                    cornerRadius: self.layout.cornerRadius
                ),
                screen: self.screen,
                theme: .matchingColorScheme(self.appearance.theme.colorScheme),
                presenter: self.presenter ?? .newUIWindow,
                onCompleteAuth: self.onCompleteAuth
            )
        )
        .uiView()
    }

    private func sendShowAnalytics(using factory: Factory) {
        let analyticsContext: (inout AnalyticsEventContext) -> AnalyticsEventContext = { ctx in
            ctx.screen = Screen(screen: self.screen)
            return ctx
        }

        switch self.oAuthProviderConfig.primaryProvider.type {
        case .vkid:
            switch self.screen {
            case .multibrandingWidget:
                factory.rootContainer.productAnalytics.vkButtonShow
                    .context(analyticsContext)
                    .send(
                        .init(
                            buttonType: .init(kind: self.layout.kind)
                        )
                    )
            case .nowhere, .oneTapBottomSheet:
                if self.screen == .nowhere {
                    factory.rootContainer.productAnalytics.screenProceed
                        .context(analyticsContext)
                        .send(
                            .init(
                                themeType: self.appearance.theme.colorScheme,
                                styleType: self.appearance.style.rawStyle,
                                textType: self.appearance.title.rawType.rawValue
                            )
                        )
                }
                factory.rootContainer.productAnalytics.oneTapButtonNoUserShow
                    .context(analyticsContext)
                    .send(
                        .init(
                            buttonType: .init(kind: self.layout.kind)
                        )
                    )
            }
        case .ok:
            factory.rootContainer.productAnalytics.okButtonShow
                .context(analyticsContext)
                .send(
                    .init(
                        buttonType: .init(kind: self.layout.kind)
                    )
                )
        case .mail:
            factory.rootContainer.productAnalytics.mailButtonShow
                .context(analyticsContext)
                .send(
                    .init(
                        buttonType: .init(kind: self.layout.kind)
                    )
                )
        }
    }
}

extension OneTapButton {
    /// Определяет основные визуальные свойства кнопки
    public struct Appearance {
        internal let title: Title
        internal let style: Style
        internal let theme: Theme

        public init(
            title: Title,
            style: Style,
            theme: Theme
        ) {
            self.title = title
            self.style = style
            self.theme = theme
        }

        public init(
            style: Style,
            theme: Theme
        ) {
            self.init(
                title: .vkid,
                style: style,
                theme: theme
            )
        }

        public init(
            style: Style = .primary()
        ) {
            self.init(
                title: .vkid,
                style: style,
                theme: .matchingColorScheme(.current)
            )
        }
    }
}

extension OneTapButton.Appearance {
    /// Текст внутри кнопки
    public struct Title {
        internal enum RawType: String, RawRepresentable {
            case signUp
            case get
            case open
            case calculate
            case order
            case makeOrder
            case submitRequest
            case participate
            case vkid
            case ok
            case mail
            case custom
        }

        /// Основной текст.
        /// Используется если достаточно ширины кнопки.
        public let primary: String

        /// Краткий текст.
        /// Используется если недостаточно ширины для отображения основного текста
        public let brief: String

        internal let rawType: RawType

        internal init(primary: String, brief: String, rawType: RawType) {
            self.primary = primary
            self.brief = brief
            self.rawType = rawType
        }

        /// Основной текст: "Записаться с VK ID".
        /// Краткий текст: "Записаться".
        public static let signUp = Self(
            primary: "vkconnect_auth_onetap_btn_sign_up_with_vkid".localized,
            brief: "vkconnect_auth_onetap_btn_sign_up".localized,
            rawType: .signUp
        )

        /// Основной текст: "Получить с VK ID".
        /// Краткий текст: "Получить".
        public static let get = Self(
            primary: "vkconnect_auth_onetap_btn_get_with_vkid".localized,
            brief: "vkconnect_auth_onetap_btn_get".localized,
            rawType: .get
        )

        /// Основной текст: "Открыть с VK ID".
        /// Краткий текст: "Открыть".
        public static let open = Self(
            primary: "vkconnect_auth_onetap_btn_open_with_vkid".localized,
            brief: "vkconnect_auth_onetap_btn_open".localized,
            rawType: .open
        )

        /// Основной текст: "Рассчитать с VK ID".
        /// Краткий текст: "Рассчитать".
        public static let calculate = Self(
            primary: "vkconnect_auth_onetap_btn_calculate_with_vkid".localized,
            brief: "vkconnect_auth_onetap_btn_calculate".localized,
            rawType: .calculate
        )

        /// Основной текст: "Заказать с VK ID".
        /// Краткий текст: "Заказать".
        public static let order = Self(
            primary: "vkconnect_auth_onetap_btn_order_with_vkid".localized,
            brief: "vkconnect_auth_onetap_btn_order".localized,
            rawType: .order
        )

        /// Основной текст: "Оформить заказ с VK ID".
        /// Краткий текст: "Оформить заказ".
        public static let makeOrder = Self(
            primary: "vkconnect_auth_onetap_btn_make_order_with_vkid".localized,
            brief: "vkconnect_auth_onetap_btn_make_order".localized,
            rawType: .makeOrder
        )

        /// Основной текст: "Оставить заявку с VK ID".
        /// Краткий текст: "Оставить заявку".
        public static let submitRequest = Self(
            primary: "vkconnect_auth_onetap_btn_submit_request_with_vkid".localized,
            brief: "vkconnect_auth_onetap_btn_submit_request".localized,
            rawType: .submitRequest
        )

        /// Основной текст: "Участвовать с VK ID".
        /// Краткий текст: "Участвовать".
        public static let participate = Self(
            primary: "vkconnect_auth_onetap_btn_participate_with_vkid".localized,
            brief: "vkconnect_auth_onetap_btn_participate".localized,
            rawType: .participate
        )

        /// Основной текст: "Войти с VK ID".
        /// Краткий текст: "VK ID".
        public static let vkid = Self(
            primary: "vkconnect_auth_onetap_login_via_vkid".localized,
            brief: "vkconnect_auth_onetap_vkid".localized,
            rawType: .vkid
        )

        /// Основной текст: "Войти через ОК".
        /// Краткий текст: "Войти через ОК".
        internal static let ok = Self(
            primary: "vkconnect_oauth_ok_button_primary_title".localized,
            brief: "vkconnect_oauth_ok_button_primary_title".localized,
            rawType: .ok
        )

        /// Основной текст: "Войти с Почтой Mail.ru".
        /// Краткий текст: "Войти с Почтой Mail.ru".
        internal static let mail = Self(
            primary: "vkconnect_oauth_mail_button_primary_title".localized,
            brief: "vkconnect_oauth_mail_button_primary_title".localized,
            rawType: .mail
        )
    }
}

extension OneTapButton.Appearance {
    /// Стиль кнопки
    public struct Style: Equatable {
        /// Основной
        public static func primary(logo: LogoImage = .vkidPrimary) -> Self {
            self.init(rawStyle: .primary, logo: logo)
        }

        /// Дополнительный
        public static func secondary(logo: LogoImage = .vkidSecondary) -> Self {
            self.init(rawStyle: .secondary, logo: logo)
        }

        internal enum _Style: String, RawRepresentable, Equatable {
            case primary
            case secondary
        }

        internal let rawStyle: _Style
        internal let logo: LogoImage
    }
}

extension OneTapButton.Appearance {
    /// Логотип сервиса
    public struct LogoImage: Equatable {
        internal let image: UIImage

        internal init(image: UIImage) {
            self.image = image
        }

        public static let vkidPrimary = Self(
            image: .logoPrimary
        )

        public static let vkidSecondary = Self(
            image: .logoSecondary
        )

        internal static let okRuSecondary = Self(
            image: .okRuLogoSecondary
        )

        internal static let mailRuSecondary = Self(
            image: .mailRuLogoSecondary
        )
    }
}

extension OneTapButton.Appearance {
    /// Цветовая тема кнопки
    public struct Theme {
        internal struct Colors {
            internal let primary: any Color
            internal let secondary: any Color

            internal init(primary: some Color, secondary: some Color) {
                self.primary = primary
                self.secondary = secondary
            }
        }

        internal let colors: Colors
        internal let colorScheme: Appearance.ColorScheme

        fileprivate init(
            colors: Colors,
            colorScheme: Appearance.ColorScheme
        ) {
            self.colors = colors
            self.colorScheme = colorScheme
        }

        public static func matchingColorScheme(_ scheme: Appearance.ColorScheme) -> Self {
            switch scheme {
            case .system:
                let light = self.matchingColorScheme(.light)
                let dark = self.matchingColorScheme(.dark)
                return .init(
                    colors: .init(
                        primary: DynamicColor(
                            light: light.colors.primary.value,
                            dark: dark.colors.primary.value
                        ),
                        secondary: DynamicColor(
                            light: light.colors.secondary.value,
                            dark: dark.colors.secondary.value
                        )
                    ),
                    colorScheme: scheme
                )
            case .light:
                return .init(
                    colors: .init(
                        primary: UIColor.azure,
                        secondary: UIColor.backgroundDark
                    ),
                    colorScheme: scheme
                )
            case .dark:
                return .init(
                    colors: .init(
                        primary: UIColor.azure,
                        secondary: UIColor.backgroundLight
                    ),
                    colorScheme: scheme
                )
            }
        }
    }
}

extension OneTapButton {
    /// Лейаут кнопки
    public struct Layout {
        public let kind: Kind
        public let height: Height
        public let cornerRadius: CGFloat

        /// Инициализация конфигурации лейаута для OneTap кнопки
        /// - Parameters:
        ///   - kind: тип лейаута
        ///   - height: высота кнопки
        ///   - cornerRadius: радиус углов кнопки
        public init(
            kind: Kind,
            height: Height = .medium(),
            cornerRadius: CGFloat
        ) {
            self.kind = kind
            self.height = height
            self.cornerRadius = cornerRadius
        }

        /// Создает лейаут обычной кнопки c лого VK ID и текстом
        public static func regular(
            height: Height = .medium(),
            cornerRadius: CGFloat = LayoutConstants.defaultCornerRadius
        ) -> Self {
            self.init(
                kind: .regular,
                height: height,
                cornerRadius: cornerRadius
            )
        }

        /// Создает лейаут квадратной кнопки с лого VK ID
        public static func logoOnly(
            size: Height = .medium(),
            cornerRadius: CGFloat = LayoutConstants.defaultCornerRadius
        ) -> Self {
            self.init(
                kind: .logoOnly,
                height: size,
                cornerRadius: cornerRadius
            )
        }

        /// Тип лейаута кнопки
        public enum Kind {
            /// Обычная кнопка c лого VK ID и текстом
            case regular

            /// Квадратная кнопка иконка, отображается только лого VK ID
            case logoOnly
        }

        /// Кнопка может иметь строго детерминированную высоту с шагом 2
        /// Все значения разбиты на 3 класса: ``Small``, ``Medium`` и ``Large``
        /// В каждом классе есть свои значения высоты по умолчанию
        public enum Height: Equatable {
            case small(Small = .h36)
            case medium(Medium = .h44)
            case large(Large = .h52)

            public enum Small: CGFloat, CaseIterable {
                case h32 = 32
                case h34 = 34
                case h36 = 36
                case h38 = 38
            }

            public enum Medium: CGFloat, CaseIterable {
                case h40 = 40
                case h42 = 42
                case h44 = 44
                case h46 = 46
            }

            public enum Large: CGFloat, CaseIterable {
                case h48 = 48
                case h50 = 50
                case h52 = 52
                case h54 = 54
                case h56 = 56
            }

            public var rawValue: CGFloat {
                switch self {
                case .small(let value):
                    return value.rawValue
                case .medium(let value):
                    return value.rawValue
                case .large(let value):
                    return value.rawValue
                }
            }
        }
    }
}

/// OAuth providers support
extension OneTapButton.Appearance {
    internal static func appearance(
        for provider: OAuthProvider,
        colorScheme: Appearance.ColorScheme
    ) -> OneTapButton.Appearance {
        let theme = OneTapButton.Appearance.Theme.matchingColorScheme(colorScheme)
        switch provider.type {
        case .vkid:
            return .init(
                title: .vkid,
                style: .secondary(logo: .vkidSecondary),
                theme: theme
            )
        case .ok:
            return .init(
                title: .ok,
                style: .secondary(logo: .okRuSecondary),
                theme: theme
            )
        case .mail:
            return .init(
                title: .mail,
                style: .secondary(logo: .mailRuSecondary),
                theme: theme
            )
        }
    }
}
