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

package struct EventProductMain: Encodable, AnalyticsEvent {
    /// Идентификатор события
    let id: Int
    /// Дата создания события (в микросекундах)
    let timestamp: String
    /// Предыдущий идентификатор события
    let prevEventId: Int = .zero
    /// Предыдущий идентификатор навигационного события
    let prevNavId: Int = .zero
    /// Имя исходного экрана (иногда называют `screen_current`)
    let screen: Screen

    /// Тип транзитивного события
    let type: TransitiveEventType = .typeAction
    /// Транзитивное action событие
    let typeAction: TypeAction

    package init(id: Int, timestamp: String, screen: Screen, typeAction: TypeAction) {
        self.id = id
        self.timestamp = timestamp
        self.screen = screen
        self.typeAction = typeAction
    }

    package init(screen: Screen, typeAction: TypeAction) {
        self.init(
            id: Int.random32,
            timestamp: AbsoluteTime.currentMicrosecondsAsString,
            screen: screen,
            typeAction: typeAction
        )
    }

    /// Тип транзитивного события
    package enum TransitiveEventType: String, Encodable {
        case typeAction = "type_action"
    }
}

/// Имя исходного экрана
package struct Screen: StringRawRepresentable, Encodable {
    package static let nowhere: Self = "nowhere"

    package var rawValue: String

    package init(rawValue: String) {
        self.rawValue = rawValue
    }
}
