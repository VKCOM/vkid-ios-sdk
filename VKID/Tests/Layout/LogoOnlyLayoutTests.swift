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
import XCTest
@testable import VKID

final class LogoOnlyLayoutTests: XCTestCase {
    enum Constants {
        static let logoSize: CGSize = .init(width: 10, height: 10)
        static let buttonSize: CGSize = .init(width: 20, height: 20)
    }

    var logo: LayoutMock!
    var title: LayoutMock!
    var activityIndicator: LayoutMock!

    var testLayout: Layout!

    override func setUpWithError() throws {
        self.logo = LayoutMock()
        self.title = LayoutMock()
        self.activityIndicator = LayoutMock()

        self.testLayout = OneTapControl.LogoOnlyLayout(
            logo: self.logo,
            title: self.title,
            activityIndicator: self.activityIndicator,
            logoSize: Constants.logoSize,
            buttonSize: Constants.buttonSize
        )
    }

    override func tearDownWithError() throws {
        self.logo = nil
        self.title = nil
        self.activityIndicator = nil

        self.testLayout = nil
    }

    func testMinimalSize() {
        let frame = CGRect(
            origin: .zero,
            size: self.testLayout.sizeThatFits(.zero)
        )

        self.testLayout.layout(in: frame)

        // width: [ <- 5 -> [10] <- 5 -> ] = 20
        // height: [ <- 5 -> [10] <- 5 -> ] = 20
        XCTAssertEqual(
            frame.size,
            CGSize(width: 20, height: 20)
        )
        // centered
        XCTAssertEqual(
            self.title.frame,
            CGRect(x: 10, y: 10, width: 0, height: 0)
        )
        //  centered with size
        XCTAssertEqual(
            self.logo.frame,
            CGRect(x: 5, y: 5, width: 10, height: 10)
        )
        // centered
        XCTAssertEqual(
            self.activityIndicator.frame,
            CGRect(x: 10, y: 10, width: 0, height: 0)
        )
    }

    func testSizeWithLargeWidth() {
        let frame = CGRect(
            origin: .zero,
            size: self.testLayout.sizeThatFits(
                CGSize(
                    width: Constants.buttonSize.width * 3,
                    height: Constants.buttonSize.height * 2
                )
            )
        )

        self.testLayout.layout(in: frame)

        // Constants.buttonSize.height * 2 = 40
        // width: [ <- 25 -> [10] <- 25 -> ] = 60
        // height: [ <- 15 -> [10] <- 15 -> ] = 40
        XCTAssertEqual(
            frame.size,
            CGSize(width: 60, height: 40)
        )
        // centered
        XCTAssertEqual(
            self.title.frame,
            CGRect(x: 30, y: 20, width: 0, height: 0)
        )
        // centered with size
        XCTAssertEqual(
            self.logo.frame,
            CGRect(x: 25, y: 15, width: 10, height: 10)
        )
        // centered
        XCTAssertEqual(
            self.activityIndicator.frame,
            CGRect(x: 30, y: 20, width: 0, height: 0)
        )
    }

    func testSizeWithLessWidth() {
        let frame = CGRect(
            origin: .zero,
            size: self.testLayout.sizeThatFits(
                CGSize(
                    width: Constants.buttonSize.width,
                    height: Constants.buttonSize.height * 2
                )
            )
        )

        self.testLayout.layout(in: frame)

        // Constants.buttonSize.height * 2 = 40
        // width: [ <- 5 -> [10] <- 5 -> ] = 20
        // height: [ <- 15 -> [10] <- 15 -> ] = 40
        XCTAssertEqual(
            frame.size,
            CGSize(width: 20, height: 40)
        )
        // centered
        XCTAssertEqual(
            self.title.frame,
            CGRect(x: 10, y: 20, width: 0, height: 0)
        )
        // centered with size
        XCTAssertEqual(
            self.logo.frame,
            CGRect(x: 5, y: 15, width: 10, height: 10)
        )
        // centered
        XCTAssertEqual(
            self.activityIndicator.frame,
            CGRect(x: 10, y: 20, width: 0, height: 0)
        )
    }
}
