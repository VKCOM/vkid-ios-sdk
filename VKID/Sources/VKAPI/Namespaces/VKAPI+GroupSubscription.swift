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

internal protocol VKAPIExternalAccessTokenProviding: VKAPIDictionaryRepresentable {
    var externalAccessToken: String? { get }
}

internal struct GroupSubscription: VKAPINamespace {
    struct ProfileShortInfo: VKAPIMethod {
        struct Response: VKAPIResponse {
            let isServiceAccount: Bool
        }

        struct Parameters: VKAPIExternalAccessTokenProviding {
            let externalAccessToken: String?
        }

        static func request(with parameters: Parameters, for userId: Int?) -> VKAPIRequest {
            VKAPIRequest(
                host: .api,
                path: "/method/account.getProfileShortInfo",
                httpMethod: .post,
                parameters: parameters.dictionaryWithoutExternalAccessToken,
                authorization: parameters.externalAccessToken.getAuthorization(userId: userId)
            )
        }
    }

    struct GroupById: VKAPIMethod {
        struct Group: Decodable {
            let id: Int
            let name: String
            let photo200: String?
            let description: String
            let verified: Int
            let isMember: Int?
            let isClosed: Int
        }

        struct Response: VKAPIResponse {
            let groups: [Group]
        }

        struct Parameters: VKAPIExternalAccessTokenProviding {
            var externalAccessToken: String?
            let groupIds: String
            let fields: String = "description,verified,is_member"
        }

        static func request(with parameters: Parameters, for userId: Int?) -> VKAPIRequest {
            VKAPIRequest(
                host: .api,
                path: "/method/groups.getById",
                httpMethod: .post,
                parameters: parameters.dictionaryWithoutExternalAccessToken,
                authorization: parameters.externalAccessToken.getAuthorization(userId: userId)
            )
        }
    }

    struct GroupMembers: VKAPIMethod {
        struct Member: Decodable {
            let photo200: String?
        }

        struct Response: VKAPIResponse {
            let items: [Member]
            let count: Int
        }

        struct Parameters: VKAPIExternalAccessTokenProviding {
            var externalAccessToken: String?
            let groupId: String
            let sort: String
            let count: Int
            let fields: String
            let filter: String?

            init(
                groupId: String,
                onlyFriends: Bool,
                externalAccessToken: String? = nil,
                sort: String = "id_asc",
                count: Int = 3,
                fields: String = "photo_200"
            ) {
                self.groupId = groupId
                self.filter = onlyFriends ? "friends" : nil
                self.externalAccessToken = externalAccessToken
                self.sort = sort
                self.count = count
                self.fields = fields
            }
        }

        static func request(with parameters: Parameters, for userId: Int?) -> VKAPIRequest {
            VKAPIRequest(
                host: .api,
                path: "/method/groups.getMembers",
                httpMethod: .post,
                parameters: parameters.dictionaryWithoutExternalAccessToken,
                authorization: parameters.externalAccessToken.getAuthorization(userId: userId)
            )
        }
    }

    struct SubscribeToGroup: VKAPIMethod {
        typealias Response = Int

        struct Parameters: VKAPIExternalAccessTokenProviding {
            var externalAccessToken: String?
            let groupId: String
            let source: String = "vkid_sdk"
        }

        static func request(with parameters: Parameters, for userId: Int?) -> VKAPIRequest {
            VKAPIRequest(
                host: .api,
                path: "/method/groups.join",
                httpMethod: .post,
                parameters: parameters.dictionaryWithoutExternalAccessToken,
                authorization: parameters.externalAccessToken.getAuthorization(userId: userId)
            )
        }
    }

    struct ShouldShowSubscribeToGroup: VKAPIMethod {
        struct Response: VKAPIResponse {
            let response: ShowResponse
        }

        struct ShowResponse: Decodable {
            let show: Bool
        }

        struct Parameters: VKAPIExternalAccessTokenProviding {
            var externalAccessToken: String?
        }

        static func request(with parameters: Parameters, for userId: Int?) -> VKAPIRequest {
            VKAPIRequest(
                host: .id,
                path: "/vkid_sdk_is_show_subscription",
                httpMethod: .post,
                parameters: parameters.dictionaryWithoutExternalAccessToken,
                authorization: parameters.externalAccessToken.getAuthorization(userId: userId)
            )
        }
    }

    var subscribeToGroup: SubscribeToGroup { Never() }
    var profileShortInfo: ProfileShortInfo { Never() }
    var groupMembers: GroupMembers { Never() }
    var groupById: GroupById { Never() }
    var shouldShowSubscribeToGroup: ShouldShowSubscribeToGroup { Never() }
}

extension String? {
    func getAuthorization(userId: Int?) ->VKAPIRequest.Authorization {
        guard let self else { return .accessToken(userId: userId) }

        return .externalAccessToken(self)
    }
}

extension VKAPIExternalAccessTokenProviding {
    var dictionaryWithoutExternalAccessToken: [String: Any] {
        dictionaryRepresentation.filter { key, _ in key != "external_access_token" }
    }
}

extension GroupSubscription.SubscribeToGroup.Response: VKAPIResponse {}
