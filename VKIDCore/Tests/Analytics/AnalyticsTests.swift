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

import VKIDAllureReport
import XCTest

@testable import VKIDCore

final class AnalyticsTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .integration,
        product: .VKIDCore,
        feature: "Формирование и отправка события аналитики"
    )

    var testAnalytics: Analytics<TestAnalyticsNamespace>!
    var analyticsServiceMock: AnalyticsServiceMock!

    override func setUp() {
        self.analyticsServiceMock = .init()
        self.testAnalytics = .init(
            deps: .init(
                service: self.analyticsServiceMock
            )
        )
    }

    override func tearDown() {
        self.analyticsServiceMock = nil
        self.testAnalytics = nil
        TestAnalyticsNamespace.TestAnalyticsEvent.updateVariables()
    }

    func testAnalyticsSendWithCustomContext() throws {
        Allure.report(
            .init(
                id: 2313590,
                name: "Формирование и отправка события аналитики",
                meta: self.testCaseMeta
            )
        )

        let expectation = XCTestExpectation()

        let parameters: TestAnalyticsNamespace.CustomParameters = .random
        let context: AnalyticsEventContext = .init(
            screen: .init(rawValue: .random)
        )
        let jsonDictionaryTemplate = try XCTUnwrap(
            AnalyticsEncodedEvent(
                EventProductMain(
                    screen: context.screen,
                    typeAction: TestAnalyticsNamespace.TestAnalyticsEvent.typeAction(parameters: parameters)
                )
            )?.jsonString.jsonDictionary
        )

        given("Настроена обработка отправки событий") {
            self.analyticsServiceMock.onSend = { events, eventContext in
                defer { expectation.fulfill() }

                XCTAssertEqual(
                    context,
                    eventContext,
                    "Контекст полученный сервисом отправки событий не совпадает с контекстом при отправке"
                )

                then("Обрабатываем событие") {
                    guard !events.isEmpty else {
                        XCTFail("Получен пустой массив с событиями")
                        return
                    }

                    events.forEach { event in
                        guard let jsonDictionary = event.jsonString.jsonDictionary else {
                            XCTFail("Не удалось конвертировать json строку в словарь")
                            return
                        }

                        XCTAssertTrue(
                            jsonDictionary.isEqual(
                                to: jsonDictionaryTemplate,
                                excludingValueInKeys: [
                                    "id",
                                    "prev_event_id",
                                    "prev_nav_id",
                                    "timestamp",
                                ]
                            ),
                            "Получен некорректно закодированный json"
                        )
                    }
                }
            }
        }

        when("Отправляем событие") {
            self.testAnalytics.testEvent
                .context(context)
                .send(parameters)

            wait(for: [expectation], timeout: 5.0)
        }
    }
}
