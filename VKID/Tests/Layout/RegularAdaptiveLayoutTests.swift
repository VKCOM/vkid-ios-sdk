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

import CoreGraphics
import VKIDAllureReport
import XCTest
@testable import VKID

final class RegularAdaptiveLayoutTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDCore,
        feature: "Адаптивный лейаут кнопки",
        priority: .critical
    )
    enum Constants {
        static let logoSize: CGSize = .init(width: 10, height: 10)
        static let marginSize: CGFloat = 8.0
    }

    var logo: LayoutMock!
    var title: LayoutMock!
    var activityIndicator: LayoutMock!

    var testLayout: Layout!

    override func setUpWithError() throws {
        self.logo = LayoutMock()
        self.title = LayoutMock()
        self.activityIndicator = LayoutMock()

        self.testLayout = OneTapControl.RegularAdaptiveLayout(
            logo: self.logo,
            title: self.title,
            activityIndicator: self.activityIndicator,
            logoSize: Constants.logoSize
        )
    }

    override func tearDownWithError() throws {
        self.logo = nil
        self.title = nil
        self.activityIndicator = nil

        self.testLayout = nil
    }

    func testSquaredSize() {
        Allure.report(
            .init(
                id: 2291641,
                name: "Квадратные размеры",
                meta: self.testCaseMeta
            )
        )
        given("Задается фрейм") {
            let frame = CGRect(
                origin: .zero,
                size: self.testLayout.sizeThatFits(.zero)
            )
            when("Лейаут по фрейму") {
                self.testLayout.layout(in: frame)
                then("Проверка размеров") {
                    // width: [ <- 4 -> [10] <- 4 -> ] = 18
                    // height: [ <- 4 -> [10] <- 4 -> ] = 18
                    XCTAssertEqual(
                        frame.size,
                        CGSize(width: 18, height: 18)
                    )
                    // centered with size
                    XCTAssertEqual(
                        self.logo.frame,
                        CGRect(x: 4, y: 4, width: 10, height: 10)
                    )
                    // centered
                    XCTAssertEqual(
                        self.title.frame,
                        CGRect(x: 9, y: 9, width: 0, height: 0)
                    )
                    // centered
                    XCTAssertEqual(
                        self.activityIndicator.frame,
                        CGRect(x: 9, y: 9, width: 0, height: 0)
                    )
                }
            }
        }
    }

    func testMinimalSize() {
        Allure.report(
            .init(
                id: 2291680,
                name: "Минимальные размеры",
                meta: self.testCaseMeta
            )
        )
        given("Задается заголовок и минимальный фрейм") {
            self.title.sizeThatFits = .init(width: 30, height: 10)

            let frame = CGRect(
                origin: .zero,
                size: self.testLayout.sizeThatFits(.zero)
            )
            when("Лейаут по фрейму") {
                self.testLayout.layout(in: frame)
                then("Проверка размеров") {
                    // width: [ <- 4 -> [10] <- 4 -> [30] <- 4 -> [10] <- 4 -> ] = 66
                    // height: [<- 4 -> [10] <- 4 -> ] = 18
                    XCTAssertEqual(
                        frame.size,
                        CGSize(width: 66, height: 18)
                    )
                    // x: = (66 - (10 + 4 + 30)) / 2 = 22 / 2 = 11
                    XCTAssertEqual(
                        self.logo.frame,
                        CGRect(x: 11, y: 4, width: 10, height: 10)
                    )
                    // x: = 11 + 10 + 4 = 25
                    XCTAssertEqual(
                        self.title.frame,
                        CGRect(x: 25, y: 4, width: 30, height: 10)
                    )
                    // x: = 66 - (5 + 4) = 57
                    XCTAssertEqual(
                        self.activityIndicator.frame,
                        CGRect(x: 57, y: 9, width: 0, height: 0)
                    )
                }
            }
        }
    }

    func testWideSize() {
        Allure.report(
            .init(
                id: 2291668,
                name: "Широкие размеры",
                meta: self.testCaseMeta
            )
        )
        given("Задается заголовок и фрейм") {
            self.title.sizeThatFits = .init(width: 30, height: 10)

            let frame = CGRect(
                origin: .zero,
                size: self.testLayout.sizeThatFits(CGSize(width: 98, height: 26))
            )
            when("Лейаут по фрейму") {
                self.testLayout.layout(in: frame)
                then("Проверка размеров") {
                    // width: [ <- 16 -> [10] <- 8 -> [30] <- 8 -> [10] <- 16 -> ] = 98
                    // height: [<- 8 -> [10] <- 8 -> ] = 26
                    XCTAssertEqual(
                        frame.size,
                        CGSize(width: 98, height: 26)
                    )
                    // x: = (98 - (10 + 8 + 30)) / 2 = 50 / 2 = 25
                    XCTAssertEqual(
                        self.logo.frame,
                        CGRect(x: 25, y: 8, width: 10, height: 10)
                    )
                    // x: = 25 + 10 + 8 = 43
                    XCTAssertEqual(
                        self.title.frame,
                        CGRect(x: 43, y: 8, width: 30, height: 10)
                    )
                    // x: = 98 - (5 + 8) = 85
                    XCTAssertEqual(
                        self.activityIndicator.frame,
                        CGRect(x: 85, y: 13, width: 0, height: 0)
                    )
                }
            }
        }
    }
}
