//
// Copyright (c) 2025 - present, LLC "V Kontakte"
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

import Foundation
import VKIDAllureReport
import XCTest

@testable import VKID
@testable import VKIDCore

final class AnonymousTokenCaptchaTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .integration,
        product: .VKIDSDK,
        feature: "Получение анонимного токена с учётом skipCaptcha",
        priority: .critical
    )

    // MARK: - AnonymousTokenService Tests

    func testAnonymousTokenServiceAllowCaptchaFalsePassesSkipCaptchaTrue() {
        Allure.report(
            .init(
                name: "AnonymousTokenService: allowCaptcha=false передаёт skipCaptcha=true в запрос",
                meta: self.testCaseMeta
            )
        )

        let expectation = XCTestExpectation(
            description: "Запрос должен быть выполнен с skipCaptcha=true"
        )

        var capturedRequest: VKAPIRequest?

        given("Создаём мок транспорта, который захватывает запрос") {
            let transportMock = AnonymousTokenTransportMock { request in
                capturedRequest = request
                expectation.fulfill()
            }

            let service = AnonymousTokenServiceImpl(
                deps: .init(
                    keychain: Keychain(),
                    api: VKAPI<Auth>(transport: transportMock),
                    credentials: AppCredentials(clientId: "test", clientSecret: "secret")
                )
            )

            when("Запрашиваем токен с allowCaptcha=false") {
                service.getFreshToken(allowCaptcha: false) { _ in }
            }
        }

        wait(for: [expectation], timeout: 1.0)

        then("Запрос должен иметь skipCaptcha=true") {
            XCTAssertNotNil(capturedRequest, "Запрос должен быть выполнен")
            XCTAssertTrue(capturedRequest?.skipCaptcha ?? false, "skipCaptcha должен быть true")
        }
    }

    func testAnonymousTokenServiceAllowCaptchaTruePassesSkipCaptchaFalse() {
        Allure.report(
            .init(
                name: "AnonymousTokenService: allowCaptcha=true передаёт skipCaptcha=false в запрос",
                meta: self.testCaseMeta
            )
        )

        let expectation = XCTestExpectation(
            description: "Запрос должен быть выполнен с skipCaptcha=false"
        )

        var capturedRequest: VKAPIRequest?

        given("Создаём мок транспорта, который захватывает запрос") {
            let transportMock = AnonymousTokenTransportMock { request in
                capturedRequest = request
                expectation.fulfill()
            }

            let service = AnonymousTokenServiceImpl(
                deps: .init(
                    keychain: Keychain(),
                    api: VKAPI<Auth>(transport: transportMock),
                    credentials: AppCredentials(clientId: "test", clientSecret: "secret")
                )
            )

            when("Запрашиваем токен с allowCaptcha=true") {
                service.getFreshToken(allowCaptcha: true) { _ in }
            }
        }

        wait(for: [expectation], timeout: 1.0)

        then("Запрос должен иметь skipCaptcha=false") {
            XCTAssertNotNil(capturedRequest, "Запрос должен быть выполнен")
            XCTAssertFalse(capturedRequest?.skipCaptcha ?? true, "skipCaptcha должен быть false")
        }
    }

    // MARK: - RequestAuthorizationInterceptor Tests

    func testRequestAuthorizationInterceptorPassesAllowCaptchaTrue() {
        Allure.report(
            .init(
                name: "RequestAuthorizationInterceptor: передаёт allowCaptcha=true при авторизации",
                meta: self.testCaseMeta
            )
        )

        let expectation = XCTestExpectation(
            description: "getFreshToken должен быть вызван с allowCaptcha=true"
        )

        given("Создаём мок AnonymousTokenService") {
            let anonymousTokenServiceMock = LocalAnonymousTokenServiceMock()
            anonymousTokenServiceMock.onGetFreshToken = { _, allowCaptcha, completion in
                XCTAssertTrue(allowCaptcha, "allowCaptcha должен быть true")
                completion(.success(AnonymousToken(value: "test", expirationDate: Date() + 3600)))
                expectation.fulfill()
            }

            let interceptor = RequestAuthorizationInterceptor(
                deps: .init(anonymousTokenService: anonymousTokenServiceMock)
            )

            let request = VKAPIRequest(
                host: .api,
                path: "/test",
                httpMethod: .get,
                authorization: .anonymousToken
            )

            when("Интерцептор обрабатывает запрос с anonymousToken авторизацией") {
                interceptor.intercept(request: request) { _ in }
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - ExpiredAnonymousTokenInterceptor Tests

    func testExpiredAnonymousTokenInterceptorPassesAllowCaptchaFalse() {
        Allure.report(
            .init(
                name: "ExpiredAnonymousTokenInterceptor: передаёт allowCaptcha=false при обновлении токена",
                meta: self.testCaseMeta
            )
        )

        let expectation = XCTestExpectation(
            description: "getFreshToken должен быть вызван с allowCaptcha=false"
        )

        given("Создаём мок AnonymousTokenService") {
            let anonymousTokenServiceMock = LocalAnonymousTokenServiceMock()
            anonymousTokenServiceMock.onGetFreshToken = { _, allowCaptcha, completion in
                XCTAssertFalse(allowCaptcha, "allowCaptcha должен быть false")
                completion(.success(AnonymousToken(value: "test", expirationDate: Date() + 3600)))
                expectation.fulfill()
            }

            let interceptor = ExpiredAnonymousTokenInterceptor(
                anonymousTokenService: anonymousTokenServiceMock
            )

            let request = VKAPIRequest(
                host: .api,
                path: "/test",
                httpMethod: .get,
                authorization: .anonymousToken
            )
            let response: Result<TestResponse, VKAPIError> = .failure(.anonymousTokenExpired)

            when("Интерцептор обрабатывает ошибку истёкшего токена") {
                interceptor.intercept(response: response, from: request) { _ in }
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Test Helpers

private final class AnonymousTokenTransportMock: VKAPITransport {
    private let onRequest: (VKAPIRequest) -> Void

    init(onRequest: @escaping (VKAPIRequest) -> Void) {
        self.onRequest = onRequest
    }

    func execute<T>(
        request: VKAPIRequest,
        callbackQueue: DispatchQueue,
        completion: @escaping (Result<T, VKAPIError>) -> Void
    ) where T: VKAPIResponse {
        self.onRequest(request)
        // Возвращаем ошибку, так как нам не нужен реальный ответ для теста
        callbackQueue.async {
            completion(.failure(.unknown))
        }
    }
}

private final class LocalAnonymousTokenServiceMock: AnonymousTokenService {
    var lastAllowCaptcha: Bool?
    var onGetFreshToken: ((Bool, Bool, @escaping (Result<AnonymousToken, Error>) -> Void) -> Void)?

    func getFreshToken(
        forceRefresh: Bool,
        allowCaptcha: Bool,
        completion: @escaping (Result<AnonymousToken, Error>) -> Void
    ) {
        self.lastAllowCaptcha = allowCaptcha
        self.onGetFreshToken?(forceRefresh, allowCaptcha, completion)
    }
}

private struct TestResponse: VKAPIResponse {
    let value: String
}
