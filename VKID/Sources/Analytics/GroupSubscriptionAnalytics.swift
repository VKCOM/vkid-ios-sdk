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

import Foundation
import VKIDCore

/// Аналитика подписки на сообщество
internal final class GroupSubscriptionAnalytics {
    /// Зависимости аналитики подписки на сообщество
    internal struct Dependencies {
        /// Аналитика.
        let analytics: Analytics<TypeRegistrationItemNamespace>
        let appCreds: AppCredentials
    }

    /// Зависимости аналитики подписки на сообщество.
    private var deps: Dependencies

    init(deps: Dependencies) {
        self.deps = deps
    }

    /// Отправляет аналитику подписки на сообщество
    internal func sendAnalytics(
        groupId: Int,
        themeType: Appearance.ColorScheme,
        authorizer: Authorizer,
        eventType: GroupSubscriptionEventType
    ) {
        let params = TypeRegistrationItemNamespace.GroupSubscriptionParameters.init(
            groupId: groupId,
            themeType: themeType,
            appId: self.deps.appCreds.clientId
        )
        switch eventType {
        case .modalViewShown:
            self.deps.analytics.groupSubscriptionShown.send(
                params,
                authorizer: authorizer
            )
        case .subscribe:
            self.deps.analytics.groupSubscriptionTap.send(
                params,
                authorizer: authorizer
            )
        case .nextTimeTap:
            self.deps.analytics.groupSubscriptionNextTimeTap.send(
                params,
                authorizer: authorizer
            )
        case .closeTap:
            self.deps.analytics.groupSubscriptionCloseTap.send(
                params,
                authorizer: authorizer
            )
        case .errorShown:
            self.deps.analytics.groupSubscriptionErrorShown.send(
                params,
                authorizer: authorizer
            )
        case .errorCancelTap:
            self.deps.analytics.groupSubscriptionErrorCancelTap.send(
                params,
                authorizer: authorizer
            )
        case .errorCloseTap:
            self.deps.analytics.groupSubscriptionErrorCloseTap.send(
                params,
                authorizer: authorizer
            )
        case .success:
            self.deps.analytics.groupSubscriptionSuccess.send(
                params,
                authorizer: authorizer
            )
        case .errorRetry:
            self.deps.analytics.groupSubscriptionErrorRetryTap.send(
                params,
                authorizer: authorizer
            )
        }
    }
}

enum GroupSubscriptionEventType {
    case modalViewShown
    case subscribe
    case nextTimeTap
    case closeTap
    case errorShown
    case errorCancelTap
    case errorCloseTap
    case success
    case errorRetry
}
