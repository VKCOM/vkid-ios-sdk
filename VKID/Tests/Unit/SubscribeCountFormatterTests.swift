//
// Copyright (c) 2025 - present, LLC “V Kontakte”
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
import XCTest
@testable import VKIDAllureReport
@testable import VKID

final class SubscribeCountFormatterTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "Подписка на сообщество"
    )
    private var subscriberCountFormatter: SubscriberCountFormatter!

    override func setUpWithError() throws {
        self.subscriberCountFormatter = SubscriberCountFormatter()
    }

    override func tearDownWithError() throws {
        self.subscriberCountFormatter = nil
    }

    func testFormatSubscribers() {
        Allure.report(
            .init(
                name: "Формат количества участников сообщества",
                meta: self.testCaseMeta
            )
        )
        [
            (0, "0"),
            (10, "10"),
            (999, "999"),
            (1000, "1K"),
            (1200, "1,2K"),
            (12345, "12K"),
            (999999, "999K"),
            (1000000, "1M"),
            (1034567, "1M"),
            (1234567, "1.2M"),
            (12345678, "12M"),
        ].forEach { subscribersCount, result in
            self.check(subscribersCount: subscribersCount, result: result)
        }
    }

    func check(subscribersCount: Int, result: String) {
        given("\(subscribersCount) подписчиков") {
            when("Форматирование") {
                let formattedResult = self.subscriberCountFormatter.format(subscriberCount: subscribersCount)
                then("Результат \(result)") {
                    XCTAssert(formattedResult == result, "wrong calculated \(formattedResult), expected \(result)")
                }
            }
        }
    }
}
