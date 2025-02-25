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

internal enum Authorization {
    case externalAccessToken(String)
    case userSession(UserSession)
}

internal protocol GroupSubscriptionService {
    func fetchGroupInfo(
        groupId: String,
        authorization: Authorization,
        completion: @escaping(
            Result<(
                GroupInfo,
                [GroupMemberInfo],
                friendsCount: Int,
                membersCount: Int,
                isServiceAccount: Bool
            ),
            VKAPIError>
        ) -> Void
    )

    func getGroup(
        byId: String,
        authorization: Authorization,
        completion: @escaping (Result<GroupInfo, VKAPIError>) -> Void
    )

    func getGroupMembers(
        byId: String,
        onlyFriends: Bool,
        authorization: Authorization,
        completion: @escaping (Result<([GroupMemberInfo], Int), VKIDCore.VKAPIError>) -> Void
    )

    func subscribeToGroup(
        groupId: String,
        authorization: Authorization,
        completion: @escaping (Result<Bool, VKAPIError>) -> Void
    )

    func isServiceAccount(
        authorization: Authorization,
        completion: @escaping (Result<Bool, VKAPIError>) -> Void
    )
}

internal final class GroupSubscriptionServiceImpl: GroupSubscriptionService {
    struct Dependencies: Dependency {
        let subscriptionAPI: VKAPI<GroupSubscription>
    }

    /// Зависимости сервиса
    private let deps: Dependencies

    /// Инициализация сервиса логаута сессии.
    /// - Parameter deps: Зависимости.
    init(deps: Dependencies) {
        self.deps = deps
    }

    internal func fetchGroupInfo(
        groupId: String,
        userSession: UserSession,
        completion: @escaping(
            Result<(
                GroupInfo,
                [GroupMemberInfo],
                friendsCount: Int,
                membersCount: Int,
                isServiceAccount: Bool
            ),
            VKAPIError>
        ) -> Void
    ) {
        self.fetchGroupInfo(
            groupId: groupId,
            authorization: .userSession(userSession),
            completion: completion
        )
    }

    internal func fetchGroupInfo(
        groupId: String,
        authorization: Authorization,
        completion: @escaping(Result<(
            GroupInfo,
            [GroupMemberInfo],
            friendsCount: Int,
            membersCount: Int,
            isServiceAccount: Bool
        ), VKAPIError>) -> Void
    ) {
        let dispatchQueue = DispatchQueue(label: "com.vkid.core.processingGroupInfoQueue")
        let group = DispatchGroup()

        var groupInfo: GroupInfo?
        var friendsInfo: [GroupMemberInfo]?
        var friendsCount: Int?
        var groupMembersInfo: [GroupMemberInfo]?
        var groupMembersCount: Int?
        var isServiceAccount: Bool?
        var groupInfoError: VKAPIError?

        group.enter()
        self.getGroup(
            byId: groupId,
            authorization: authorization
        ) { result in
            dispatchQueue.async {
                switch result {
                case .success(let group):
                    groupInfo = group
                case .failure(let error):
                    groupInfoError = error
                }
                group.leave()
            }
        }

        group.enter()
        self.isServiceAccount(
            authorization: authorization
        ) { result in
            dispatchQueue.async {
                switch result {
                case.success(let isServiceAcc):
                    isServiceAccount = isServiceAcc
                case.failure(let error):
                    groupInfoError = error
                }
                group.leave()
            }
        }

        group.enter()
        self.getGroupMembers(
            byId: groupId,
            onlyFriends: true,
            authorization: authorization
        ) { result in
            dispatchQueue.async {
                switch result {
                case.success((let friends, let count)):
                    friendsInfo = friends
                    friendsCount = count
                case .failure(let apiError):
                    groupInfoError = apiError
                }
                group.leave()
            }
        }

        group.enter()
        self.getGroupMembers(
            byId: groupId,
            onlyFriends: false,
            authorization: authorization
        ) { result in
            dispatchQueue.async {
                switch result {
                case.success((let members, let count)):
                    groupMembersInfo = members
                    groupMembersCount = count
                case .failure(let apiError):
                    groupInfoError = apiError
                }
                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            guard let groupInfo,
                  let friendsInfo,
                  let friendsCount,
                  let groupMembersInfo,
                  let groupMembersCount,
                  let isServiceAccount
            else {
                if let groupInfoError {
                    completion(.failure(groupInfoError))
                } else {
                    completion(.failure(.noResponseDataProvided))
                }
                return
            }
            completion(.success((
                groupInfo,
                friendsInfo + groupMembersInfo,
                friendsCount,
                groupMembersCount,
                isServiceAccount
            )))
        }
    }

    func getGroup(
        byId groupId: String,
        authorization: Authorization,
        completion: @escaping (Result<GroupInfo, VKAPIError>) -> Void
    ) {
        let (externalAccessToken, session) = self.authorization(from: authorization)
        self.deps
            .subscriptionAPI
            .groupById
            .execute(
                with: .init(
                    externalAccessToken: externalAccessToken,
                    groupIds: groupId
                ),
                for: session?.userId.value
            ) { result in
                switch result {
                case .success(let response):
                    if !response.groups.isEmpty {
                        completion(.success(.init(from: response.groups[0])))
                    } else {
                        completion(.failure(.noResponseDataProvided))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    func getGroupMembers(
        byId groupId: String,
        onlyFriends: Bool,
        authorization: Authorization,
        completion: @escaping (Result<([GroupMemberInfo], Int), VKIDCore.VKAPIError>) -> Void
    ) {
        let (externalAccessToken, session) = self.authorization(from: authorization)
        self.deps
            .subscriptionAPI
            .groupMembers
            .execute(
                with: .init(
                    groupId: groupId,
                    onlyFriends: onlyFriends,
                    externalAccessToken: externalAccessToken
                ),
                for: session?.userId.value
            ) { result in
                switch result {
                case .success(let response):
                    completion(.success((
                        response.items.map { member in
                            guard let avatar = member.photo200 else {
                                return .init(avatarURL: nil)
                            }
                            return .init(avatarURL: URL(string: avatar))
                        },
                        response.count
                    )))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    func subscribeToGroup(
        groupId: String,
        authorization: Authorization,
        completion: @escaping (Result<Bool, VKIDCore.VKAPIError>) -> Void
    ) {
        let (externalAccessToken, session) = self.authorization(from: authorization)
        self.deps
            .subscriptionAPI
            .subscribeToGroup
            .execute(
                with: .init(
                    externalAccessToken: externalAccessToken,
                    groupId: groupId
                ),
                for: session?.userId.value
            ) { result in
                switch result {
                case .success(let response):
                    completion(.success(response == 1))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    func isServiceAccount(
        authorization: Authorization,
        completion: @escaping (Result<Bool, VKIDCore.VKAPIError>) -> Void
    ) {
        let (externalAccessToken, session) = self.authorization(from: authorization)
        self.deps
            .subscriptionAPI
            .profileShortInfo.execute(
                with: .init(externalAccessToken: externalAccessToken),
                for: session?.userId.value
            ) { result in
                switch result {
                case .success(let response):
                    completion(.success(response.isServiceAccount))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    private func authorization(from auth: Authorization) -> (String?, UserSession?) {
        switch auth {
        case .externalAccessToken(let token): (token, nil)
        case .userSession(let session): (nil, session)
        }
    }
}
