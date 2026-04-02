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

final class CaptchaInterceptorTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "CaptchaInterceptor: пропуск капчи для запросов с skipCaptcha",
        priority: .critical
    )

    // MARK: - Captcha Interceptor Tests

    func testCaptchaInterceptorContinuesWhenSkipCaptchaIsTrue() {
        Allure.report(
            .init(
                name: "CaptchaInterceptor продолжает выполнение когда skipCaptcha = true",
                meta: self.testCaseMeta
            )
        )

        let expectation = XCTestExpectation(
            description: "Запрос должен быть продолжен без показа капчи"
        )

        given("Создаём CaptchaInterceptor и запрос с skipCaptcha = true") {
            let captchaInterceptor = CaptchaInterceptor(deps: .init(logger: LoggerStub()))
            let request = VKAPIRequest(
                host: .api,
                path: "/test",
                httpMethod: .get,
                authorization: .none,
                skipCaptcha: true
            )
            let response: Result<TestResponse, VKAPIError> = .failure(.unknown)

            when("Интерцептор обрабатывает ответ с ошибкой") {
                captchaInterceptor.intercept(response: response, from: request) { result in
                    then("Результат должен быть continue") {
                        switch result {
                        case .continue:
                            expectation.fulfill()
                        case .retry, .interrupt:
                            XCTFail("Ожидался .continue, получен \(result)")
                        }
                    }
                }
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testCaptchaInterceptorContinuesForNonCaptchaError() {
        Allure.report(
            .init(
                name: "CaptchaInterceptor продолжает выполнение для не-captcha ошибок",
                meta: self.testCaseMeta
            )
        )

        let expectation = XCTestExpectation(
            description: "Запрос должен быть продолжен"
        )

        given("Создаём CaptchaInterceptor и запрос с skipCaptcha = false") {
            let captchaInterceptor = CaptchaInterceptor(deps: .init(logger: LoggerStub()))
            let request = VKAPIRequest(
                host: .api,
                path: "/test",
                httpMethod: .get,
                authorization: .none,
                skipCaptcha: false
            )
            let response: Result<TestResponse, VKAPIError> = .failure(.unknown)

            when("Интерцептор обрабатывает ответ с не-captcha ошибкой") {
                captchaInterceptor.intercept(response: response, from: request) { result in
                    then("Результат должен быть continue") {
                        switch result {
                        case .continue:
                            expectation.fulfill()
                        case .retry, .interrupt:
                            XCTFail("Ожидался .continue, получен \(result)")
                        }
                    }
                }
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Test Helpers

private struct TestResponse: VKAPIResponse {
    let value: String
}
