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

@testable import VKID
@testable import VKIDCore

public final class GroupSubscriptionServiceMock: GroupSubscriptionService {
    public func shouldShowGroupSubscriptionScreen(
        groupId: String,
        authorization: Authorization,
        completion: @escaping (Result<Bool, VKIDCore.VKAPIError>) -> Void
    ) {}

    public var handler: ((String, Authorization) -> (Result<(
        GroupInfo,
        [GroupMemberInfo],
        friendsCount: Int,
        membersCount: Int,
        isServiceAccount: Bool,
        show: Bool
    ), VKIDCore.VKAPIError>))?

    public var subscribeToGroupHandler: ((String, Authorization) -> (Result<Bool, VKAPIError>))?

    public init() {}

    public init(handler: @escaping (String, Authorization) -> Result<(
        GroupInfo,
        [GroupMemberInfo],
        friendsCount: Int,
        membersCount: Int,
        isServiceAccount: Bool,
        show: Bool
    ), VKIDCore.VKAPIError>) {
        self.handler = handler
    }

    public func fetchGroupInfo(
        groupId: String,
        authorization: Authorization,
        completion: @escaping (
            Result<(
                GroupInfo,
                [GroupMemberInfo],
                friendsCount: Int,
                membersCount: Int,
                isServiceAccount: Bool,
                show: Bool
            ), VKIDCore.VKAPIError>
        ) -> Void
    ) {
        completion(self.handler?(groupId, authorization) ?? .failure(.unknown))
    }

    public func getGroup(
        byId: String,
        authorization: Authorization,
        completion: @escaping (Result<GroupInfo, VKAPIError>) -> Void
    ) {}

    public func getGroupMembers(
        byId: String,
        onlyFriends: Bool,
        authorization: Authorization,
        completion: @escaping (Result<([GroupMemberInfo], Int), VKAPIError>) -> Void
    ) {}

    public func subscribeToGroup(
        groupId: String,
        authorization: Authorization,
        completion: @escaping (Result<Bool, VKAPIError>) -> Void
    ) {
        completion(self.subscribeToGroupHandler?(groupId,authorization) ?? .failure(.unknown))
    }

    public func isServiceAccount(
        authorization: Authorization,
        completion: @escaping (Result<Bool, VKAPIError>) -> Void
    ) {}
}
