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

internal final class BottomSheetAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool
    private let bottomSheetEdgeInsets: UIEdgeInsets
    private var currentAnimator: UIViewImplicitlyAnimating?

    internal init(
        bottomSheetEdgeInsets: UIEdgeInsets,
        presentation: Bool
    ) {
        self.bottomSheetEdgeInsets = bottomSheetEdgeInsets
        self.isPresenting = presentation
    }

    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        0.25
    }

    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        let animator = if self.isPresenting {
            self.animatePresentation(
                using: transitionContext,
                duration: self.transitionDuration(using: transitionContext)
            )
        } else {
            self.animateDismissal(
                using: transitionContext,
                duration: self.transitionDuration(using: transitionContext)
            )
        }
        animator.startAnimation()
        self.currentAnimator = animator
    }

    func animationEnded(_ transitionCompleted: Bool) {
        self.currentAnimator?.stopAnimation(false)
    }

    func interruptibleAnimator(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating {
        if self.isPresenting {
            return self.animatePresentation(
                using: transitionContext,
                duration: self.transitionDuration(using: transitionContext)
            )
        } else {
            return self.animateDismissal(
                using: transitionContext,
                duration: self.transitionDuration(using: transitionContext)
            )
        }
    }

    private func animatePresentation(
        using transitionContext: UIViewControllerContextTransitioning,
        duration: TimeInterval
    ) -> UIViewImplicitlyAnimating {
        let toView = transitionContext.view(forKey: .to)!
        let toViewController = transitionContext.viewController(forKey: .to)!
        let finalFrame = transitionContext.finalFrame(for: toViewController)

        let safeAreaBottomInset = transitionContext.containerView.safeAreaInsets.bottom
        let dy = finalFrame.height + safeAreaBottomInset + self.bottomSheetEdgeInsets.bottom
        toView.frame = finalFrame.offsetBy(dx: 0, dy: dy)
        let animator = UIViewPropertyAnimator(
            duration: duration,
            curve: .easeOut
        ) {
            toView.frame = finalFrame
        }
        animator.addCompletion { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        return animator
    }

    private func animateDismissal(
        using transitionContext: UIViewControllerContextTransitioning,
        duration: TimeInterval
    ) -> UIViewImplicitlyAnimating {
        let fromView = transitionContext.view(forKey: .from)!
        let fromViewController = transitionContext.viewController(forKey: .from)!
        let initialFrame = transitionContext.initialFrame(for: fromViewController)

        let animator = UIViewPropertyAnimator(
            duration: duration,
            curve: .easeOut
        ) {
            let safeAreaBottomInset = transitionContext.containerView.safeAreaInsets.bottom
            let dy = initialFrame.height + safeAreaBottomInset + self.bottomSheetEdgeInsets.bottom
            fromView.frame = initialFrame.offsetBy(dx: 0, dy: dy)
        }
        animator.addCompletion { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        return animator
    }
}
