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
@_implementationOnly import VKIDCore

/// Аналитика авторизации через VKID.
internal final class VKIDAnalytics: VKIDObserver {
    /// Зависимости аналитики авторизации
    internal struct Dependencies {
        /// Аналитика.
        let analytics: Analytics<TypeRegistrationItemNamespace>
    }

    /// Контекст авторизации.
    internal var context: AuthContext
    /// Зависимости аналитики авторизации.
    private var deps: Dependencies

    init(deps: Dependencies) {
        self.deps = deps
        self.context = .init(launchedBy: .service)
    }

    func vkid(_ vkid: VKID, didStartAuthUsing oAuth: OAuthProvider) {
        switch self.context.launchedBy {
        case .oneTapBottomSheetRetry:
            self.deps.analytics.retryAuthTap.context(
                .init(screen: .floatingOneTap)
            ).send(
                .init(
                    uniqueSessionId: self.context.uniqueSessionId
                )
            )
        case .oneTapButton(let provider, let buttonKind):
            switch provider.type {
            case .vkid:
                switch self.context.screen {
                case .multibrandingWidget:
                    self.deps.analytics.vkButtonTap
                        .context(
                            .init(screen: self.context.screen)
                        )
                        .send(
                            .init(
                                buttonType: .init(kind: buttonKind),
                                uniqueSessionId: self.context.uniqueSessionId
                            )
                        )
                case .oneTapBottomSheet, .nowhere:
                    self.deps.analytics.oneTapButtonNoUserTap
                        .context(
                            .init(screen: self.context.screen)
                        )
                        .send(
                            .init(
                                buttonType: .init(kind: buttonKind),
                                uniqueSessionId: self.context.uniqueSessionId
                            )
                        )
                }

            case .ok:
                self.deps.analytics.okButtonTap
                    .context(
                        .init(screen: self.context.screen)
                    )
                    .send(
                        .init(
                            buttonType: .init(kind: buttonKind),
                            uniqueSessionId: self.context.uniqueSessionId
                        )
                    )
            case .mail:
                self.deps.analytics.mailButtonTap
                    .context(
                        .init(screen: self.context.screen)
                    )
                    .send(
                        .init(
                            buttonType: .init(kind: buttonKind),
                            uniqueSessionId: self.context.uniqueSessionId
                        )
                    )
            }
        case .service:
            self.deps.analytics.customAuth.send(
                .init(
                    uniqueSessionId: self.context.uniqueSessionId
                )
            )
        }
    }

    func vkid(_ vkid: VKID, didCompleteAuthWith result: AuthResult, in oAuth: OAuthProvider) {
        if case .success = result {
            self.sendAnalyticsSuccessAuth()
        } else if case .failure = result {
            self.sendAnalyticsFailureAuth()
        }
    }

    /// Отправляет аналитику при успешной авторизации.
    internal func sendAnalyticsSuccessAuth() {
        switch self.context.launchedBy {
        case .oneTapBottomSheetRetry:
            break
        case .oneTapButton(let provider, let kind):
            if provider != .vkid {
                self.deps.analytics.authByOAuth
                    .context(
                        .init(screen: self.context.screen)
                    )
                    .send(
                        .init(
                            provider: provider,
                            uniqueSessionId: self.context.uniqueSessionId,
                            kind: kind
                        )
                    )
            } else if self.context.screen == .oneTapBottomSheet {
                self.deps.analytics.authByFloatingOneTap.context(
                    .init(screen: self.context.screen)
                ).send()
            }
        case .service:
            break
        }
    }

    /// Отправляет аналитику при неудачной авторизации.
    internal func sendAnalyticsFailureAuth() {
        switch self.context.launchedBy {
        case .oneTapBottomSheetRetry:
            break
        case .oneTapButton(let provider, let kind):
            switch provider.type {
            case .vkid:
                switch self.context.screen {
                case .nowhere, .multibrandingWidget:
                    self.deps.analytics.oneTapButtonNoUserAuthError.send(
                        .init(
                            buttonType: .init(kind: kind),
                            uniqueSessionId: self.context.uniqueSessionId
                        )
                    )
                case .oneTapBottomSheet:
                    self.deps.analytics.alertAuthError.context(
                        .init(screen: .floatingOneTap)
                    ).send()
                }
            case .ok, .mail:
                self.deps.analytics.multibrandingAuthError
                    .context(
                        .init(screen: self.context.screen)
                    )
                    .send(
                        .init(
                            uniqueSessionId: self.context.uniqueSessionId
                        )
                    )
            }
        case .service:
            self.deps.analytics.errorCustomAuth.send(
                .init(
                    uniqueSessionId: self.context.uniqueSessionId
                )
            )
        }
    }
}
