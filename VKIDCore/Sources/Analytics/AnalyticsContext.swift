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

package struct AnalyticsEventContext: Equatable {
    package var screen: Screen

    package init(screen: Screen = .nowhere) {
        self.screen = screen
    }
}

/// Окружение типизированного события.
package struct AnalyticsCallingContext<EventTypeAction: AnalyticsEventTypeAction> {
    /// Зависимости окружения типизированного события
    internal struct Dependencies {
        /// Контекст события
        let eventContext: AnalyticsEventContext
        /// Сервис отправки событий аналитики
        let service: AnalyticsService

        internal func copy(with context: AnalyticsEventContext) -> Self {
            Self(
                eventContext: context,
                service: self.service
            )
        }
    }

    /// Зависимости окружения.
    private let deps: Dependencies

    /// Инициализация окружения типизированного события.
    /// - Parameter deps: Зависимости окружения типизированного события.
    internal init(deps: Dependencies) {
        self.deps = deps
    }

    /// Создаем новое окружение типизированного события,
    /// у которого будет переопределен контекст события.
    /// - Parameter changedContext: Контекст события с текущими значениями (имеется возможность их изменить).
    /// - Returns: Новое окружение типизированного события
    /// с переопределенным контекстом события.
    package func context(_ changedContext: (inout AnalyticsEventContext) -> AnalyticsEventContext) -> Self {
        var eventContext = self.deps.eventContext

        return Self(
            deps: self.deps.copy(
                with: changedContext(&eventContext)
            )
        )
    }

    /// Создаем новое окружение типизированного события,
    /// у которого будет переопределен контекст события.
    /// - Parameter eventContext: Контекст события.
    /// - Returns: Новое окружение типизированного события
    /// с переопределенным контекстом события.
    package func context(_ context: AnalyticsEventContext) -> Self {
        Self(
            deps: self.deps.copy(
                with: context
            )
        )
    }

    /// Отправка события с явно заданным типом, не имеющим параметры
    package func send() where EventTypeAction.Parameters == Empty {
        self.send(.init())
    }

    /// Отправка события с явно заданным типом, со своими параметрами
    /// - Parameter parameters: Параметры события
    package func send(_ parameters: EventTypeAction.Parameters) {
        let typeAction = EventTypeAction.typeAction(
            with: parameters,
            context: self.deps.eventContext
        )

        let event = EventProductMain(
            screen: self.deps.eventContext.screen,
            typeAction: typeAction
        )

        guard let encodedEvent = AnalyticsEncodedEvent(event) else {
            return
        }

        self.deps
            .service
            .send(
                events: [encodedEvent],
                context: self.deps.eventContext
            )
    }
}
