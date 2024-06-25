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
import VKIDCore

/// Сервис отправки событий аналитики.
internal final class AnalyticsServiceImpl: AnalyticsService {
    internal struct Dependencies {
        /// Методы для отправки событий.
        let api: VKAPI<StatEvents>
        /// Логгер.
        let logger: Logging
    }

    /// Зависимости сервиса.
    private let deps: Dependencies

    /// Инициализация сервиса отправки событий аналитики.
    /// - Parameter deps: Зависимости.
    init(deps: Dependencies) {
        self.deps = deps
    }

    /// Отправить событие.
    func send(events: [AnalyticsEncodedEvent], context: AnalyticsEventContext) {
        let eventIds = Set(events.map { $0.id })
        let events = events.jsonString

        self.deps.logger.info("Start sending events with ids:\n\(eventIds)")

        self.deps.api.statEventsAddVKIDAnonymously.execute(
            with: .init(
                events: events,
                sakVersion: Env.VKIDVersion.description
            ),
            completion: { result in
                self.handleStatEventsAddVKID(
                    result: result,
                    eventIds: eventIds
                )
            }
        )
    }

    private func handleStatEventsAddVKID(
        result: Result<StatEvents.StatEventsResponse, VKAPIError>,
        eventIds: Set<Int>
    ) {
        switch result {
        case .success(let respone):
            if respone.failedIds.isEmpty {
                self.deps.logger.info(
                    "Did send events with ids:\n\(eventIds)"
                )
            } else {
                let failedEventIds = Set(respone.failedIds)
                let sendedEventIds = eventIds.subtracting(failedEventIds)

                self.deps.logger.warning(
                    "Did send events with ids:\n\(sendedEventIds)\nFailed ids:\n\(failedEventIds)"
                )
            }
        case .failure(let error):
            self.deps.logger.error(
                "Failed to send events:\n\(eventIds)\nWith error: \(error)"
            )
        }
    }
}
