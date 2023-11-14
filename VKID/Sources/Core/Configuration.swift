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

/// Конфигурация VK ID SDK
public struct Configuration {
    public let appCredentials: AppCredentials
    public var appearance: Appearance

    public init(
        appCredentials: AppCredentials,
        appearance: Appearance = Appearance()
    ) {
        self.appCredentials = appCredentials
        self.appearance = appearance
    }
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

/// Конфигурация внешнего вида визуальных элементов VK ID
public struct Appearance {
    /// Цветовая схема интерфейса
    public enum ColorScheme: CaseIterable {
        case system
        case light
        case dark
    }

    /// Локализация интерфейса
    public enum Locale: CaseIterable {
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

    public init(
        colorScheme: ColorScheme = .system,
        locale: Locale = .system
    ) {
        self.colorScheme = colorScheme
        self.locale = locale
    }
}
