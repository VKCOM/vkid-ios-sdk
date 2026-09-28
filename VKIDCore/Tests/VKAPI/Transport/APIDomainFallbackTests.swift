//
// Copyright (c) 2026 - present, LLC "V Kontakte"
//
// 1. Permission is hereby granted to any person obtaining a copy of this Software to
// use the Software without charge.
//
// 2. Restrictions
// You may not modify, merge, publish, distribute, sublicense, and/or sell copies,
// create derivative works based upon the Software or any part thereof.
//
// 3. Termination
// This License is effective until terminated. LLC "V Kontakte" may terminate this
// License at any time without any negative consequences to our rights.
// You may terminate this License at any time by deleting the Software and all copies
// thereof. Upon termination of this license for any reason, you shall continue to be
// bound by the provisions of Section 2 above.
// Termination will be without prejudice to any rights LLC "V Kontakte" may have as
// a result of this agreement.
//
// 4. Disclaimer of warranty and liability
// THE SOFTWARE IS MADE AVAILABLE ON THE "AS IS" BASIS. LLC "V KONTAKTE" DISCLAIMS
// ALL WARRANTIES THAT THE SOFTWARE MAY BE SUITABLE OR UNSUITABLE FOR ANY SPECIFIC
// PURPOSES OF USE. LLC "V KONTAKTE" CAN NOT GUARANTEE AND DOES NOT PROMISE ANY
// SPECIFIC RESULTS OF USE OF THE SOFTWARE.
// UNDER NO CIRCUMSTANCES LLC "V KONTAKTE" BEAR LIABILITY TO THE LICENSEE OR ANY
// THIRD PARTIES FOR ANY DAMAGE IN CONNECTION WITH USE OF THE SOFTWARE.
//

import CFNetwork
import Foundation
import VKIDAllureReport
import XCTest

@testable import VKIDCore

