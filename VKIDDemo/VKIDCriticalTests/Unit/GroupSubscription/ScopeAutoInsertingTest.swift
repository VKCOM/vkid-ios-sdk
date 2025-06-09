//
// Copyright (c) 2025 - present, LLC “V Kontakte”
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
import VKIDTestingInfra
import XCTest

@_spi(VKIDDebug)
@testable import VKID
@testable import VKIDCore

final class ScopeAutoInsertingTest: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "Подписка на сообщество",
        priority: .critical
    )

    func testAutoAddingGroupScope() {
        Allure.report(
            .init(
                name: "Автодобавление скопа groups в пустой конфиг",
                meta: self.testCaseMeta
            )
        )
        given("Задаем конфигурацию для подписки на сообщество") {
            when("Инициализируем конфигурацию") {
                let authConfig = AuthConfiguration(
                    groupSubscriptionConfiguration: .init(subscribeToGroupId: "1")
                )
                then("Проверяем наличие скопа groups") {
                    XCTAssert(authConfig.scope!.value.contains(Scope.Permission.groups.rawValue), "Нет скопа groups")
                }
            }
        }
    }

    func testAutoAddingGroupsScopeWithOthers() {
        Allure.report(
            .init(
                name: "Автодобавление скопа groups вместе с другими скопами",
                meta: self.testCaseMeta
            )
        )
        given("Задаем конфигурацию для подписки на сообщество") {
            when("Инициализируем конфигурацию со скопами phone, email") {
                enum Scopes: String, CaseIterable {
                    case phone
                    case email
                }
                let authConfig = AuthConfiguration(
                    scope: Scope(Set(Scopes.allCases.map(\.rawValue))),
                    groupSubscriptionConfiguration: .init(subscribeToGroupId: "1")
                )
                then("Проверяем наличие скопов") {
                    for scope in Scopes.allCases {
                        XCTAssert(authConfig.scope!.value.contains(scope.rawValue), "Нет скопа \(scope)")
                    }
                    XCTAssert(authConfig.scope!.value.contains(Scope.Permission.groups.rawValue), "Нет скопа")
                }
            }
        }
    }
}
