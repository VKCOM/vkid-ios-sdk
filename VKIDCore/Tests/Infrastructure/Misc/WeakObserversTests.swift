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

import VKIDAllureReport
import VKIDCore
import XCTest

final class WeakObserversTests: XCTestCase {
    final class Observer {
        private(set) var getNotified: Bool = false

        func notify() {
            self.getNotified = true
        }
    }

    private var underTest: WeakObservers<Observer>!
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDCore,
        feature: "Список WeakObservers"
    )

    override func setUpWithError() throws {
        self.underTest = WeakObservers()
    }

    override func tearDownWithError() throws {
        self.underTest = nil
    }

    func testObserverGetNotified() {
        Allure.report(
            .init(
                name: "Добавленный в список observer получает уведомления",
                meta: self.testCaseMeta
            )
        )
        let observer = Observer()
        given("Добавляем observer в список") {
            XCTAssertFalse(observer.getNotified)
            self.underTest.add(observer)
        }
        when("Вызываем метод notify") {
            self.underTest.notify { $0.notify() }
        }
        then("Добавленный observer получает уведомление") {
            XCTAssertTrue(observer.getNotified)
        }
    }

    func testObserverStoredWeakly() {
        Allure.report(
            .init(
                name: "Добавленный в список observer хранится weak ссылкой",
                meta: self.testCaseMeta
            )
        )
        weak var observer: Observer?
        when("Добавляем observer в список") {
            do {
                let o = Observer()
                self.underTest.add(o)
                observer = o
            }
        }
        then("Если на observer нету strong ссылок - он уничтожается") {
            XCTAssertNil(observer)
        }
    }

    func testRemovedObserverNotGetNotified() {
        Allure.report(
            .init(
                name: "Удаленный из списка observer больше не получает уведомления",
                meta: self.testCaseMeta
            )
        )
        let observer = Observer()
        given("Добавляем observer в список") {
            XCTAssertFalse(observer.getNotified)
            self.underTest.add(observer)
        }
        when("Удаляем observer из списка и вызываем метод notify") {
            self.underTest.remove(observer)
            self.underTest.notify { $0.notify() }
        }
        then("Удаленный observer не получает уведомления") {
            XCTAssertFalse(observer.getNotified)
        }
    }

    func testContainsObserver() {
        Allure.report(
            .init(
                name: "Добавленный в список observer проходит проверку на contains",
                meta: self.testCaseMeta
            )
        )
        let observer = Observer()
        when("Добавляем observer в список") {
            self.underTest.add(observer)
        }
        then("Проверка на contains возвращает true") {
            XCTAssertTrue(self.underTest.contains(observer))
        }
    }
}
