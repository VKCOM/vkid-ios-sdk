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

import UIKit
import VKIDCore

internal struct TypeRegistrationItemNamespace: AnalyticsTypeItemNamespace {
    enum ButtonType: String {
        case icon
        case `default`

        init(kind: OneTapButton.Layout.Kind) {
            switch kind {
            case .regular:
                self = .default
            case .logoOnly:
                self = .icon
            }
        }
    }

    struct AnalyticsOAuthProvider: Equatable {
        /// Конвертированное имя провайдера
        let name: String

        init(oAuthProvider: OAuthProvider) {
            self.name = switch oAuthProvider.type {
            case .vkid: "vk"
            case .ok, .mail: oAuthProvider.type.rawValue
            }
        }
    }

    struct AuthErrorParameters {
        let authErrorFrom: String
        let uniqueSessionId: String
        let oAuthProvider: AnalyticsOAuthProvider?

        init(context: AuthContext, provider: OAuthProvider) {
            self.authErrorFrom = context.flowSource
            self.uniqueSessionId = context.uniqueSessionId
            self.oAuthProvider = .init(oAuthProvider: provider)
        }
    }

    struct OAuthServiceParameters {
        let oAuthProvider: AnalyticsOAuthProvider
        let uniqueSessionId: String
        let buttonType: ButtonType

        init(provider: OAuthProvider, uniqueSessionId: String, kind: OneTapButton.Layout.Kind) {
            self.oAuthProvider = .init(oAuthProvider: provider)
            self.uniqueSessionId = uniqueSessionId
            self.buttonType = .init(
                kind: kind
            )
        }
    }

    struct OAuthServicesParameters {
        let oAuthProviders: [AnalyticsOAuthProvider]

        init(oAuthProviders: [OAuthProvider]) {
            self.oAuthProviders = oAuthProviders.map { .init(oAuthProvider: $0) }
        }
    }

    struct ButtonTypeParameters {
        let buttonType: ButtonType

        init(buttonType: ButtonType) {
            self.buttonType = buttonType
        }
    }

    struct UniqueSessionParameters {
        let uniqueSessionId: String

        init(uniqueSessionId: String) {
            self.uniqueSessionId = uniqueSessionId
        }
    }

    struct DefaultParameters {
        let buttonType: ButtonType
        let uniqueSessionId: String

        init(
            buttonType: ButtonType,
            uniqueSessionId: String
        ) {
            self.buttonType = buttonType
            self.uniqueSessionId = uniqueSessionId
        }
    }

    struct ScreenProceedParameters {
        var language: String? = nil
        var themeType: String? = nil
        var textType: String? = nil
        var styleType: String? = nil

        init(
            themeType: Appearance.ColorScheme? = nil,
            styleType: OneTapButton.Appearance.Style._Style? = nil,
            textType: String? = nil
        ) {
            self.language = Appearance.Locale.preferredLocale?.rawLocale

            if let themeType {
                self.themeType = AnalyticsMappings.colorSchemeToText(colorScheme: themeType)
            }

            if let textType {
                self.textType = AnalyticsMappings.textTypeToText(textType: textType)
            }

            if let styleType {
                self.styleType = styleType.rawValue
            }
        }
    }

    struct CustomAuthStartParameters {
        let uniqueSessionId: String
        let oAuthProvider: AnalyticsOAuthProvider

        init(
            uniqueSessionId: String,
            oAuthProvider: OAuthProvider
        ) {
            self.uniqueSessionId = uniqueSessionId
            self.oAuthProvider = .init(oAuthProvider: oAuthProvider)
        }
    }

    // MARK: - General
    var screenProceed: ScreenProceed { Never() }
    var authProviderUsed: AuthProviderUsed { Never() }
    var noAuthProvider: NoAuthProvider { Never() }
    var customAuthStart: CustomAuthStart { Never() }
    var sdkAuthError: SDKAuthError { Never() }

    // MARK: - OneTapButton
    var oneTapButtonNoUserShow: OneTapButtonNoUserShowEvent { Never() }
    var oneTapButtonNoUserTap: OneTapButtonNoUserTapEvent { Never() }

    // MARK: - FloatingOneTap / OneTapBottomSheet
    var dataLoading: DataLoading { Never() }
    var retryAuthTap: RetryAuthTap { Never() }

    // MARK: - ThreeInOne / Multibranding
    var multibrandingOAuthAdded: MultibrandingOAuthAdded { Never() }
    var vkButtonShow: VKButtonShow { Never() }
    var okButtonShow: OkButtonShow { Never() }
    var mailButtonShow: MailButtonShow { Never() }
    var vkButtonTap: VKButtonTap { Never() }
    var okButtonTap: OkButtonTap { Never() }
    var mailButtonTap: MailButtonTap { Never() }

