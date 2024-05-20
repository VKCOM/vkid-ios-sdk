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

public enum MetricsReportError: Error {
    case generic(reason: String)
}

public protocol MetricsReportGenerating {
    func generateReport() throws -> String
}

extension MetricsReportGenerating {
    public var measuredReport: MetricsReportGenerating {
        MeasureMetricsReportGeneratingTime(wrapped: self)
    }
}

public final class MeasureMetricsReportGeneratingTime: MetricsReportGenerating {
    public let wrapped: MetricsReportGenerating

    private lazy var durationFormatter: DateComponentsFormatter = {
        let df = DateComponentsFormatter()
        df.allowedUnits = [.minute, .second]
        df.unitsStyle = .short
        df.calendar?.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()

    public init(wrapped: MetricsReportGenerating) {
        self.wrapped = wrapped
    }

    public func generateReport() throws -> String {
        let startTime = CFAbsoluteTimeGetCurrent()
        let report = try self.wrapped.generateReport()
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        let elapsedTimeString = self.durationFormatter.string(from: elapsedTime) ?? "0"
        return report.appending("\n\nReport generation took \(elapsedTimeString).")
    }
}
