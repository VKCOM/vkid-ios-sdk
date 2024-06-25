//
// Copyright (c) 2023 - present, LLC “V Kontakte”
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

package protocol VKAPITransport {
    func execute<T: VKAPIResponse>(
        request: VKAPIRequest,
        callbackQueue: DispatchQueue,
        completion: @escaping (Result<T, VKAPIError>) -> Void
    )
}

extension VKAPITransport {
    package func execute<T: VKAPIResponse>(
        request: VKAPIRequest,
        completion: @escaping (Result<T, VKAPIError>) -> Void
    ) {
        self.execute(
            request: request,
            callbackQueue: .main,
            completion: completion
        )
    }
}

package struct VKAPICallingContext<T: VKAPIMethod> {
    private let transport: VKAPITransport

    package init(transport: VKAPITransport) {
        self.transport = transport
    }

    package func execute(
        with parameters: @autoclosure () -> T.Parameters,
        for userId: Int? = nil,
        callbackOn callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<T.Response, VKAPIError>) -> Void
    ) {
        let request = T.request(with: parameters(), for: userId)
        self.transport.execute(
            request: request,
            callbackQueue: callbackQueue,
            completion: completion
        )
    }
}

package extension VKAPICallingContext where T.Parameters == Empty {
    func execute(
        for userId: Int? = nil,
        completion: @escaping (Result<T.Response, VKAPIError>) -> Void
    ) {
        let request = T.request(with: Empty(), for: userId)
        self.transport.execute(request: request, completion: completion)
    }
}

package protocol VKAPINamespace {}

@dynamicMemberLookup
package final class VKAPI<T: VKAPINamespace> {
    private let transport: VKAPITransport

    package init(transport: VKAPITransport) {
        self.transport = transport
    }

    package subscript<U: VKAPIMethod>(dynamicMember keyPath: KeyPath<T, U>) -> VKAPICallingContext<U> {
        VKAPICallingContext<U>(transport: self.transport)
    }
}

@dynamicMemberLookup
package final class VKAPI2<T1: VKAPINamespace, T2: VKAPINamespace> {
    private let transport: VKAPITransport

    package init(transport: VKAPITransport) {
        self.transport = transport
    }

    package subscript<U: VKAPIMethod>(dynamicMember keyPath: KeyPath<T1, U>) -> VKAPICallingContext<U> {
        VKAPICallingContext<U>(transport: self.transport)
    }

    package subscript<U: VKAPIMethod>(dynamicMember keyPath: KeyPath<T2, U>) -> VKAPICallingContext<U> {
        VKAPICallingContext<U>(transport: self.transport)
    }
}
