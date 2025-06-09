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

struct GroupSubscriptionInfo: Codable {
    var subscriptionShownHistory: [Date]
    var userId: UserID

    init(subscriptionShownHistory: [Date], userId: UserID) {
        self.subscriptionShownHistory = subscriptionShownHistory
        self.userId = userId
    }
}

protocol SubscriptionStorageService {
    func saveSubscriptionInfo(_ info: GroupSubscriptionInfo)
    func getSubscriptionInfo(forUserId userId: UserID) -> GroupSubscriptionInfo?
}

internal final class GroupSubscriptionStorageService: SubscriptionStorageService {
    func saveSubscriptionInfo(_ info: GroupSubscriptionInfo) {
        var subscriptionInfo: [GroupSubscriptionInfo] = UserDefaults.standard.groupSubscriptionInfo
        if let index = subscriptionInfo.firstIndex(where: { $0.userId == info.userId }) {
            subscriptionInfo[index] = info
        } else {
            subscriptionInfo.append(info)
        }
        UserDefaults.standard.groupSubscriptionInfo = subscriptionInfo
    }

    func getSubscriptionInfo(forUserId userId: UserID) -> GroupSubscriptionInfo? {
        let subscriptionInfo = UserDefaults.standard.groupSubscriptionInfo
        return subscriptionInfo.first(where: { $0.userId == userId })
    }
}

extension UserDefaults {
    var groupSubscriptionInfo: [GroupSubscriptionInfo] {
        get {
            guard let data = UserDefaults.standard.data(
                forKey: "com.vkid.subscriptionStorage.shownInfo"
            ) else { return [] }
            let value = try? JSONDecoder().decode([GroupSubscriptionInfo].self, from: data)
            return value ?? []
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            UserDefaults.standard.set(
                data,
                forKey: "com.vkid.subscriptionStorage.shownInfo"
            )
        }
    }
}
