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

/// Конфигурация OneTapButton
public struct OneTapButton: UIViewElement {
    public typealias Factory = VKID
    public typealias OnTapCallback = (ActivityIndicating) -> Void

    private let appearance: Appearance
    private let layout: Layout
    private let presenter: UIKitPresenter?
    private let onTap: OnTapCallback?
    private let onCompleteAuth: AuthResultCompletion?

    /// Инициализация конфигурации кнопки
    /// - Parameters:
    ///   - appearance: Внешний вид кнопки.
    ///   - layout: Оформление кнопки.
    ///   - presenter: Источник отображения авторизации, при нажатии на кнопку.
    ///   - onCompleteAuth: Замыкание, вызывающееся при завершении авторизации.
    public init(
        appearance: Appearance = Appearance(),
        layout: Layout = .regular(),
        presenter: UIKitPresenter = .newUIWindow,
        onCompleteAuth: AuthResultCompletion? = nil
    ) {
        self.appearance = appearance
        self.layout = layout
        self.presenter = presenter
        self.onCompleteAuth = onCompleteAuth
        self.onTap = nil
    }

    /// Инициализация конфигурации кнопки
    /// - Parameters:
    ///   - appearance: Внешний вид кнопки.
    ///   - layout: Оформление кнопки.
    ///   - onTap: Замыкание, вызывающееся при нажатии на кнопку.
    public init(
        appearance: Appearance = Appearance(),
        layout: Layout = .regular(),
        onTap: OnTapCallback? = nil
    ) {
        self.appearance = appearance
        self.layout = layout
        self.onTap = onTap
        self.presenter = nil
        self.onCompleteAuth = nil
    }

    public func _uiView(factory: Factory) -> UIView {
        let control = OneTapControl(configuration: .init(
            appearance: self.appearance,
            layout: self.layout,
            colorScheme: factory.appearance.colorScheme
        ))

        if let onTap = self.onTap {
            control.onTap = onTap
        } else if let presenter = self.presenter {
            control.onTap = { control in
                guard !control.isAnimating else {
                    return
                }

                control.startAnimating()

                factory.authorize(using: presenter) { result in
                    self.onCompleteAuth?(result)

                    control.stopAnimating()
                }
            }
        }

        return control
    }
}

extension OneTapButton {
    /// Определяет основные визуальные свойства кнопки
    public struct Appearance {
        internal let title: Title
        internal let style: Style
        internal let theme: Theme

        fileprivate init(
            title: Title,
            style: Style,
            theme: Theme
        ) {
            self.title = title
            self.style = style
            self.theme = theme
        }

        public init(
            style: Style = .primary(),
            theme: Theme = .matchesVKIDColorScheme
        ) {
            self.init(
                title: .vkid,
                style: style,
                theme: theme
            )
        }
    }
}

extension OneTapButton.Appearance {
    /// Текст внутри кнопки
    public struct Title {
        /// Основной текст.
        /// Используется если достаточно ширины кнопки.
        internal let primary: String

        /// Краткий текст.
        /// Используется если недостаточно ширины для отображения основного текста
        internal let brief: String

        internal init(primary: String, brief: String) {
            self.primary = primary
            self.brief = brief
        }

        fileprivate static let vkid = Self(
            primary: "vkid_button_primary_title".localized,
            brief: "vkid_button_brief_title".localized
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

        internal enum _Style: Equatable {
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

        fileprivate init(image: UIImage) {
            self.image = image
        }

        public static let vkidPrimary = Self(
            image: .init(
                named: "vk_id_logo_primary",
                in: .module,
                compatibleWith: nil
            )!
        )

        public static let vkidSecondary = Self(
            image: .init(
                named: "vk_id_logo_secondary",
                in: .module,
                compatibleWith: nil
            )!
        )
    }
}

extension OneTapButton.Appearance {
    /// Цветовая тема кнопки
    public struct Theme {
        internal struct Colors {
            internal let primary: Color
            internal let secondary: Color

            internal init(primary: Color, secondary: Color) {
                self.primary = primary
                self.secondary = secondary
            }
        }

        internal enum _Theme {
            case light
            case dark
            case system
            case matchesVKIDColorScheme
        }

        internal let rawTheme: _Theme
        internal let colors: Colors

        fileprivate init(
            rawTheme: _Theme,
            colors: Colors
        ) {
            self.rawTheme = rawTheme
            self.colors = colors
        }

        public static let system = Self(
            rawTheme: .system,
            colors: .init(
                primary: DynamicColor(
                    light: light.colors.primary.value,
                    dark: dark.colors.primary.value
                ),
                secondary: DynamicColor(
                    light: light.colors.secondary.value,
                    dark: dark.colors.secondary.value
                )
            )
        )

        public static let light = Self(
            rawTheme: .light,
            colors: .init(
                primary: UIColor.azure,
                secondary: UIColor.backgroundDark
            )
        )

        public static let dark = Self(
            rawTheme: .dark,
            colors: .init(
                primary: UIColor.azure,
                secondary: UIColor.backgroundLight
            )
        )

        /// Тема будет соответствовать цветовой схеме `ColorScheme`,
        /// указанной в структуре `Appearance` при инициализации инстанса `VKID`
        /// По умолчанию используется `colorScheme = .system`
        public static let matchesVKIDColorScheme = Self(
            rawTheme: .matchesVKIDColorScheme,
            colors: .init(
                primary: stubColor,
                secondary: stubColor
            )
        )
    }
}

extension OneTapButton {
    public struct Layout {
        public let kind: Kind
        public let height: Height
        public let cornerRadius: CGFloat

        public init(
            kind: Kind,
            height: Height = .medium(),
            cornerRadius: CGFloat
        ) {
            self.kind = kind
            self.height = height
            self.cornerRadius = cornerRadius
        }

        public static func regular(
            height: Height = .medium(),
            cornerRadius: CGFloat = 0.0
        ) -> Self {
            self.init(
                kind: .regular,
                height: height,
                cornerRadius: cornerRadius
            )
        }

        public static func logoOnly(
            size: Height = .medium(),
            cornerRadius: CGFloat = 0.0
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

            internal var rawValue: CGFloat {
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
