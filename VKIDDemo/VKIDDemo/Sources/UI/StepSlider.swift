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

class StepSlider: UISlider {
    public var actualValue: Float {
        self.values[Int(value)]
    }

    public var values: [Float] {
        get {
            self._values
        }
        set {
            self._values = newValue
            self.recalculateSteps()
        }
    }

    private var _values: [Float] = []
    private var lastIndex: Int?
    private var points: [UIView] = []

    var callback: ((Float) -> Void)?

    func setup() {
        self.addTarget(
            self,
            action: #selector(self.handleValueChange(sender:)),
            for: .valueChanged
        )
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }

    private func recalculateSteps() {
        let steps = self.values.count - 1
        self.lastIndex = nil
        self.minimumValue = 0
        self.maximumValue = Float(steps)
    }

    @objc
    func handleValueChange(sender: UISlider) {
        let newIndex = Int(sender.value + 0.5)

        self.setValue(Float(newIndex), animated: false)

        let didChange = self.lastIndex == nil || newIndex != self.lastIndex!

        if didChange {
            self.lastIndex = newIndex
            let actualValue = self.values[newIndex]
            self.callback?(actualValue)
        }
    }
}
