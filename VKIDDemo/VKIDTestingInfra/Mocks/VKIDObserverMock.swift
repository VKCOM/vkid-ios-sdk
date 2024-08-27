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
@testable import VKID

public final class VKIDObserverMock: VKIDObserver {
    public typealias DidStartAuthUsing = (VKID, OAuthProvider) -> Void
    public typealias DidCompleteAuthWith = (VKID, AuthResult, OAuthProvider) -> Void
    public typealias DidLogoutFrom = (VKID, UserSession, LogoutResult) -> Void
    public typealias DidRefreshAccessTokenIn = (VKID, UserSession, TokenRefreshingResult) -> Void
    public typealias DidUpdateUserIn = (VKID, UserSession, UserFetchingResult) -> Void

    public var didStartAuthUsing: DidStartAuthUsing?
    public var didCompleteAuthWith: DidCompleteAuthWith?
    public var didLogoutFrom: DidLogoutFrom?
    public var didRefreshAccessTokenIn: DidRefreshAccessTokenIn?
    public var didUpdateUserIn: DidUpdateUserIn?

    public init(
        didStartAuthUsing: DidStartAuthUsing? = nil,
        didCompleteAuthWith: DidCompleteAuthWith? = nil,
        didLogoutFrom: DidLogoutFrom? = nil,
        didRefreshAccessTokenIn: DidRefreshAccessTokenIn? = nil,
        didUpdateUserIn: DidUpdateUserIn? = nil
    ) {
        self.didStartAuthUsing = didStartAuthUsing
        self.didCompleteAuthWith = didCompleteAuthWith
        self.didLogoutFrom = didLogoutFrom
        self.didRefreshAccessTokenIn = didRefreshAccessTokenIn
        self.didUpdateUserIn = didUpdateUserIn
    }

    public func vkid(
        _ vkid: VKID,
        didStartAuthUsing oAuth: OAuthProvider
    ) {
        self.didStartAuthUsing?(vkid, oAuth)
    }

    public func vkid(
        _ vkid: VKID,
        didCompleteAuthWith result: AuthResult,
        in oAuth: OAuthProvider
    ) {
        self.didCompleteAuthWith?(vkid, result, oAuth)
    }

    public func vkid(
        _ vkid: VKID,
        didLogoutFrom session: UserSession,
        with result: LogoutResult
    ) {
        self.didLogoutFrom?(vkid, session, result)
    }

    public func vkid(
        _ vkid: VKID,
        didRefreshAccessTokenIn session: UserSession,
        with result: TokenRefreshingResult
    ) {
        self.didRefreshAccessTokenIn?(vkid, session, result)
    }

    public func vkid(
        _ vkid: VKID,
        didUpdateUserIn session: UserSession,
        with result: UserFetchingResult
    ) {
        self.didUpdateUserIn?(vkid, session, result)
    }
}
