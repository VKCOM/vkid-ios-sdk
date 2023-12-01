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

internal class BottomSheetShadowView: UIView {
    private static let cornerRadius: CGFloat = 14

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = frame
        let layer0 = self.createShadowLayer(
            shadowRadius: 16,
            shadowOffset: CGSize(width: 0, height: 4),
            bounds: self.bounds
        )
        let layer1 = self.createShadowLayer(
            shadowRadius: 2,
            shadowOffset: CGSize(width: 0, height: 0),
            bounds: self.bounds
        )
        self.layer.addSublayer(layer0)
        self.layer.addSublayer(layer1)
        self.layer.cornerRadius = BottomSheetShadowView.cornerRadius
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var frame: CGRect {
        didSet {
            if let sublayers = self.layer.sublayers {
                for layer in sublayers {
                    layer.update(
                        frame: self.bounds,
                        cornerRadius: BottomSheetShadowView.cornerRadius
                    )
                }
            }
        }
    }

    private func createShadowLayer(
        shadowRadius: CGFloat,
        shadowOffset: CGSize,
        bounds: CGRect
    ) -> CALayer {
        let layer = CALayer()
        layer.update(
            frame: bounds,
            cornerRadius: BottomSheetShadowView.cornerRadius
        )
        layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = shadowRadius
        layer.shadowOffset = shadowOffset
        layer.cornerRadius = BottomSheetShadowView.cornerRadius
        return layer
    }
}
