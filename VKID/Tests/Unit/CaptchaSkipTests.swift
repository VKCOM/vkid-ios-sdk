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

final class CaptchaSkipTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "Пропуск капчи для определённых запросов",
        priority: .critical
    )

    // MARK: - VKAPIRequest Tests

    func testVKAPIRequestSkipCaptchaDefaultValue() {
        Allure.report(
            .init(
                name: "VKAPIRequest: skipCaptcha по умолчанию false",
                meta: self.testCaseMeta
            )
        )

        given("Создаём запрос без указания skipCaptcha") {
            let request = VKAPIRequest(
                host: .api,
                path: "/test",
                httpMethod: .get,
                authorization: .none
            )

            then("skipCaptcha должен быть false") {
                XCTAssertFalse(request.skipCaptcha, "skipCaptcha должен быть false по умолчанию")
            }
        }
    }

    func testVKAPIRequestSkipCaptchaSetToTrue() {
        Allure.report(
            .init(
                name: "VKAPIRequest: skipCaptcha можно установить в true",
                meta: self.testCaseMeta
            )
        )

        given("Создаём запрос с skipCaptcha = true") {
            let request = VKAPIRequest(
                host: .api,
                path: "/test",
                httpMethod: .get,
                authorization: .none,
                skipCaptcha: true
            )

            then("skipCaptcha должен быть true") {
                XCTAssertTrue(request.skipCaptcha, "skipCaptcha должен быть true")
            }
        }
    }

    // MARK: - GetAnonymousToken.Parameters Tests

    func testGetAnonymousTokenParametersSkipCaptchaDefaultValue() {
        Allure.report(
            .init(
                name: "GetAnonymousToken.Parameters: skipCaptcha по умолчанию false",
                meta: self.testCaseMeta
            )
        )

        given("Создаём параметры без указания skipCaptcha") {
            let parameters = Auth.GetAnonymousToken.Parameters(
                anonymousToken: nil,
                clientId: "test",
                clientSecret: "secret"
            )

            then("skipCaptcha должен быть false") {
                XCTAssertFalse(parameters.skipCaptcha, "skipCaptcha должен быть false по умолчанию")
            }
        }
    }

    func testGetAnonymousTokenParametersSkipCaptchaSetToTrue() {
        Allure.report(
            .init(
                name: "GetAnonymousToken.Parameters: skipCaptcha можно установить в true",
                meta: self.testCaseMeta
            )
        )

        given("Создаём параметры с skipCaptcha = true") {
            let parameters = Auth.GetAnonymousToken.Parameters(
                anonymousToken: nil,
                clientId: "test",
                clientSecret: "secret",
                skipCaptcha: true
            )

            then("skipCaptcha должен быть true") {
                XCTAssertTrue(parameters.skipCaptcha, "skipCaptcha должен быть true")
            }
        }
    }

    // MARK: - GetAnonymousToken Request Tests

    func testGetAnonymousTokenRequestPassesSkipCaptchaTrue() {
        Allure.report(
            .init(
                name: "GetAnonymousToken request: skipCaptcha true передаётся в VKAPIRequest",
                meta: self.testCaseMeta
            )
        )

        given("Создаём параметры с skipCaptcha = true") {
            let parameters = Auth.GetAnonymousToken.Parameters(
                anonymousToken: nil,
                clientId: "test",
                clientSecret: "secret",
                skipCaptcha: true
            )

            when("Создаём запрос из параметров") {
                let request = Auth.GetAnonymousToken.request(with: parameters, for: nil)

                then("VKAPIRequest должен иметь skipCaptcha = true") {
                    XCTAssertTrue(request.skipCaptcha, "request.skipCaptcha должен быть true")
                }
            }
        }
    }

    func testGetAnonymousTokenRequestPassesSkipCaptchaFalse() {
        Allure.report(
            .init(
                name: "GetAnonymousToken request: skipCaptcha false передаётся в VKAPIRequest",
                meta: self.testCaseMeta
            )
        )

        given("Создаём параметры с skipCaptcha = false") {
            let parameters = Auth.GetAnonymousToken.Parameters(
                anonymousToken: nil,
                clientId: "test",
                clientSecret: "secret",
                skipCaptcha: false
            )

            when("Создаём запрос из параметров") {
                let request = Auth.GetAnonymousToken.request(with: parameters, for: nil)

                then("VKAPIRequest должен иметь skipCaptcha = false") {
                    XCTAssertFalse(request.skipCaptcha, "request.skipCaptcha должен быть false")
                }
            }
        }
    }

    // MARK: - StatEvents Tests

    func testStatEventsAnonymousRequestHasSkipCaptchaTrue() {
        Allure.report(
            .init(
                name: "StatEvents request: skipCaptcha true для анонимной статистики",
                meta: self.testCaseMeta
            )
        )

        given("Создаём параметры для StatEventsAddVKIDAnonymously") {
            let parameters = StatEvents.StatEventsParameters(
                events: "[]",
                sakVersion: "1.0.0"
            )

            when("Создаём запрос из параметров") {
                let request = StatEvents.StatEventsAddVKIDAnonymously.request(
                    with: parameters,
                    for: nil
                )

                then("VKAPIRequest должен иметь skipCaptcha = true") {
                    XCTAssertTrue(request.skipCaptcha, "request.skipCaptcha должен быть true для статистики")
                }
            }
        }
    }

    func testStatEventsAuthorizedRequestHasSkipCaptchaTrue() {
        Allure.report(
            .init(
                name: "StatEvents request: skipCaptcha true для авторизованной статистики",
                meta: self.testCaseMeta
            )
        )

        given("Создаём параметры для StatEventsAddVKID") {
            let parameters = StatEvents.StatEventsParameters(
                events: "[]",
                sakVersion: "1.0.0"
            )

            when("Создаём запрос из параметров") {
                let request = StatEvents.StatEventsAddVKID.request(
                    with: parameters,
                    for: nil
                )

                then("VKAPIRequest должен иметь skipCaptcha = true") {
                    XCTAssertTrue(request.skipCaptcha, "request.skipCaptcha должен быть true для статистики")
                }
            }
        }
    }
}
