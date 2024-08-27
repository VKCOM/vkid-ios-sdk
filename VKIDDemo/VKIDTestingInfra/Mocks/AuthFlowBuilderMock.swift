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

@testable import VKID

public final class AuthFlowMock: AuthFlow {
    public typealias Handler = (
        _ presenter: UIKitPresenter,
        _ completion: @escaping AuthFlowResultCompletion
    ) -> Void

    public var handler: Handler?

    public init(handler: Handler? = nil) {
        self.handler = handler
    }

    public func authorize(with presenter: UIKitPresenter, completion: @escaping AuthFlowResultCompletion) {
        self.handler?(presenter, completion)
    }
}

public final class AuthFlowBuilderMock: AuthFlowBuilder {
    public typealias WebViewAuthFlowHandler = (
        _ authContext: AuthContext,
        _ authConfig: ExtendedAuthConfiguration,
        _ appearance: Appearance
    ) -> any AuthFlow
    public typealias AuthByProviderFlowHandler = (
        _ authContext: AuthContext,
        _ authConfig: ExtendedAuthConfiguration,
        _ appearance: Appearance
    ) -> any AuthFlow
    public typealias ServiceAuthFlowHandler = (
        _ authContext: AuthContext,
        _ authConfig: ExtendedAuthConfiguration,
        _ appearance: Appearance
    ) -> any AuthFlow

    public var webViewAuthFlowHandler: WebViewAuthFlowHandler?
    public var authByProviderFlowHandler: AuthByProviderFlowHandler?
    public var serviceAuthFlowHandler: ServiceAuthFlowHandler?

    public init(
        webViewAuthFlowHandler: WebViewAuthFlowHandler? = nil,
        authByProviderFlowHandler: AuthByProviderFlowHandler? = nil,
        serviceAuthFlowHandler: ServiceAuthFlowHandler? = nil
    ) {
        self.webViewAuthFlowHandler = webViewAuthFlowHandler
        self.authByProviderFlowHandler = authByProviderFlowHandler
        self.serviceAuthFlowHandler = serviceAuthFlowHandler
    }

    public func webViewAuthFlow(
        in authContext: AuthContext,
        for authConfig: ExtendedAuthConfiguration,
        appearance: Appearance
    ) -> any AuthFlow {
        self.webViewAuthFlowHandler?(authContext, authConfig, appearance) ?? AuthFlowMock()
    }

    public func authByProviderFlow(
        in authContext: AuthContext,
        for authConfig: ExtendedAuthConfiguration,
        appearance: Appearance
    ) -> any AuthFlow {
        self.authByProviderFlowHandler?(authContext, authConfig, appearance) ?? AuthFlowMock()
    }

    public func serviceAuthFlow(
        in authContext: AuthContext,
        for authConfig: ExtendedAuthConfiguration,
        appearance: Appearance
    ) -> any AuthFlow {
        self.serviceAuthFlowHandler?(authContext, authConfig, appearance) ?? AuthFlowMock()
    }
}
