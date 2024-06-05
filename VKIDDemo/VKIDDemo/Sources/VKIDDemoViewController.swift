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
import VKID

class VKIDDemoViewController: UIViewController {
    internal var navigationTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = label.textColor.withAlphaComponent(0.3)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    internal lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 24, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    internal lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    internal lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = label.textColor.withAlphaComponent(0.3)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    internal lazy var rightSideContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    internal lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var backgroundImage: UIImageView = {
        let image = UIImageView(
            image: UIImage(named: "brandLines")
        )
        image.contentMode = .scaleAspectFill
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    var vkid: VKID?

    var appearance: Appearance {
        get {
            self.vkid?.appearance ?? .init()
        }
        set {
            self.vkid?.appearance = newValue
        }
    }

    weak var debugSettingsVC: DebugSettingsViewController?

    var supportsScreenSplitting: Bool { false }
    var layoutType: LayoutType = .oneColumn

    var rightSideContentWidthConstraint: NSLayoutConstraint? = nil

    var oneColumnLayoutConstraints: [NSLayoutConstraint] = []
    var twoColumnLayoutConstraints: [NSLayoutConstraint] = []

    init(
        title: String,
        subtitle: String,
        description: String,
        navigationTitle: String? = nil
    ) {
        super.init(nibName: nil, bundle: nil)
        self.titleLabel.text = title
        self.subtitleLabel.text = subtitle
        self.descriptionLabel.text = description
        self.navigationTitleLabel.text = navigationTitle
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            self.view.backgroundColor = .systemBackground
        } else {
            self.view.backgroundColor = .white
        }
        self.navigationItem.titleView = self.navigationTitleLabel

        self.setupSubviews()
    }

    private func setupSubviews() {
        self.view.addSubview(self.backgroundImage)
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.subtitleLabel)
        self.view.addSubview(self.descriptionLabel)
        self.view.addSubview(self.rightSideContentView)
        self.view.addSubview(self.containerView)

        self.rightSideContentWidthConstraint = self.rightSideContentView.widthAnchor.constraint(
            equalToConstant: 0
        )
        self.rightSideContentWidthConstraint?.isActive = true

        if self.supportsScreenSplitting {
            self.updateRightSideConstraint(width: self.view.frame.width)
        }

        NSLayoutConstraint.activate([
            self.backgroundImage.topAnchor.constraint(
                equalTo: self.view.topAnchor
            ),
            self.backgroundImage.bottomAnchor.constraint(
                equalTo: self.view.bottomAnchor
            ),
            self.backgroundImage.leftAnchor.constraint(
                equalTo: self.view.leftAnchor
            ),
            self.backgroundImage.rightAnchor.constraint(
                equalTo: self.view.rightAnchor
            ),

            self.rightSideContentView.topAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.topAnchor
            ),
            self.rightSideContentView.trailingAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.trailingAnchor
            ),
            self.rightSideContentView.bottomAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.bottomAnchor
            ),

            self.titleLabel.topAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.topAnchor
            ),
            self.titleLabel.leadingAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            self.titleLabel.trailingAnchor.constraint(
                equalTo: self.rightSideContentView.safeAreaLayoutGuide.leadingAnchor,
                constant: -16
            ),

            self.subtitleLabel.topAnchor.constraint(
                greaterThanOrEqualTo: self.titleLabel.bottomAnchor
            ),
            self.subtitleLabel.topAnchor.constraint(
                lessThanOrEqualTo: self.titleLabel.bottomAnchor,
                constant: 16
            ),
            self.subtitleLabel.leadingAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            self.subtitleLabel.trailingAnchor.constraint(
                equalTo: self.rightSideContentView.safeAreaLayoutGuide.leadingAnchor,
                constant: -16
            ),

            self.descriptionLabel.topAnchor.constraint(
                greaterThanOrEqualTo: self.subtitleLabel.bottomAnchor
            ),
            self.descriptionLabel.topAnchor.constraint(
                lessThanOrEqualTo: self.subtitleLabel.bottomAnchor,
                constant: 8
            ),
            self.descriptionLabel.leadingAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            self.descriptionLabel.trailingAnchor.constraint(
                equalTo: self.rightSideContentView.safeAreaLayoutGuide.leadingAnchor,
                constant: -16
            ),

            self.containerView.topAnchor.constraint(
                equalTo: self.descriptionLabel.bottomAnchor
            ),
            self.containerView.leadingAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.leadingAnchor
            ),
            self.containerView.trailingAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.trailingAnchor
            ),
            self.containerView.bottomAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.bottomAnchor
            ),
        ])
    }

    override func updateViewConstraints() {
        if self.supportsScreenSplitting {
            switch self.layoutType {
            case .oneColumn:
                NSLayoutConstraint.deactivate(self.twoColumnLayoutConstraints)
                NSLayoutConstraint.activate(self.oneColumnLayoutConstraints)
            case .twoColumn:
                NSLayoutConstraint.deactivate(self.oneColumnLayoutConstraints)
                NSLayoutConstraint.activate(self.twoColumnLayoutConstraints)
            }
        }

        super.updateViewConstraints()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if self.supportsScreenSplitting {
            self.updateRightSideConstraint(width: size.width)
            self.view.setNeedsUpdateConstraints()
        }
    }

    private func updateRightSideConstraint(width: CGFloat) {
        let minWidthToDivide = 333.0
        let halfWidth = width / 2
        if halfWidth >= minWidthToDivide {
            self.rightSideContentWidthConstraint?.constant = halfWidth
            self.rightSideContentWidthConstraint?.isActive = true
            self.layoutType = .twoColumn
        } else {
            self.rightSideContentWidthConstraint?.isActive = false
            self.layoutType = .oneColumn
        }
    }
}

extension VKIDDemoViewController {
    enum LayoutType {
        case oneColumn
        case twoColumn
    }
}
