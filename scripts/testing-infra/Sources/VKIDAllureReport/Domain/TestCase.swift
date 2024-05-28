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

extension Allure {
    /// Общая информация о тест кейсе [](https://docs.qameta.io/allure-testops/briefly/test-cases/)
    public struct TestCase {
        /// Уникальный идентификатор тест кейса в Allure TestOps.
        /// Если не указан, то в качестве идентификатора будет использоваться полное название тест кейса (например PrivacyPolicyTestCase/testScenario())
        public var id: Int?

        /// Название тест кейса
        public var name: String

        /// Метаинформация (дополнительная информация о тест кейсе: овнер, продукт, фича...)
        public var meta: MetaInformation

        public init(id: Int? = nil, name: String, meta: MetaInformation) {
            self.id = id
            self.name = name
            self.meta = meta
        }
    }
}

extension Allure.TestCase: AllureReportable {
    public var allureReportAttributes: [AllureReportAttribute] {
        var attributes = [AllureReportAttribute]()
        id.map { attributes.append(.init(name: "id", value: String($0))) }
        attributes.append(.init(name: "name", value: name))
        attributes += meta.allureReportAttributes
        return attributes
    }
}

extension Allure.TestCase {
    /// Метаинформация (дополнительная информация о тест кейсе: овнер, продукт, фича...)
    public struct MetaInformation {
        public enum Priority: String {
            case showStopper = "Show-stopper"
            case critical = "Critical"
            case major = "Major"
            case normal = "Normal"
            case minor = "Minor"
        }

        /// Владелец(ответственный) тест кейса
        public var owner: Owner

        public var platform: Platform

        /// Слой тест кейса: unit, integration или ui
        public var layer: Layer

        public var project: Project

        public var product: Product
        public var feature: String?
        public var component: String?
        public var priority: Priority?

        public init(
            owner: Owner,
            platform: Platform = .iOS_Auto,
            layer: Layer,
            project: Project = .VKIDSDK,
            product: Product,
            feature: String?,
            component: String? = nil,
            priority: Priority? = nil
        ) {
            self.owner = owner
            self.platform = platform
            self.layer = layer
            self.project = project
            self.product = product
            self.feature = feature
            self.component = component
            self.priority = priority
        }
    }
}

extension Allure.TestCase.MetaInformation: AllureReportable {
    public var allureReportAttributes: [AllureReportAttribute] {
        var attributes = [AllureReportAttribute]()
        attributes += self.owner.allureReportAttributes
        attributes += self.platform.allureReportAttributes
        attributes += self.layer.allureReportAttributes
        attributes += self.project.allureReportAttributes
        attributes += self.product.allureReportAttributes
        self.feature.map { attributes.append(.init(label: "feature", value: $0)) }
        self.component.map { attributes.append(.init(label: "component", value: $0)) }
        self.priority.map { attributes.append(.init(label: "priority", value: $0.rawValue)) }
        return attributes
    }
}

extension Allure.TestCase {
    public enum Platform: String, AllureReportable {
        case iOS_Auto = "iOS Auto"
        case iOS_Manual = "iOS Manual"
    }
}

extension Allure.TestCase {
    public enum Layer: String, AllureReportable {
        case ui
        case integration
        case unit
    }
}

extension Allure.TestCase {
    public enum Project: String, AllureReportable {
        case VKIDSDK
    }
}

extension Allure.TestCase {
    public enum Product: String, AllureReportable {
        case VKIDSDK = "VK ID SDK"
        case VKIDCore
    }
}
