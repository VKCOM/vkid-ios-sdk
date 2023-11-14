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

import XCTest
@testable import VKIDCore

final class VKAPIDictionaryRepresentableTest: XCTestCase {
    private class TestClass: VKAPIDictionaryRepresentable {
        open var test_String: String?
        public var tEsTBoolVariable: Bool
        internal var TESTInt: Int
        private var privateTestInt: Int?

        func foo() {}

        init(testString: String? = nil, testBoolVariable: Bool, testInt: Int, privateTestInt: Int? = nil) {
            self.test_String = testString
            self.tEsTBoolVariable = testBoolVariable
            self.TESTInt = testInt
            self.privateTestInt = privateTestInt
        }
    }

    private struct TestStruct: VKAPIDictionaryRepresentable {
        public var test_Bool_Variable: Bool?
        internal var tEsTInt: Int
        private var PRIVATETestInt: Int?

        func foo() {}

        init(testBoolVariable: Bool?, testInt: Int, privateTestInt: Int? = nil) {
            self.test_Bool_Variable = testBoolVariable
            self.tEsTInt = testInt
            self.PRIVATETestInt = privateTestInt
        }
    }

    func testClassDictionaryRepresentation() {
        let testClass: VKAPIDictionaryRepresentable = TestClass(
            testString: "some string",
            testBoolVariable: false,
            testInt: 0,
            privateTestInt: 1
        )

        let expectedResult: [String: Any] = [
            "test__string": "some string",
            "t_es_t_bool_variable": false,
            "t_est_int": 0,
            "private_test_int": 1,
        ]

        let testClassDict = NSDictionary(dictionary: testClass.dictionaryRepresentation)
        let expectedResultDict = NSDictionary(dictionary: expectedResult)
        XCTAssertEqual(testClassDict, expectedResultDict)
    }

    func testClassDictionaryRepresentationWithNilParams() {
        let testClass: VKAPIDictionaryRepresentable = TestClass(
            testString: nil,
            testBoolVariable: false,
            testInt: 0,
            privateTestInt: nil
        )

        let expectedResult: [String: Any] = [
            "t_es_t_bool_variable": false,
            "t_est_int": 0,
        ]

        let testClassDict = NSDictionary(dictionary: testClass.dictionaryRepresentation)
        let expectedResultDict = NSDictionary(dictionary: expectedResult)
        XCTAssertEqual(testClassDict, expectedResultDict)
    }

    func testStructDictionaryRepresentation() {
        let testStruct: VKAPIDictionaryRepresentable = TestStruct(
            testBoolVariable: false,
            testInt: -1,
            privateTestInt: 3
        )

        let expectedResult: [String: Any] = [
            "test__bool__variable": false,
            "t_es_t_int": -1,
            "p_rivate_test_int": 3,
        ]

        let testClassDict = NSDictionary(dictionary: testStruct.dictionaryRepresentation)
        let expectedResultDict = NSDictionary(dictionary: expectedResult)
        XCTAssertEqual(testClassDict, expectedResultDict)
    }

    func testStructDictionaryRepresentationWithNilParams() {
        let testStruct: VKAPIDictionaryRepresentable = TestStruct(
            testBoolVariable: nil,
            testInt: -1,
            privateTestInt: nil
        )

        let expectedResult: [String: Any] = [
            "t_es_t_int": -1,
        ]

        let testClassDict = NSDictionary(dictionary: testStruct.dictionaryRepresentation)
        let expectedResultDict = NSDictionary(dictionary: expectedResult)
        XCTAssertEqual(testClassDict, expectedResultDict)
    }
}
