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
@testable import VKIDAllureReport
@testable import VKID

final class AuthCodeResponseParserTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDCore,
        feature: "Парсинг респонса с кодом авторизации"
    )
    private var parser: AuthCodeResponseParser!

    override func setUpWithError() throws {
        self.parser = AuthCodeResponseParserImpl()
    }

    override func tearDownWithError() throws {
        self.parser = nil
    }

    func testParseAuthCodeResponseWithValidURL() {
        Allure.report(
            .init(
                id: 2291643,
                name: "Парсинг валидного URL",
                meta: self.testCaseMeta
            )
        )
        given("Создается валидный URL") {
            let expectedResponse = makeRandomResponse()
            let validUrl = self.makeURLComponents(with: expectedResponse).url!
            when("Парсинг URL") {
                do {
                    let actualResponse = try parser.parseAuthCodeResponse(from: validUrl)
                    then("Проверка результата парсинга") {
                        XCTAssertEqual(expectedResponse, actualResponse)
                    }
                } catch {
                    XCTFail("Error in parsing: \(error)")
                }
            }
        }
    }

    func testParseAuthCodeResponseWithoutQuery() throws {
        Allure.report(
            .init(
                id: 2291664,
                name: "Парсинг URL без параметров",
                meta: self.testCaseMeta
            )
        )
        try given("Создается URL без параметров") {
            let urlWithoutQuery = URL(string: "vk523633://vk.ru/blank.html")!
            try when("Парсинг URL") {
                XCTAssertThrowsError(try self.parser.parseAuthCodeResponse(from: urlWithoutQuery)) { error in
                    then("Проверка ошибки - невалидный URL") {
                        guard case AuthFlowError.invalidAuthCallbackURL = error
                        else { return XCTFail("Invalid error type/class - \(error)") }
                    }
                }
            }
        }
    }

    func testParseAuthCodeResponseWithoutPayload() throws {
        Allure.report(
            .init(
                id: 2291693,
                name: "Парсинг URL без пейлаода",
                meta: self.testCaseMeta
            )
        )
        try given("Создается URL без пейлаода") {
            let urlWithoutPayload = URL(string: "vk523633://vk.ru/blank.html?skip=0&limit=10")!
            try when("Парсинг URL") {
                XCTAssertThrowsError(try self.parser.parseAuthCodeResponse(from: urlWithoutPayload)) { error in
                    then("Проверка ошибки - невалидный URL") {
                        guard case AuthFlowError.invalidAuthCallbackURL = error
                        else { return XCTFail("Invalid error type/class - \(error)") }
                    }
                }
            }
        }
    }

    func testParseAuthCodeResponseWithEmptyPayload() throws {
        Allure.report(
            .init(
                id: 2291692,
                name: "Парсинг URL с пустым пейлаодом",
                meta: self.testCaseMeta
            )
        )
        try given("Создается URL c пустым пейлаодом") {
            let urlWithEmptyPayload = URL(string: "vk523633://vk.ru/blank.html?payload=")!
            try when("Парсинг URL") {
                XCTAssertThrowsError(try self.parser.parseAuthCodeResponse(from: urlWithEmptyPayload)) { error in
                    then("Проверка ошибки - невалидный URL") {
                        guard case AuthFlowError.invalidAuthCallbackURL = error
                        else { return XCTFail("Invalid error type/class - \(error)") }
                    }
                }
            }
        }
    }

    func testParseAuthCodeResponseWithInvalidPayload() throws {
        Allure.report(
            .init(
                id: 2291689,
                name: "Парсинг URL с невалидным пейлаодом",
                meta: self.testCaseMeta
            )
        )
        try given("Создается URL c невалидным пейлаодом") {
            let urlWithInvalidPayload = URL(string: "vk523633://vk.ru/blank.html?payload=invalidPayloadStucture")!
            try when("Парсинг URL") {
                XCTAssertThrowsError(try self.parser.parseAuthCodeResponse(from: urlWithInvalidPayload)) { error in
                    then("Проверка ошибки - невалидный URL") {
                        guard case AuthFlowError.invalidAuthCallbackURL = error
                        else { return XCTFail("Invalid error type/class - \(error)") }
                    }
                }
            }
        }
    }

    func testParseCallbackMethodWithValidURL() {
        Allure.report(
            .init(
                id: 2291685,
                name: "Парсинг URL с валидным методом",
                meta: self.testCaseMeta
            )
        )
        given("Создается URL c валидным методом") {
            let expectedTypeAuthProvider = "external_auth"
            let validUrl = makeURLforCallbackMethod(typeAuthProvider: expectedTypeAuthProvider)
            when("Парсинг URL") {
                do {
                    let actualType = try parser.parseCallbackMethod(from: validUrl)
                    then("Проверка метода") {
                        XCTAssertEqual(actualType, expectedTypeAuthProvider)
                    }
                } catch {
                    XCTFail("Error in parsing: \(error)")
                }
            }
        }
    }

    func testParseCallbackMethodWithoutQuery() throws {
        Allure.report(
            .init(
                id: 2291661,
                name: "Парсинг URL без домена и параметров",
                meta: self.testCaseMeta
            )
        )
        try given("Создается URL без домена и параметров") {
            let urlWithoutQuery = URL(string: "vk523633://")!
            try when("Парсинг URL") {
                XCTAssertThrowsError(try self.parser.parseCallbackMethod(from: urlWithoutQuery)) { error in
                    then("Проверка ошибки - невалидный URL") {
                        guard case AuthFlowError.invalidAuthCallbackURL = error
                        else { return XCTFail("Invalid error type/class - \(error)") }
                    }
                }
            }
        }
    }

    func testParseCallbackMethodWithoutPayload() throws {
        Allure.report(
            .init(
                id: 2291659,
                name: "Парсинг URL без домена, c параметрами",
                meta: self.testCaseMeta
            )
        )
        try given("Создается URL без домена, с параметрами") {
            let urlWithoutPayload = URL(string: "vk523633://?skip=0&limit=10")!
            try when("Парсинг URL") {
                XCTAssertThrowsError(try self.parser.parseCallbackMethod(from: urlWithoutPayload)) { error in
                    then("Проверка ошибки - невалидный URL") {
                        guard case AuthFlowError.invalidAuthCallbackURL = error
                        else { return XCTFail("Invalid error type/class - \(error)") }
                    }
                }
            }
        }
    }

    func testParseCallbackMethodWithEmptyPayload() throws {
        Allure.report(
            .init(
                id: 2291648,
                name: "Парсинг URL без домена, c пустым пейлаодом",
                meta: self.testCaseMeta
            )
        )
        try given("Создается URL без домена, c пустым пейлаодом") {
            let urlWithEmptyPayload = URL(string: "vk523633://payload=")!
            try when("Парсинг URL") {
                XCTAssertThrowsError(try self.parser.parseCallbackMethod(from: urlWithEmptyPayload)) { error in
                    then("Проверка ошибки - невалидный URL") {
                        guard case AuthFlowError.invalidAuthCallbackURL = error
                        else { return XCTFail("Invalid error type/class - \(error)") }
                    }
                }
            }
        }
    }

    func testParseCallbackMethodWithInvalidPayload() throws {
        Allure.report(
            .init(
                id: 2291679,
                name: "Парсинг URL без домена, c невалидным пейлаодом",
                meta: self.testCaseMeta
            )
        )
        try given("Создается URL без домена, c невалидным пейлаодом") {
            let urlWithInvalidPayload = URL(string: "vk523633://?payload=invalidPayloadStucture")!
            try when("Парсинг URL") {
                XCTAssertThrowsError(try self.parser.parseCallbackMethod(from: urlWithInvalidPayload)) { error in
                    then("Проверка ошибки - невалидный URL") {
                        guard case AuthFlowError.invalidAuthCallbackURL = error
                        else { return XCTFail("Invalid error type/class - \(error)") }
                    }
                }
            }
        }
    }
}

extension AuthCodeResponseParserTests {
    private func makeURLforCallbackMethod(typeAuthProvider: String) -> URL {
        var urlComponents = self.makeURLComponents(with: self.makeRandomResponse())
        urlComponents.queryItems?.append(
            URLQueryItem(
                name: "vkconnect_auth_provider_method",
                value: typeAuthProvider
            )
        )

        return urlComponents.url!
    }

    private func makeURLComponents(with response: AuthCodeResponse) -> URLComponents {
        var urlComponents = URLComponents()
        urlComponents.scheme = "vk\(Int.random)"
        urlComponents.host = "vk.ru"
        urlComponents.path = "/blank.html"
        let queryItems: [URLQueryItem] = [
            .init(name: "code", value: response.code),
            .init(name: "state", value: response.state),
            .init(name: "device_id", value: response.serverProvidedDeviceId),
        ]
        urlComponents.queryItems = queryItems
        return urlComponents
    }

    private func makeRandomResponse() -> AuthCodeResponse {
        AuthCodeResponse(
            code: UUID().uuidString,
            state: UUID().uuidString,
            serverProvidedDeviceId: UUID().uuidString
        )
    }
}
