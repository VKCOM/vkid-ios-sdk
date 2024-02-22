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

internal final class BottomSheetPresentationController: UIPresentationController {
    private var presentedSheetController: BottomSheetViewController {
        guard let controller = self.presentedViewController as? BottomSheetViewController else {
            preconditionFailure("Wrong type of presentedViewController")
        }
        return controller
    }

    private var shadowViewFrame: CGRect {
        let frame = self.frameOfPresentedViewInContainerView
        let containerBottomInset = containerView?.safeAreaInsets.bottom ?? 0
        let sheetBottomInset = self.presentedSheetController.layoutConfiguration.edgeInsets.bottom

        return frame.offsetBy(
            dx: 0,
            dy: frame.height + containerBottomInset + sheetBottomInset
        )
    }

    private lazy var dimmingView: UIView = {
        let view = UIView()
        let gestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(self.onTapOutsideOfSheet)
        )
        view.backgroundColor = .black.withAlphaComponent(0.4)
        view.alpha = 0
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(gestureRecognizer)
        return view
    }()

    private lazy var shadowView = BottomSheetShadowView(frame: self.shadowViewFrame)

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        self.containerView?.addSubview(self.dimmingView)
        self.containerView?.addSubview(self.shadowView)
        self.containerView?.addSubview(self.presentedView!)
        self.performAlongsideTransitionIfPossible { [weak self] in
            guard let self else {
                return
            }

            self.dimmingView.alpha = 1
            self.shadowView.alpha = 1
            self.shadowView.frame = self.frameOfPresentedViewInContainerView
        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if !completed {
            self.dimmingView.removeFromSuperview()
            self.shadowView.removeFromSuperview()
        }
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        self.performAlongsideTransitionIfPossible { [weak self] in
            guard let self else {
                return
            }

            self.dimmingView.alpha = 0
            self.shadowView.alpha = 0
            self.shadowView.frame = self.shadowViewFrame
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            self.dimmingView.removeFromSuperview()
            self.shadowView.removeFromSuperview()
        }
    }

    private func performAlongsideTransitionIfPossible(_ block: @escaping () -> Void) {
        guard let coordinator = self.presentedSheetController.transitionCoordinator else {
            block()
            return
        }

        coordinator.animate(
            alongsideTransition: { _ in block() },
            completion: nil
        )
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        self.presentedView?.frame = self.frameOfPresentedViewInContainerView
        if let frame = self.containerView?.frame {
            self.dimmingView.frame = frame
        }
        self.shadowView.frame = self.shadowViewFrame
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView else {
            return .zero
        }
        let sheet = self.presentedSheetController
        let edgeInsets = sheet.layoutConfiguration.edgeInsets
        let containerSafeArea = containerView.bounds.inset(by: containerView.safeAreaInsets)
        let availableContentSize = CGSize(
            width: min(
                416,
                containerSafeArea.width - edgeInsets.left - edgeInsets.right
            ),
            height: containerSafeArea.height
        )
        let contentSize = sheet.preferredContentSize(withParentContainerSize: availableContentSize)
        return CGRect(
            origin: .init(
                x: containerView.center.x - 0.5 * contentSize.width,
                y: containerView.bounds.height - containerView.safeAreaInsets.bottom -
                    contentSize.height - edgeInsets.bottom
            ),
            size: contentSize
        )
    }

    /// Touch event handling
    @objc
    private func onTapOutsideOfSheet() {
        self.presentedViewController.dismiss(animated: true)
    }
}
