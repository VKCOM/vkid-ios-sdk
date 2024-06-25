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

/// Транзитивное action событие
package struct TypeAction: Encodable {
    /// Тип конечного события
    let type: ActionType
    /// Конечное событие
    let typeItem: CustomKeyValueEncodable<ActionType>

    package init(type: ActionType, value: Encodable) {
        self.type = type
        self.typeItem = .init(
            key: type,
            value: value
        )
    }

    package func encode(to encoder: any Encoder) throws {
        var typeItemContainer = encoder.singleValueContainer()
        try typeItemContainer.encode(self.typeItem)

        var typeContainer = encoder.container(keyedBy: CodingKeys.self)
        try typeContainer.encode(self.type, forKey: .type)
    }

    package enum CodingKeys: String, CodingKey {
        case type
    }

    package struct ActionType: StringRawRepresentableCodingKeys, Encodable {
        static let typeRegistrationItem: Self = "type_registration_item"
        static let typeDebugStatsItem: Self = "type_debug_stats_item"
        static let typeSAKSessionsEventItem: Self = "type_sak_sessions_event_item"

        package var rawValue: String

        package init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

/// Инициализация typeAction с определенным конечным событием
extension TypeAction {
    package init(typeRegistrationItem: TypeRegistrationItem) {
        self.init(type: .typeRegistrationItem, value: typeRegistrationItem)
    }

    package init(typeSAKSessionsEventItem: TypeSAKSessionsEventItem) {
        self.init(type: .typeSAKSessionsEventItem, value: typeSAKSessionsEventItem)
    }

    package init(typeDebugStatsItem: TypeDebugStatsItem) {
        self.init(type: .typeDebugStatsItem, value: typeDebugStatsItem)
    }
}
