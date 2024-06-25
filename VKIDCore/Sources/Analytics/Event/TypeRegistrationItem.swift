//
// Copyright (c) 2024 - present, LLC “V Kontakte”
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

/// Событие регистрации, записывается в таблицу Registrations
package struct TypeRegistrationItem: Encodable {
    // MARK: - Основные поля
    /// Тип события в процессе регистрации
    package let eventType: EventType
    /// Ошибка авторизации/регистрации
    package let error: Error?
    /// Поля события регистрации
    package var fields: [FieldItem]

    // MARK: - Дополнительные поля
    /// Источник/Инициатор флоу
    package var flowSource: String?

    /// Инициализация элемента события аналитики.
    /// - Parameters:
    ///   - eventType: тип события.
    ///   - error: ошибка авторизации/регистрации.
    ///   - fields: поля события аналитики.
    package init(eventType: EventType, error: Error? = nil, fields: [FieldItem]) {
        self.eventType = eventType
        self.error = error
        self.fields = fields
    }

    /// Типы событий регистрации
    package struct EventType: StringRawRepresentable, Encodable {
        package var rawValue: String

        package init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// Ошибки авторизации/регистрации
    package struct Error: StringRawRepresentable, Encodable {
        package var rawValue: String

        package init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// Поле событий регистрации..
    package struct FieldItem: Encodable {
        /// Имя поля
        let name: Name
        /// Значение поля
        let value: String?

        package init(name: Name, value: String?) {
            self.name = name
            self.value = value
        }

        /// Поля событий регистрации
        package struct Name: StringRawRepresentable, Encodable {
            package var rawValue: String

            package init(rawValue: String) {
                self.rawValue = rawValue
            }
        }
    }
}
