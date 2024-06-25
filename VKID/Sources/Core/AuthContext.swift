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

/// Контекст метода авторизации
internal struct AuthContext: Equatable {
    /// Уникальный идентификатор вызова авторизации
    let uniqueSessionId: String
    /// Экран вызова
    let screen: Screen
    /// Источник вызова авторизации
    let launchedBy: AuthorizationSource

    /// Источник вызова, текстовое представление
    var flowSource: String {
        switch self.launchedBy {
        case .oneTapBottomSheetRetry, .oneTapButton:
            switch self.screen {
            case .multibrandingWidget:
                "from_multibranding"
            case .oneTapBottomSheet:
                "from_floating_one_tap"
            case .nowhere:
                "from_one_tap"
            }
        case .service:
            "from_custom_auth"
        }
    }

    internal init(
        uniqueSessionId: String = UUID().uuidString,
        screen: Screen = .nowhere,
        launchedBy: AuthorizationSource
    ) {
        self.uniqueSessionId = uniqueSessionId
        self.screen = screen
        self.launchedBy = launchedBy
    }

    internal enum Screen: Equatable {
        case multibrandingWidget
        case oneTapBottomSheet
        case nowhere
    }

    internal enum AuthorizationSource: Equatable {
        case oneTapBottomSheetRetry
        case oneTapButton(provider: OAuthProvider, kind: OneTapButton.Layout.Kind)
        case service
    }
}

extension Screen {
    internal init(screen: AuthContext.Screen) {
        self = switch screen {
        case .multibrandingWidget: .multibrandingWidget
        case .oneTapBottomSheet: .floatingOneTap
        case .nowhere: .nowhere
        }
    }
}
