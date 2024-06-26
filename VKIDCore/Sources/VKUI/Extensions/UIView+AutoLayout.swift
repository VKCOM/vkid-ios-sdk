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

import UIKit

package final class ConstraintBuilder {
    private weak var superview: UIView?
    private weak var subview: UIView?

    fileprivate init(superview: UIView, subview: UIView) {
        self.superview = superview
        self.subview = subview
    }
}

extension ConstraintBuilder {
    package func pinToEdges(withInsets insets: UIEdgeInsets = .zero) {
        guard let superview, let subview else {
            return
        }
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(
                equalTo: superview.leadingAnchor,
                constant: insets.left
            ),
            subview.trailingAnchor.constraint(
                equalTo: superview.trailingAnchor,
                constant: -insets.right
            ),
            subview.topAnchor.constraint(
                equalTo: superview.topAnchor,
                constant: insets.top
            ),
            subview.bottomAnchor.constraint(
                equalTo: superview.bottomAnchor,
                constant: -insets.bottom
            ),
        ])
    }

    package func pinSize(_ size: CGSize) {
        guard let subview else {
            return
        }
        NSLayoutConstraint.activate([
            subview.widthAnchor.constraint(equalToConstant: size.width),
            subview.heightAnchor.constraint(equalToConstant: size.height),
        ])
    }
}

extension UIView {
    package func addSubview(
        _ subview: UIView,
        constraintBuilder: (ConstraintBuilder) -> Void
    ) {
        self.addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        constraintBuilder(
            ConstraintBuilder(
                superview: self,
                subview: subview
            )
        )
    }

    package func buildConstraint(_ builder: (ConstraintBuilder) -> Void) {
        guard let superview else {
            return
        }
        self.translatesAutoresizingMaskIntoConstraints = false
        builder(
            ConstraintBuilder(
                superview: superview,
                subview: self
            )
        )
    }
}
