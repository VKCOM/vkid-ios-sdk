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

internal enum AbsoluteTime {
    internal static var currentMicrosecondsAsString: String {
        timeString(
            with: currentMicroseconds
        )
    }

    internal static var currentMicroseconds: UInt64 {
        var time = timeval(tv_sec: 0, tv_usec: 0)
        gettimeofday(&time, nil)

        return UInt64(1.0E+6) * UInt64(time.tv_sec) + UInt64(time.tv_usec)
    }

    internal static func timeString(with microseconds: UInt64) -> String {
        String(microseconds)
    }

    internal static func microseconds(for timeInterval: TimeInterval) -> UInt64 {
        UInt64(1.0E+6 * timeInterval)
    }

    internal static func microseconds(for date: Date) -> UInt64 {
        self.microseconds(for: date.timeIntervalSince1970)
    }
}
