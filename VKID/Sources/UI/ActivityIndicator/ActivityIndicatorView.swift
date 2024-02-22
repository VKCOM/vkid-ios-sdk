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
@_implementationOnly import VKIDCore

internal final class ActivityIndicatorView: UIView {
    private let lineWidth: CGFloat
    private var _isAnimating = false

    override var layer: CAShapeLayer {
        super.layer as! CAShapeLayer
    }

    override class var layerClass: AnyClass {
        CAShapeLayer.self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, lineWidth: CGFloat = 2.0) {
        self.lineWidth = lineWidth
        super.init(frame: frame)
        self.setupLayer()
        self.updateLayerStrokeColor()
        self.updateLayerPath()
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = false
    }

    override var frame: CGRect {
        get {
            super.frame
        }
        set {
            super.frame = newValue
            self.updateLayerPath()
        }
    }

    override var tintColor: UIColor! {
        get {
            super.tintColor
        }
        set {
            super.tintColor = newValue
            self.updateLayerStrokeColor()
        }
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.updateLayerStrokeColor()
    }

    private func setupLayer() {
        self.layer.lineWidth = self.lineWidth
        self.layer.lineCap = .round
        self.layer.strokeColor = self.tintColor.cgColor
        self.layer.fillColor = nil
        self.layer.strokeStart = 0
        self.layer.strokeEnd = 0.8
        self.layer.masksToBounds = true
    }

    private func bezierPath(
        for frame: CGRect,
        lineWidth: CGFloat
    ) -> UIBezierPath {
        let size = frame.size * 0.65
        let halfWidth = size.width / 2.0
        return UIBezierPath(
            arcCenter: .init(
                x: frame.width / 2,
                y: frame.height / 2
            ),
            radius: max(halfWidth - lineWidth, 0),
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )
    }

    private func updateLayerStrokeColor() {
        self.layer.strokeColor = self.tintColor.cgColor
    }

    private func updateLayerPath() {
        self.layer.path = self.bezierPath(
            for: self.frame,
            lineWidth: self.layer.lineWidth
        ).cgPath
    }
}

extension ActivityIndicatorView: ActivityIndicating {
    private enum AnimationKeys: String {
        case spin
    }

    var isAnimating: Bool {
        self._isAnimating
    }

    func startAnimating() {
        guard !self.isAnimating else {
            return
        }
        self._isAnimating = true
        self.addSpinAnimation()
    }

    func stopAnimating() {
        guard self.isAnimating else {
            return
        }
        self.removeSpinAnimation()
        self._isAnimating = false
    }

    private func addSpinAnimation() {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = 0.8
        animation.fromValue = 0
        animation.toValue = 2 * Double.pi
        animation.repeatCount = .infinity
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = true

        self.layer.transform = CATransform3DIdentity
        self.layer.add(animation, forKey: AnimationKeys.spin.rawValue)

        self.layer.shouldRestoreAnimationsOnBecomeActive(
            true,
            for: [AnimationKeys.spin.rawValue]
        )
    }

    private func removeSpinAnimation() {
        if let transform = self.layer.presentation()?.transform {
            let angle = atan2(transform.m12, transform.m11)
            self.layer.transform = CATransform3DMakeRotation(angle, 0.0, 0.0, 1.0)
        }

        self.layer.removeAnimation(forKey: AnimationKeys.spin.rawValue)

        self.layer.shouldRestoreAnimationsOnBecomeActive(
            false,
            for: [AnimationKeys.spin.rawValue]
        )
    }
}
