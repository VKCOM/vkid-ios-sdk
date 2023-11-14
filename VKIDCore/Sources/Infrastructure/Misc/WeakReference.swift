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

public struct WeakReference<T> {
    private weak var _ref: AnyObject?

    public var value: T? {
        self._ref as? T
    }

    public init(_ ref: AnyObject?) {
        precondition(ref is T, "Incorrect type. Value is expected to be of \(T.self) type")
        self._ref = ref
    }
}

/// Not thread-safe for now
public struct WeakObservers<T> {
    private var observers: [WeakReference<T>] = []

    public init() {}

    public mutating func add(_ observer: T) {
        self.observers.append(WeakReference(observer as AnyObject))
    }

    public mutating func remove(_ observer: T) {
        if let idx = index(of: observer) {
            self.observers.remove(at: idx)
        }
    }

    public nonmutating func contains(_ observer: T) -> Bool {
        self.index(of: observer) != nil
    }

    public nonmutating func notify(_ block: (T) -> Void) {
        self.observers.forEach {
            if let o = $0.value {
                block(o)
            }
        }
    }

    private func index(of observer: T) -> Int? {
        self.observers.firstIndex {
            $0.value as AnyObject === observer as AnyObject
        }
    }
}
