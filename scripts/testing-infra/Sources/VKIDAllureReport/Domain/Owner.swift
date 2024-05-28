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

extension Allure.TestCase {
    /// Описывает автора/ответственного за тест кейс
    public struct Owner: Equatable {
        public var name: String
        public var id: Int

        public init(name: String, id: Int) {
            self.name = name
            self.id = id
        }
    }
}

// MARK: - Allure.Owner + CustomStringConvertible

extension Allure.TestCase.Owner: CustomStringConvertible {
    public var description: String { "\(name):\(id)" }
}

extension Allure.TestCase.Owner: AllureReportable {
    public var allureReportAttributes: [AllureReportAttribute] {
        [
            .init(
                label: "owner",
                value: self.description
            ),
        ]
    }
}

// MARK: - Owners

extension Allure.TestCase.Owner {
    public static let vkidTester: Self = .init(name: "vkid.ios.autotests", id: 0)
}
