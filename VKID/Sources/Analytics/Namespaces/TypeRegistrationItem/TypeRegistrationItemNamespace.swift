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
@_implementationOnly import VKIDCore

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

    struct OAuthServiceParameters {
        let oAuthProvider: OAuthProvider
        let uniqueSessionId: String
        let buttonType: ButtonType

        init(provider: OAuthProvider, uniqueSessionId: String, kind: OneTapButton.Layout.Kind) {
            self.oAuthProvider = provider
            self.uniqueSessionId = uniqueSessionId
            self.buttonType = .init(
                kind: kind
            )
        }
    }

    struct OAuthServicesParameters {
        let oAuthProviders: [OAuthProvider]

        init(providers: [OAuthProvider]) {
            self.oAuthProviders = providers
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
        let language: String?
        let themeType: String
        let textType: String

        init(
            language: Appearance.Locale,
            themeType: Appearance.ColorScheme,
            textType: OneTapBottomSheet.TargetActionType
        ) {
            self.language = language.rawLocale
            self.themeType = themeType.resolveSystemToActualScheme().rawValue

            switch textType {
            case .signIn:
                self.textType = "service_sign_in"
            case .signInToService:
                self.textType = "account_sign_in"
            case .registerForEvent:
                self.textType = "event_reg"
            case .applyFor:
                self.textType = "request"
            case .orderCheckout:
                self.textType = "vkid_order_placing"
            case .orderCheckoutAtService:
                self.textType = "service_order_placing"
            }
        }
    }

    // MARK: - General
    var screenProceed: ScreenProceed { Never() }
    var authProviderUsed: AuthProviderUsed { Never() }
    var noAuthProvider: NoAuthProvider { Never() }
    var customAuth: CustomAuth { Never() }
    var errorCustomAuth: ErrorCustomAuth { Never() }
    var sdkInit: SDKInit { Never() }

    // MARK: - OneTapButton
    var oneTapButtonNoUserShow: OneTapButtonNoUserShowEvent { Never() }
    var oneTapButtonNoUserTap: OneTapButtonNoUserTapEvent { Never() }
    var oneTapButtonNoUserAuthError: OneTapButtonNoUserAuthError { Never() }

    // MARK: - FloatingOneTap / OneTapBottomSheet
    var authByFloatingOneTap: AuthByFloatingOneTap { Never() }
    var dataLoading: DataLoading { Never() }
    var retryAuthTap: RetryAuthTap { Never() }
    var alertAuthError: AlertAuthError { Never() }

    // MARK: - ThreeInOne / Multibranding
    var multibrandingOAuthAdded: MultibrandingOAuthAdded { Never() }
    var vkButtonShow: VKButtonShow { Never() }
    var okButtonShow: OkButtonShow { Never() }
    var mailButtonShow: MailButtonShow { Never() }
    var vkButtonTap: VKButtonTap { Never() }
    var okButtonTap: OkButtonTap { Never() }
    var mailButtonTap: MailButtonTap { Never() }
    var authByOAuth: AuthByOAuth { Never() }
    var multibrandingAuthError: MultibrandingAuthError { Never() }

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

    struct CustomAuth: AnalyticsEventTypeAction {
        static func typeAction(with parameters: UniqueSessionParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .customAuth,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    struct ErrorCustomAuth: AnalyticsEventTypeAction {
        static func typeAction(with parameters: UniqueSessionParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .errorCustomAuth,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    struct SDKInit: AnalyticsEventTypeAction {
        static func typeAction(with parameters: Empty, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .sdkInit
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

    struct OneTapButtonNoUserAuthError: AnalyticsEventTypeAction {
        static func typeAction(with parameters: DefaultParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .oneTapButtonNoUserAuthError,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    // MARK: - FloatingOneTap / OneTapBottomSheet
    struct AuthByFloatingOneTap: AnalyticsEventTypeAction {
        static func typeAction(with parameters: Empty, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .authByFloatingOneTap
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

    struct AlertAuthError: AnalyticsEventTypeAction {
        static func typeAction(with parameters: Empty, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .alertAuthError
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

    struct AuthByOAuth: AnalyticsEventTypeAction {
        static func typeAction(with parameters: OAuthServiceParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .authByOAuth,
                    parameters: parameters,
                    context: context
                )
            )
        }
    }

    struct MultibrandingAuthError: AnalyticsEventTypeAction {
        static func typeAction(with parameters: UniqueSessionParameters, context: AnalyticsEventContext) -> TypeAction {
            TypeAction(
                typeRegistrationItem: typeRegistrationItem(
                    eventType: .multibrandingAuthError
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
        parameters: ScreenProceedParameters,
        context: AnalyticsEventContext
    ) -> TypeRegistrationItem {
        var typeRegistrationItem = self.typeRegistrationItem(eventType: eventType)
        typeRegistrationItem.fields += [
            .init(name: .themeType, value: parameters.themeType),
            .init(name: .textType, value: parameters.textType),
        ]

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

        OAuthProvider.allCases.forEach { oAuthProvider in
            typeRegistrationItem.addField(
                oAuthProvider: oAuthProvider,
                value: parameters.oAuthProviders.contains(oAuthProvider)
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
}

extension TypeRegistrationItem {
    fileprivate mutating func addField(buttonType: TypeRegistrationItemNamespace.ButtonType) {
        self.fields.append(
            .init(name: .buttonType, value: buttonType.rawValue)
        )
    }

    fileprivate mutating func addField(uniqueSessionId: String) {
        self.fields.append(
            .init(name: .uniqueSessionId, value: uniqueSessionId)
        )
    }

    fileprivate mutating func addField(oAuthProvider: OAuthProvider) {
        self.fields.append(
            .init(name: .oAuthService, value: oAuthProvider.type.endingWithRuIfNeeded)
        )
    }

    fileprivate mutating func addField(oAuthProvider: OAuthProvider, value: Bool) {
        self.fields.append(
            .init(name: .init(rawValue: oAuthProvider.type.clearName), value: value ? "1" : "0")
        )
    }

    fileprivate mutating func addField(language: String) {
        self.fields.append(
            .init(name: .language, value: language)
        )
    }
}
