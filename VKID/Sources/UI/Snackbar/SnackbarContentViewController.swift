//
// Copyright (c) 2025 - present, LLC “V Kontakte”
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
import VKIDCore

internal final class SnackbarContentViewController: UIViewController, BottomSheetContent {
    public weak var contentDelegate: BottomSheetContentDelegate?
    private let snackbarConfig: SnackbarSheetConfig
    private let onLoad: () -> Void
    private let onDismiss: () -> Void

    internal init (
        snackbarConfig: SnackbarSheetConfig,
        onLoad: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.snackbarConfig = snackbarConfig
        self.onLoad = onLoad
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.contentPlaceholderView) {
            $0.pinToEdges()
        }
    }

    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.onLoad()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.onDismiss()
    }

    func preferredContentSize(withParentContainerSize parentSize: CGSize) -> CGSize {
        self.view.systemLayoutSizeFitting(
            parentSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }

    private lazy var contentPlaceholderView: UIView = {
        let view = UIView()
        view.backgroundColor = self.snackbarConfig.theme.colors.background.value
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self.image)
        view.addSubview(self.label)

        NSLayoutConstraint.activate([
            self.image.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            self.label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            self.label.leadingAnchor.constraint(equalTo: self.image.trailingAnchor, constant: 12),
            self.image.topAnchor.constraint(equalTo: view.topAnchor, constant: 14),
            self.image.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -14),
            self.label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
        ])
        return view
    }()

    private lazy var image: UIImageView = {
        let imageView = UIImageView(image: self.snackbarConfig.theme.images.icon.value)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),
        ])

        return imageView
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = self.snackbarConfig.text
        label.textColor = self.snackbarConfig.theme.colors.text.value
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(equalToConstant: 40),
        ])

        return label
    }()
}