final class APIDomainFallbackTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDCore,
        feature: "Резервный API-домен"
    )

    func testAPIRequestUsesPrimaryHost() throws {
        self.report("API-запрос использует основной домен")
        let session = URLSessionMock(responses: [.success])
        let transport = self.makeTransport(session: session)

        let result = self.execute(request: .api, using: transport)

        XCTAssertEqual(try result.get().value, "ok")
        XCTAssertEqual(session.requestHosts, ["api.vk.ru"])
    }

    func testDNSFailureRetriesWithFallbackHostAndPersistsIt() throws {
        self.report("При DNS-ошибке используется и сохраняется резервный домен")
        let storage = APIHostStorageMock()
        let apiHosts = APIHosts(hostname: "vk.ru", storage: storage)
        let session = URLSessionMock(responses: [
            .failure(URLError(.cannotFindHost)),
            .success,
        ])
        let transport = self.makeTransport(session: session, apiHosts: apiHosts)

        let result = self.execute(request: .api, using: transport)

        XCTAssertEqual(try result.get().value, "ok")
        XCTAssertEqual(session.requestHosts, ["api.vk.ru", "internal-sdk.api.vk.ru"])

        let restoredHosts = APIHosts(hostname: "vk.ru", storage: storage)
        XCTAssertEqual(restoredHosts.getHostBy(requestHost: .api), "internal-sdk.api.vk.ru")
    }

    func testEachRequestFallsBackOnceAndCyclesThroughAllAPIHosts() throws {
        self.report("Каждый запрос переключается один раз, домены перебираются по кругу")
        let storage = APIHostStorageMock()
        let apiHosts = APIHosts(hostname: "vk.ru", storage: storage)
        let unavailable = URLSessionMock.Response.failure(URLError(.cannotFindHost))
        let session = URLSessionMock(responses: [
            unavailable,
            unavailable,
            unavailable,
            unavailable,
            unavailable,
            unavailable,
            unavailable,
            .success,
        ])
        let transport = self.makeTransport(session: session, apiHosts: apiHosts)

        func assertTransition(
            requestHosts: [String],
            activeHost: String,
            line: UInt = #line
        ) {
            XCTAssertEqual(session.requestHosts, requestHosts, line: line)
            let restoredHosts = APIHosts(hostname: "vk.ru", storage: storage)
            XCTAssertEqual(restoredHosts.getHostBy(requestHost: .api), activeHost, line: line)
        }

        XCTAssertThrowsError(try self.execute(request: .api, using: transport).get())
        assertTransition(
            requestHosts: ["api.vk.ru", "internal-sdk.api.vk.ru"],
            activeHost: "internal-sdk.api.vk.ru"
        )

        XCTAssertThrowsError(try self.execute(request: .api, using: transport).get())
        assertTransition(requestHosts: [
            "api.vk.ru",
            "internal-sdk.api.vk.ru",
            "internal-sdk.api.vk.ru",
            "api.l.vk.ru",
        ], activeHost: "api.l.vk.ru")

        XCTAssertThrowsError(try self.execute(request: .api, using: transport).get())
        assertTransition(requestHosts: [
            "api.vk.ru",
            "internal-sdk.api.vk.ru",
            "internal-sdk.api.vk.ru",
            "api.l.vk.ru",
            "api.l.vk.ru",
            "api.r.vk.com",
        ], activeHost: "api.r.vk.com")

        let result = self.execute(request: .api, using: transport)
        XCTAssertEqual(try result.get().value, "ok")
        assertTransition(requestHosts: [
            "api.vk.ru",
            "internal-sdk.api.vk.ru",
            "internal-sdk.api.vk.ru",
            "api.l.vk.ru",
            "api.l.vk.ru",
            "api.r.vk.com",
            "api.r.vk.com",
            "api.vk.ru",
        ], activeHost: "api.vk.ru")
    }

    func testSSLFailureRetriesWithFallbackHost() throws {
        self.report("При SSL-ошибке используется резервный домен")
        let session = URLSessionMock(responses: [
            .failure(URLError(.secureConnectionFailed)),
            .success,
        ])
        let transport = self.makeTransport(session: session)

        let result = self.execute(request: .api, using: transport)

        XCTAssertEqual(try result.get().value, "ok")
        XCTAssertEqual(session.requestHosts, ["api.vk.ru", "internal-sdk.api.vk.ru"])
    }

    func testHTTPSProxyConnectionFailureRetriesWithFallbackHost() throws {
        self.report("При ошибке HTTPS proxy используется резервный домен")
        let session = URLSessionMock(responses: [
            .failure(
                NSError(
                    domain: kCFErrorDomainCFNetwork as String,
                    code: Int(CFNetworkErrors.cfErrorHTTPSProxyConnectionFailure.rawValue)
                )
            ),
            .success,
        ])
        let transport = self.makeTransport(session: session)

        let result = self.execute(request: .api, using: transport)

        XCTAssertEqual(try result.get().value, "ok")
        XCTAssertEqual(session.requestHosts, ["api.vk.ru", "internal-sdk.api.vk.ru"])
    }

    func testCancelledSSLChallengeRetriesWithFallbackHost() throws {
        self.report("При отмене SSL challenge используется резервный домен")
        let session = URLSessionMock(responses: [
            .failure(URLError(.cancelled)),
            .success,
        ])
        let transport = self.makeTransport(session: session)

        let result = self.execute(request: .api, using: transport)

        XCTAssertEqual(try result.get().value, "ok")
        XCTAssertEqual(session.requestHosts, ["api.vk.ru", "internal-sdk.api.vk.ru"])
    }

    func testOrdinaryNetworkFailureDoesNotRetry() {
        self.report("При обычной сетевой ошибке домен не переключается")
        let session = URLSessionMock(responses: [
            .failure(URLError(.cannotConnectToHost)),
        ])
        let transport = self.makeTransport(session: session)

        _ = self.execute(request: .api, using: transport)

        XCTAssertEqual(session.requestHosts, ["api.vk.ru"])
    }

    func testAPIErrorResponseDoesNotRetry() {
        self.report("При API-ошибке домен не переключается")
        let session = URLSessionMock(responses: [.apiError])
        let transport = self.makeTransport(session: session)

        _ = self.execute(request: .api, using: transport)

        XCTAssertEqual(session.requestHosts, ["api.vk.ru"])
    }

    func testIDRequestDoesNotUseAPIFallback() {
        self.report("ID-запрос не использует резервный API-домен")
        let session = URLSessionMock(responses: [
            .failure(URLError(.cannotFindHost)),
        ])
        let transport = self.makeTransport(session: session)

        _ = self.execute(request: .id, using: transport)

        XCTAssertEqual(session.requestHosts, ["id.vk.ru"])
    }

    func testCustomDomainDoesNotUseAPIFallback() {
        self.report("Отладочный домен не использует резервный API-домен")
        let apiHosts = APIHosts(
            template: "%@.test",
            hostname: "vk.ru",
            storage: APIHostStorageMock()
        )
        let session = URLSessionMock(responses: [
            .failure(URLError(.cannotFindHost)),
        ])
        let transport = self.makeTransport(session: session, apiHosts: apiHosts)

        _ = self.execute(request: .api, using: transport)

        XCTAssertEqual(session.requestHosts, ["api.test.vk.ru"])
    }

    private func makeTransport(
        session: URLSessionMock,
        apiHosts: APIHosts = APIHosts(hostname: "vk.ru", storage: APIHostStorageMock())
    ) -> URLSessionTransport {
        URLSessionTransport(
            urlRequestBuilder: URLRequestBuilder(apiHosts: apiHosts),
            genericParameters: VKAPIGenericParameters(
                deviceId: "device-id",
                clientId: "client-id",
                apiVersion: Version(major: 5, minor: 220, patch: 0),
                vkidVersion: Version(major: 2, minor: 0, patch: 0)
            ),
            defaultHeaders: [:],
            sslPinningConfiguration: .pinningDisabled,
            logger: LoggerStub(),
            urlSession: session
        )
    }

    private func execute(
        request host: VKAPIRequest.Host,
        using transport: URLSessionTransport
    ) -> Result<TestResponse, VKAPIError> {
        let completed = self.expectation(description: "Request completed")
        let callbackQueue = DispatchQueue(label: "com.vkid.tests.apiDomainFallback")
        var result: Result<TestResponse, VKAPIError>?
        transport.execute(
            request: VKAPIRequest(
                host: host,
                path: "/method/test",
                httpMethod: .get,
                authorization: .none
            ),
            callbackQueue: callbackQueue
        ) {
            result = $0
            completed.fulfill()
        }
        self.wait(for: [completed], timeout: 1)
        return result ?? .failure(.unknown)
    }

    private func report(_ name: String) {
        Allure.report(.init(name: name, meta: self.testCaseMeta))
    }
}

