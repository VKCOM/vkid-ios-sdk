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

final class TypeActionEncodingTests: XCTestCase {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()

    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDCore,
        feature: "Кодирование TypeAction"
    )

    var testType: TypeAction.ActionType!
    var testValue: String!
    var testTypeAction: TypeAction!

    override func setUp() {
        self.testType = TypeAction.ActionType(stringLiteral: .random)
        self.testValue = .random

        self.testTypeAction = .init(
            type: self.testType,
            value: self.testValue
        )
    }

    func testTypeActionEncoding() throws {
        Allure.report(
            .init(
                name: "Кодирование TypeAction в корректный json",
                meta: self.testCaseMeta
            )
        )

        let jsonDictionaryTemplate: [String: Any] = [
            TypeAction.CodingKeys.type.rawValue: self.testType.rawValue,
            self.testType.stringValue.convertedToSnakeCase: self.testValue!,
        ]

        var jsonData: Data!
        var jsonDictionary: [String: Any]!

        try given("Кодируем TypeAction") {
            jsonData = try XCTUnwrap(
                try? Self.encoder.encode(self.testTypeAction)
            )
        }

        try when("Превращаем закодированный json в словарь") {
            jsonDictionary = try XCTUnwrap(
                try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            )
        }

        then("Проверяем, что поля json'а имеют корректные ключи для TypeAction") {
            XCTAssertTrue(
                jsonDictionary.isEqual(to: jsonDictionaryTemplate),
                "Получен некорректно закодированный json"
            )
        }
    }
}
