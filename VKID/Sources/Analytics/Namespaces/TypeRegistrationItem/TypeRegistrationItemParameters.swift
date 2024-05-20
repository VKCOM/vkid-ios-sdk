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

extension TypeRegistrationItem.EventType {
    // MARK: - General
    static let screenProceed: Self = "screen_proceed"
    static let authProviderUsed: Self = "auth_provider_used"
    static let noAuthProvider: Self = "no_auth_provider"
    static let customAuth: Self = "custom_auth"
    static let errorCustomAuth: Self = "error_custom_auth"
    static let sdkInit: Self = "sdk_init"

    // MARK: - OneTapButton
    static let oneTapButtonNoUserShow: Self = "onetap_button_no_user_show"
    static let oneTapButtonNoUserTap: Self = "onetap_button_no_user_tap"
    static let oneTapButtonNoUserAuthError: Self = "onetap_button_no_user_auth_error"

    // MARK: - FloatingOneTap / OneTapBottomSheet
    static let authByFloatingOneTap: Self = "auth_by_floating_one_tap"
    static let dataLoading: Self = "data_loading"
    static let retryAuthTap: Self = "retry_auth_tap"
    static let alertAuthError: Self = "alert_auth_error"

    // MARK: - ThreeInOne / Multibranding
    static let multibrandingOAuthAdded: Self = "multibranding_oauth_added"
    static let vkButtonShow: Self = "vk_button_show"
    static let okButtonShow: Self = "ok_button_show"
    static let mailButtonShow: Self = "mail_button_show"
    static let vkButtonTap: Self = "vk_button_tap"
    static let okButtonTap: Self = "ok_button_tap"
    static let mailButtonTap: Self = "mail_button_tap"
    static let authByOAuth: Self = "auth_by_oauth"
    static let multibrandingAuthError: Self = "multibranding_auth_error"
}

extension TypeRegistrationItem.FieldItem.Name {
    static let sdkType: Self = "sdk_type"
    static let buttonType: Self = "button_type"
    static let uniqueSessionId: Self = "unique_session_id"
    static let language: Self = "language"
    static let textType: Self = "text_type"
    static let themeType: Self = "theme_type"
    static let oAuthService: Self = "oauth_service"
    static let ok: Self = "ok"
    static let mail: Self = "mail"
}

extension TypeRegistrationItem.Error {
    static let authError: Self = "auth_error"
}
