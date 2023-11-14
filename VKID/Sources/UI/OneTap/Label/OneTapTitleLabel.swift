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
import UIKit

internal final class OneTapTitleLabel: UILabel, Layout {
    private let primaryTitle: String
    private let briefTitle: String

    internal init(primaryTitle: String, briefTitle: String) {
        self.primaryTitle = primaryTitle
        self.briefTitle = briefTitle
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layout(in frame: CGRect) {
        self.text = self.title(for: frame.width)
        self.frame = frame
        self.sizeToFit()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let primarySize = self.primaryTitle.size(with: self.font)
        if primarySize.width <= size.width {
            return primarySize
        }

        let briefSize = self.briefTitle.size(with: self.font)
        if briefSize.width <= size.width {
            return briefSize
        }
        return .zero
    }

    private func title(for width: CGFloat) -> String? {
        let primaryWidth = self.primaryTitle.size(with: self.font).width
        if primaryWidth <= width {
            return self.primaryTitle
        }
        let briefWidth = self.briefTitle.size(with: self.font).width
        if briefWidth <= width {
            return self.briefTitle
        }
        return nil
    }
}

extension String {
    fileprivate func size(with font: UIFont) -> CGSize {
        (self as NSString).size(withAttributes: [.font: font])
    }
}
