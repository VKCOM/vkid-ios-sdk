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

internal final class BottomSheetInteractiveDismissTransition: UIPercentDrivenInteractiveTransition {
    private weak var presentedViewController: UIViewController?

    private lazy var interactiveDismissPanRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(self.onHandleInteractiveDismissPan(recognizer:))
        )
        return recognizer
    }()

    internal var isActive: Bool {
        self.interactiveDismissPanRecognizer.state == .began ||
            self.interactiveDismissPanRecognizer.state == .changed
    }

    internal func attach(to controller: UIViewController) {
        controller.view.addGestureRecognizer(self.interactiveDismissPanRecognizer)
        self.presentedViewController = controller
    }

    @objc
    private func onHandleInteractiveDismissPan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            self.presentedViewController?.dismiss(animated: true)
        case .changed:
            self.update(self.interactiveDismissPanRecognizer.dismissTranslationPercent)
        case .ended, .cancelled:
            if recognizer.isProjectedEndLocationAtTheBottomHalf(percentComplete: self.percentComplete) {
                self.finish()
            } else {
                self.cancel()
            }
        case .failed:
            cancel()
        default:
            break
        }
    }
}

extension UIPanGestureRecognizer {
    fileprivate var dismissTranslationPercent: CGFloat {
        let currentTranslation = self.translation(in: self.view).y
        return currentTranslation / self.maxDismissTranslation
    }

    fileprivate func isProjectedEndLocationAtTheBottomHalf(percentComplete: CGFloat) -> Bool {
        let initialVelocity = self.velocity(in: self.view).y
        let currentTranslation = self.maxDismissTranslation * percentComplete
        let distanceOffset = self.projectedDistance(
            initialVelocity: initialVelocity,
            decelerationRate: UIScrollView.DecelerationRate.fast.rawValue
        )
        let endTranslation = currentTranslation + distanceOffset
        return endTranslation > self.maxDismissTranslation / 2
    }

    private func projectedDistance(
        initialVelocity: CGFloat,
        decelerationRate: CGFloat
    ) -> CGFloat {
        (initialVelocity / 1000.0) * decelerationRate / (1.0 - decelerationRate)
    }

    private var maxDismissTranslation: CGFloat {
        self.view?.bounds.height ?? 0.1
    }

    public static func project(
        _ velocity: CGFloat,
        onto position: CGFloat,
        decelerationRate: UIScrollView.DecelerationRate = .normal
    ) -> CGFloat {
        position - 0.001 * velocity / log(decelerationRate.rawValue)
    }
}
