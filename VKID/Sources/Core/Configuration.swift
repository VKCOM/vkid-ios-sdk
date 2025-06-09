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

/// Конфигурация VK ID SDK
public struct Configuration {
    /// Учетные данные для VK ID приложения
    public let appCredentials: AppCredentials
    /// Включение/выключение логов
    public let loggingEnabled: Bool
    /// Конфигурация внешнего вида визуальных элементов VK ID
    public var appearance: Appearance
    /// Приложение использует функции SDK через адаптер. Только для внутреннего использования.
    @_spi(VKIDPrivate)
    public let wrapperSDK: WrapperSDK
    /// Ограничение показов шторки подписки на сообщество
    public let groupSubscriptionsLimit: GroupSubscriptionsLimit?

    // Only for debug purposes
    @_spi(VKIDDebug)
    public var network: NetworkConfiguration

    public init(
        appCredentials: AppCredentials,
        appearance: Appearance = Appearance(),
        loggingEnabled: Bool = true,
        groupSubscriptionsLimit: GroupSubscriptionsLimit? = .init()
    ) {
        self.init(
            appCredentials: appCredentials,
            appearance: appearance,
            network: .init(isSSLPinningEnabled: true),
            groupSubscriptionsLimit: groupSubscriptionsLimit
        )
    }

    // Only for internal using
    @_spi(VKIDPrivate)
    // Only for debug purposes
    @_spi(VKIDDebug)
    public init(
        appCredentials: AppCredentials,
        appearance: Appearance = Appearance(),
        loggingEnabled: Bool = true,
        wrapperSDK: WrapperSDK = .none,
        network: NetworkConfiguration,
        groupSubscriptionsLimit: GroupSubscriptionsLimit? = nil
    ) {
        self.appCredentials = appCredentials
        self.appearance = appearance
        self.network = network
        self.loggingEnabled = loggingEnabled
        self.wrapperSDK = wrapperSDK
        self.groupSubscriptionsLimit = groupSubscriptionsLimit
    }
}

/// Адаптеры SDK. Только для внутреннего использования.
@_spi(VKIDPrivate)
public enum WrapperSDK: String {
    case none
    case flutter
}

/// Учетные данные для VK ID приложения
public struct AppCredentials {
    public let clientId: String
    public let clientSecret: String

    public init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
}

/// Конфигурация внешнего вида визуальных элементов VK ID. Контролы всегда локализуются по языку приложения/системы.
public struct Appearance {
    /// Цветовая схема интерфейса
    public enum ColorScheme: String, CaseIterable {
        case system
        case light
        case dark

        func resolveSystemToActualScheme() -> Self {
            UIScreen.main.traitCollection.userInterfaceStyle == .light ?
                .light :
                .dark
        }
    }

    /// Локализация интерфейса
    public enum Locale: String, CaseIterable {
        /// Будет использована системная локаль
        case system
        /// Russian
        case ru
        /// Ukrainian
        case uk
        /// English
        case en
        /// Spanish
        case es
        /// German
        case de
        /// Polish
        case pl
        /// French
        case fr
        /// Turkish
        case tr
    }

    public var colorScheme: ColorScheme
    public var locale: Locale

    /// Инициализация конфигурации внешнего вида визуальных элементов VKID
    /// - Parameters:
    ///   - colorScheme: Цветовая схема интерфейса
    ///   - locale: Локализация, которая будет применена на странице авторизации в вебвью. Контролы всегда локализуются по языку приложения/системы.
    public init(
        colorScheme: ColorScheme = .system,
        locale: Locale = .system
    ) {
        self.colorScheme = colorScheme
        self.locale = locale
    }
}

/// Настройка показов шторки подписки на сообщество
public struct GroupSubscriptionsLimit {
    /// Максимальное количество показов шторки за период времени
    public let maxSubscriptionsToShow: UInt
    /// Цикличный период с ограничением показов
    public let periodInDays: UInt

    public init(maxSubsctiptionsToShow: UInt = 2, periodInDays: UInt = 30) {
        self.maxSubscriptionsToShow = maxSubsctiptionsToShow
        self.periodInDays = periodInDays
    }
}

extension Appearance.ColorScheme {
    /// Цветовая схема, указанная при инициализации VK ID SDK
    public internal(set) static var current: Appearance.ColorScheme = .system
}

extension Appearance.Locale {
    public internal(set) static var current: Appearance.Locale = .system

    public var languageCode: String? {
        guard self != .system else {
            return nil
        }
        return self.rawValue
    }
}
