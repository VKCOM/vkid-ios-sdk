//
// Copyright (c) 2026 - present, LLC "V Kontakte"
//

import Foundation
import VKIDAllureReport
import XCTest

@testable import VKID

final class LocalizationResourcesTests: XCTestCase {
    private let testCaseMeta = Allure.TestCase.MetaInformation(
        owner: .vkidTester,
        layer: .unit,
        product: .VKIDSDK,
        feature: "Локализация"
    )

    func testAllLocalizedStringsArePresentForSupportedLocales() throws {
        Allure.report(
            .init(
                id: 1350681,
                name: "Все тексты переведены на поддерживаемые языки",
                meta: self.testCaseMeta
            )
        )

        let resourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/Resources/Localizable.xcstrings")
        let resourceData = try Data(contentsOf: resourceURL)
        let resource = try XCTUnwrap(
            JSONSerialization.jsonObject(with: resourceData) as? [String: Any],
            "Файл локализаций должен быть корректным JSON"
        )
        let strings = try XCTUnwrap(
            resource["strings"] as? [String: Any],
            "Файл локализаций должен содержать строки"
        )
        let supportedLocales = Set(Appearance.Locale.allCases.filter { $0 != .system }.map(\.rawValue))

        for (key, value) in strings {
            let string = try XCTUnwrap(
                value as? [String: Any],
                "Строка \(key) должна иметь описание локализаций"
            )
            let localizations = try XCTUnwrap(
                string["localizations"] as? [String: Any],
                "Для строки \(key) должны быть локализации"
            )

            XCTAssertEqual(
                Set(localizations.keys),
                supportedLocales,
                "Строка \(key) должна быть переведена на все поддерживаемые языки"
            )
        }
    }
}
