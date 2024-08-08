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

import Foundation
import VKIDCore

/// Аналитика авторизации через VKID.
internal final class VKIDAnalytics: VKIDObserver {
    /// Зависимости аналитики авторизации
    internal struct Dependencies {
        /// Аналитика.
        let analytics: Analytics<TypeRegistrationItemNamespace>
    }

    /// Контекст авторизации.
    internal var authContext: AuthContext
    /// Зависимости аналитики авторизации.
    private var deps: Dependencies

    init(deps: Dependencies) {
        self.deps = deps
        self.authContext = .init(launchedBy: .service)
    }

    func vkid(_ vkid: VKID, didStartAuthUsing oAuth: OAuthProvider) {
        let analyticsContext: (inout AnalyticsEventContext) -> AnalyticsEventContext = { ctx in
            ctx.screen = Screen(screen: self.authContext.screen)
            return ctx
        }

        switch self.authContext.launchedBy {
        case .oneTapBottomSheetRetry:
            self.deps.analytics.retryAuthTap
                .context { ctx in
                    ctx.screen = .floatingOneTap
                    return ctx
                }
                .send(
                    .init(
                        uniqueSessionId: self.authContext.uniqueSessionId
                    )
                )
        case .oneTapButton(let provider, let buttonKind):
            switch provider.type {
            case .vkid:
                switch self.authContext.screen {
                case .multibrandingWidget:
                    self.deps.analytics.vkButtonTap
                        .context(analyticsContext)
                        .send(
                            .init(
                                buttonType: .init(kind: buttonKind),
                                uniqueSessionId: self.authContext.uniqueSessionId
                            )
                        )
                case .oneTapBottomSheet, .nowhere:
                    self.deps.analytics.oneTapButtonNoUserTap
                        .context(analyticsContext)
                        .send(
                            .init(
                                buttonType: .init(kind: buttonKind),
                                uniqueSessionId: self.authContext.uniqueSessionId
                            )
                        )
                }

            case .ok:
                self.deps.analytics.okButtonTap
                    .context(analyticsContext)
                    .send(
                        .init(
                            buttonType: .init(kind: buttonKind),
                            uniqueSessionId: self.authContext.uniqueSessionId
                        )
                    )
            case .mail:
                self.deps.analytics.mailButtonTap
                    .context(analyticsContext)
                    .send(
                        .init(
                            buttonType: .init(kind: buttonKind),
                            uniqueSessionId: self.authContext.uniqueSessionId
                        )
                    )
            }
        case .service:
            self.deps.analytics.customAuthStart.send(
                .init(
                    uniqueSessionId: self.authContext.uniqueSessionId,
                    oAuthProvider: oAuth
                )
            )
        }
    }

    func vkid(_ vkid: VKID, didCompleteAuthWith result: AuthResult, in oAuth: OAuthProvider) {
        if case .success = result {
            self.sendAnalyticsSuccessAuth()
        } else if case .failure = result {
            self.sendAnalyticsFailureAuth(in: oAuth)
        }
    }

    /// Отправляет аналитику при успешной авторизации.
    internal func sendAnalyticsSuccessAuth() {
        self.deps.analytics.screenProceed
            .context { ctx in
                ctx.screen = .authorizationWindow
                return ctx
            }
            .send(
                .init()
            )
    }

    /// Отправляет аналитику при неудачной авторизации.
    internal func sendAnalyticsFailureAuth(in oAuth: OAuthProvider) {
        self.deps.analytics.sdkAuthError.send(
            .init(
                context: self.authContext,
                provider: oAuth
            )
        )
    }
}