private struct TestResponse: VKAPIResponse {
    let value: String
}

private final class APIHostStorageMock: APIHostStorage {
    private var values: [String: Any] = [:]

    func string(forKey defaultName: String) -> String? {
        self.values[defaultName] as? String
    }

    func set(_ value: Any?, forKey defaultName: String) {
        self.values[defaultName] = value
    }
}

private final class URLSessionMock: URLSessionProtocol {
    struct Response {
        let data: Data?
        let error: Error?

        static let success = Self(
            data: #"{"response":{"value":"ok"}}"#.data(using: .utf8),
            error: nil
        )
        static let apiError = Self(
            data: #"{"error":{"error_code":1,"error_msg":"error"}}"#.data(using: .utf8),
            error: nil
        )

        static func failure(_ error: Error) -> Self {
            Self(data: nil, error: error)
        }
    }

    private var responses: [Response]
    private(set) var requests: [URLRequest] = []

    var requestHosts: [String] {
        self.requests.compactMap(\.url?.host)
    }

    init(responses: [Response]) {
        self.responses = responses
    }

    func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionDataTaskProtocol {
        self.requests.append(request)
        let response = self.responses.removeFirst()
        return URLSessionDataTaskMock {
            completionHandler(response.data, nil, response.error)
        }
    }
}

private final class URLSessionDataTaskMock: URLSessionDataTaskProtocol {
    private let onResume: () -> Void

    init(onResume: @escaping () -> Void) {
        self.onResume = onResume
    }

    func resume() {
        self.onResume()
    }
}
