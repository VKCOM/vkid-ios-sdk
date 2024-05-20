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
@testable import VKID

final class AuthCodeResponseParserTests: XCTestCase {
    private var parser: AuthCodeResponseParser!

    override func setUpWithError() throws {
        self.parser = AuthCodeResponseParserImpl()
    }

    override func tearDownWithError() throws {
        self.parser = nil
    }

    func testParseAuthCodeResponseWithValidURL() {
        let expectedResponse = makeRandomResponse()
        let validUrl = self.makeURLComponents(with: expectedResponse).url!
        do {
            let actualResponse = try parser.parseAuthCodeResponse(from: validUrl)
            XCTAssertEqual(expectedResponse, actualResponse)
        } catch {
            XCTFail("Error in parsing: \(error)")
        }
    }

    func testParseAuthCodeResponseWithoutQuery() {
        let urlWithoutQuery = URL(string: "vk523633://vk.com/blank.html")!
        XCTAssertThrowsError(try self.parser.parseAuthCodeResponse(from: urlWithoutQuery)) { error in
            guard case AuthFlowError.invalidAuthCallbackURL = error
            else { return XCTFail("Invalid error type/class - \(error)") }
        }
    }

    func testParseAuthCodeResponseWithoutPayload() {
        let urlWithoutPayload = URL(string: "vk523633://vk.com/blank.html?skip=0&limit=10")!
        XCTAssertThrowsError(try self.parser.parseAuthCodeResponse(from: urlWithoutPayload)) { error in
            guard case AuthFlowError.invalidAuthCallbackURL = error
            else { return XCTFail("Invalid error type/class - \(error)") }
        }
    }

    func testParseAuthCodeResponseWithEmptyPayload() {
        let urlWithEmptyPayload = URL(string: "vk523633://vk.com/blank.html?payload=")!
        XCTAssertThrowsError(try self.parser.parseAuthCodeResponse(from: urlWithEmptyPayload)) { error in
            guard case AuthFlowError.invalidAuthCallbackURL = error
            else { return XCTFail("Invalid error type/class - \(error)") }
        }
    }

    func testParseAuthCodeResponseWithInvalidPayload() {
        let urlWithInvalidPayload = URL(string: "vk523633://vk.com/blank.html?payload=invalidPayloadStucture")!
        XCTAssertThrowsError(try self.parser.parseAuthCodeResponse(from: urlWithInvalidPayload)) { error in
            guard case AuthFlowError.invalidAuthCallbackURL = error
            else { return XCTFail("Invalid error type/class - \(error)") }
        }
    }

    func testParseCallbackMethodWithValidURL() {
        let expectedTypeAuthProvider = "external_auth"
        let validUrl = makeURLforCallbackMethod(typeAuthProvider: expectedTypeAuthProvider)
        do {
            let actualType = try parser.parseCallbackMethod(from: validUrl)
            XCTAssertEqual(actualType, expectedTypeAuthProvider)
        } catch {
            XCTFail("Error in parsing: \(error)")
        }
    }

    func testParseCallbackMethodWithoutQuery() {
        let urlWithoutQuery = URL(string: "vk523633://")!
        XCTAssertThrowsError(try self.parser.parseCallbackMethod(from: urlWithoutQuery)) { error in
            guard case AuthFlowError.invalidAuthCallbackURL = error
            else { return XCTFail("Invalid error type/class - \(error)") }
        }
    }

    func testParseCallbackMethodWithoutPayload() {
        let urlWithoutPayload = URL(string: "vk523633://?skip=0&limit=10")!
        XCTAssertThrowsError(try self.parser.parseCallbackMethod(from: urlWithoutPayload)) { error in
            guard case AuthFlowError.invalidAuthCallbackURL = error
            else { return XCTFail("Invalid error type/class - \(error)") }
        }
    }

    func testParseCallbackMethodWithEmptyPayload() {
        let urlWithEmptyPayload = URL(string: "vk523633://payload=")!
        XCTAssertThrowsError(try self.parser.parseCallbackMethod(from: urlWithEmptyPayload)) { error in
            guard case AuthFlowError.invalidAuthCallbackURL = error
            else { return XCTFail("Invalid error type/class - \(error)") }
        }
    }

    func testParseCallbackMethodWithInvalidPayload() {
        let urlWithInvalidPayload = URL(string: "vk523633://?payload=invalidPayloadStucture")!
        XCTAssertThrowsError(try self.parser.parseCallbackMethod(from: urlWithInvalidPayload)) { error in
            guard case AuthFlowError.invalidAuthCallbackURL = error
            else { return XCTFail("Invalid error type/class - \(error)") }
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
        urlComponents.host = "vk.com"
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
