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

    override func setUpWithError() throws {
        self.underTest = WeakObservers()
    }

    override func tearDownWithError() throws {
        self.underTest = nil
    }

    func testObserverGetNotified() {
        let observer = Observer()
        XCTAssertFalse(observer.getNotified)
        self.underTest.add(observer)

        self.underTest.notify { $0.notify() }

        XCTAssertTrue(observer.getNotified)
    }

    func testObserverStoredWeakly() {
        weak var observer: Observer?
        do {
            let o = Observer()
            self.underTest.add(o)
            observer = o
        }
        XCTAssertNil(observer)
    }

    func testRemovedObserverNotGetNotified() {
        let observer = Observer()
        XCTAssertFalse(observer.getNotified)
        self.underTest.add(observer)

        self.underTest.remove(observer)
        self.underTest.notify { $0.notify() }

        XCTAssertFalse(observer.getNotified)
    }

    func testContainsObserver() {
        let observer = Observer()
        self.underTest.add(observer)
        XCTAssertTrue(self.underTest.contains(observer))
    }
}