    // MARK: - General
    struct ScreenProceed: AnalyticsEventTypeAction {
        static func typeAction(with parameters: ScreenProceedParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .screenProceed,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    struct AuthProviderUsed: AnalyticsEventTypeAction {
        static func typeAction(with parameters: Empty, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .authProviderUsed
                )
            )
        }
    }

    struct NoAuthProvider: AnalyticsEventTypeAction {
        static func typeAction(with parameters: Empty, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .noAuthProvider
                )
            )
        }
    }

    struct CustomAuthStart: AnalyticsEventTypeAction {
        static func typeAction(
            with parameters: CustomAuthStartParameters,
            context: AnalyticsEventContext
        ) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .customAuthStart,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    struct SDKAuthError: AnalyticsEventTypeAction {
        static func typeAction(with parameters: AuthErrorParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .sdkAuthError,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    // MARK: - OneTapButton
    struct OneTapButtonNoUserShowEvent: AnalyticsEventTypeAction {
        static func typeAction(with parameters: ButtonTypeParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .oneTapButtonNoUserShow,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    struct OneTapButtonNoUserTapEvent: AnalyticsEventTypeAction {
        static func typeAction(with parameters: DefaultParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .oneTapButtonNoUserTap,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    struct DataLoading: AnalyticsEventTypeAction {
        static func typeAction(with parameters: Empty, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .dataLoading
                )
            )
        }
    }

    struct RetryAuthTap: AnalyticsEventTypeAction {
        static func typeAction(with parameters: UniqueSessionParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .retryAuthTap,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    // MARK: - ThreeInOne / Multibranding
    struct MultibrandingOAuthAdded: AnalyticsEventTypeAction {
        static func typeAction(with parameters: OAuthServicesParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .multibrandingOAuthAdded,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    struct VKButtonShow: AnalyticsEventTypeAction {
        static func typeAction(with parameters: ButtonTypeParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .vkButtonShow,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    struct OkButtonShow: AnalyticsEventTypeAction {
        static func typeAction(with parameters: ButtonTypeParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .okButtonShow,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    struct MailButtonShow: AnalyticsEventTypeAction {
        static func typeAction(with parameters: ButtonTypeParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .mailButtonShow,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    struct VKButtonTap: AnalyticsEventTypeAction {
        static func typeAction(with parameters: DefaultParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .vkButtonTap,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    struct OkButtonTap: AnalyticsEventTypeAction {
        static func typeAction(with parameters: DefaultParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .okButtonTap,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    struct MailButtonTap: AnalyticsEventTypeAction {
        static func typeAction(with parameters: DefaultParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .mailButtonTap,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }
}

extension TypeRegistrationItemNamespace {
    // MARK: - Methods
    static func typeRegistrationItem(
        eventType: TypeRegistrationItem.EventType,
        error: TypeRegistrationItem.Error? = nil
    ) -> TypeRegistrationItem {
        TypeRegistrationItem(
            eventType: eventType,
            error: error,
            fields: [
                .init(name: .sdkType, value: "vkid"),
            ]
        )
    }

    static func typeRegistrationItem(
        eventType: TypeRegistrationItem.EventType,
        parameters: AuthErrorParameters,
        context: AnalyticsEventContext
    ) -> TypeRegistrationItem {
        var typeRegistrationItem = self.typeRegistrationItem(
            eventType: eventType,
            error: .sdkAuthError
        )
        typeRegistrationItem.addField(authErrorFrom: parameters.authErrorFrom)
        typeRegistrationItem.addField(uniqueSessionId: parameters.uniqueSessionId)

        if let oAuthProvider = parameters.oAuthProvider {
            typeRegistrationItem.addField(oAuthProvider: oAuthProvider)
        }

        return typeRegistrationItem
    }

    static func typeRegistrationItem(
        eventType: TypeRegistrationItem.EventType,
        parameters: ScreenProceedParameters,
        context: AnalyticsEventContext
    ) -> TypeRegistrationItem {
        var typeRegistrationItem = self.typeRegistrationItem(eventType: eventType)

        if let themeType = parameters.themeType {
            typeRegistrationItem.addField(themeType: themeType)
        }

        if let textType = parameters.textType {
            typeRegistrationItem.addField(textType: textType)
        }

        if let styleType = parameters.styleType {
            typeRegistrationItem.addField(styleType: styleType)
        }

        if let language = parameters.language {
            typeRegistrationItem.addField(language: language)
        }

        return typeRegistrationItem
    }

    static func typeRegistrationItem(
        eventType: TypeRegistrationItem.EventType,
        parameters: OAuthServicesParameters,
        context: AnalyticsEventContext
    ) -> TypeRegistrationItem {
        var typeRegistrationItem = self.typeRegistrationItem(eventType: eventType)

        OAuthProvider.allCases
            .map { AnalyticsOAuthProvider(oAuthProvider: $0) }
            .forEach {
                typeRegistrationItem.addField(
                    oAuthProvider: $0,
                    value: parameters.oAuthProviders.contains($0)
                )
            }

        return typeRegistrationItem
    }

    static func typeRegistrationItem(
        eventType: TypeRegistrationItem.EventType,
        parameters: OAuthServiceParameters,
        context: AnalyticsEventContext
    ) -> TypeRegistrationItem {
        var typeRegistrationItem = self.typeRegistrationItem(eventType: eventType)
        typeRegistrationItem.addField(oAuthProvider: parameters.oAuthProvider)
        typeRegistrationItem.addField(uniqueSessionId: parameters.uniqueSessionId)
        typeRegistrationItem.addField(buttonType: parameters.buttonType)

        return typeRegistrationItem
    }

    static func typeRegistrationItem(
        eventType: TypeRegistrationItem.EventType,
        parameters: UniqueSessionParameters,
        context: AnalyticsEventContext
    ) -> TypeRegistrationItem {
        var typeRegistrationItem = self.typeRegistrationItem(eventType: eventType)
        typeRegistrationItem.addField(uniqueSessionId: parameters.uniqueSessionId)

        return typeRegistrationItem
    }

    static func typeRegistrationItem(
        eventType: TypeRegistrationItem.EventType,
        parameters: ButtonTypeParameters,
        context: AnalyticsEventContext
    ) -> TypeRegistrationItem {
        var typeRegistrationItem = self.typeRegistrationItem(eventType: eventType)
        typeRegistrationItem.addField(buttonType: parameters.buttonType)

        return typeRegistrationItem
    }

    static func typeRegistrationItem(
        eventType: TypeRegistrationItem.EventType,
        parameters: DefaultParameters,
        context: AnalyticsEventContext
    ) -> TypeRegistrationItem {
        var typeRegistrationItem = self.typeRegistrationItem(eventType: eventType)
        typeRegistrationItem.addField(buttonType: parameters.buttonType)
        typeRegistrationItem.addField(uniqueSessionId: parameters.uniqueSessionId)

        return typeRegistrationItem
    }

    static func typeRegistrationItem(
        eventType: TypeRegistrationItem.EventType,
        parameters: CustomAuthStartParameters,
        context: AnalyticsEventContext
    ) -> TypeRegistrationItem {
        var typeRegistrationItem = self.typeRegistrationItem(eventType: eventType)
        typeRegistrationItem.addField(uniqueSessionId: parameters.uniqueSessionId)
        typeRegistrationItem.addField(oAuthProvider: parameters.oAuthProvider)

        return typeRegistrationItem
    }
}

extension TypeRegistrationItem {
    fileprivate mutating func addField(
        authErrorFrom: String
    ) {
        self.fields.append(
            .init(name: .init(rawValue: authErrorFrom), value: "true")
        )
    }

    fileprivate mutating func addField(
        buttonType: TypeRegistrationItemNamespace.ButtonType
    ) {
        self.fields.append(
            .init(name: .buttonType, value: buttonType.rawValue)
        )
    }

    fileprivate mutating func addField(
        uniqueSessionId: String
    ) {
        self.fields.append(
            .init(name: .uniqueSessionId, value: uniqueSessionId)
        )
    }

    fileprivate mutating func addField(
        oAuthProvider: TypeRegistrationItemNamespace.AnalyticsOAuthProvider
    ) {
        self.fields.append(
            .init(name: .oAuthService, value: oAuthProvider.name)
        )
    }

    fileprivate mutating func addField(
        oAuthProvider: TypeRegistrationItemNamespace.AnalyticsOAuthProvider,
        value: Bool
    ) {
        self.fields.append(
            .init(name: .init(rawValue: oAuthProvider.name), value: value ? "1" : "0")
        )
    }

    fileprivate mutating func addField(
        language: String
    ) {
        self.fields.append(
            .init(name: .language, value: language)
        )
    }

    fileprivate mutating func addField(
        themeType: String
    ) {
        self.fields.append(
            .init(name: .themeType, value: themeType)
        )
    }

    fileprivate mutating func addField(
        textType: String
    ) {
        self.fields.append(
            .init(name: .textType, value: textType)
        )
    }

    fileprivate mutating func addField(
        styleType: String
    ) {
        self.fields.append(
            .init(name: .styleType, value: styleType)
        )
    }
}
