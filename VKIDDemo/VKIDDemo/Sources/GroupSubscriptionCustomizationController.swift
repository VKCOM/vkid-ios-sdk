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

import Foundation
import UIKit
import VKID

final class GroupSubscriptionCustomizationController: VKIDDemoViewController {
    lazy var config: GroupSubscriptionCustomization = .init(
        theme: .matchingColorScheme(.current),
        buttonHeight: .small(.h32),
        buttonCornerRadius: 0
    )

    private lazy var presentButton: UIButton = {
        let bt = UIButton(type: .system)
        bt.setTitle(
            "Present Sheet",
            for: .normal
        )
        bt.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        if #available(iOS 13.0, *) {
            bt.setTitleColor(.label, for: .normal)
        } else {
            bt.setTitleColor(.black, for: .normal)
        }
        bt.addTarget(
            self,
            action: #selector(self.onOpenSheet(sender:)),
            for: .touchUpInside
        )

        bt.translatesAutoresizingMaskIntoConstraints = false
        return bt
    }()

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var heightSegmentControlLabel: UILabel = {
        let label = UILabel()
        label.text = "Height"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var heightSegmentControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl()
        segmentControl.insertSegment(withTitle: ".small", at: 0, animated: false)
        segmentControl.insertSegment(withTitle: ".medium", at: 1, animated: false)
        segmentControl.insertSegment(withTitle: ".large", at: 2, animated: false)

        segmentControl.addTarget(self, action: #selector(self.heightSegmentControlChanged), for: .allEvents)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentControl
    }()

    var heightSliderLabelText: String {
        "Height \(Int(self.heightSlider.actualValue)) pt"
    }

    lazy var heightSliderLabel: UILabel = {
        let label = UILabel()
        label.text = self.heightSliderLabelText
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var heightSlider: StepSlider = {
        let slider = StepSlider(frame: .zero)
        slider.setup()
        slider.callback = { height in
            self.heightSliderChanged(height: CGFloat(height))
        }
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    var cornerRadiusLabelText: String {
        "Corner radius \(Int(self.cornerRadiusSlider.value)) pt"
    }

    lazy var cornerRadiusLabel: UILabel = {
        let label = UILabel()
        label.text = self.cornerRadiusLabelText
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var cornerRadiusSlider: UISlider = {
        let slider = UISlider()
        slider.addTarget(self, action: #selector(self.cornerRadiusSliderChanged), for: .allEvents)
        slider.minimumValue = 0
        slider.maximumValue = Float(self.config.buttonHeight.rawValue / 2)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    private func heightSliderChanged(height: CGFloat) {
        var layoutHeight: OneTapButton.Layout.Height = .small(.h32)

        if let height = OneTapButton.Layout.Height.Large(rawValue: height) {
            layoutHeight = .large(height)
        } else if let height = OneTapButton.Layout.Height.Medium(rawValue: height) {
            layoutHeight = .medium(height)
        } else if let height = OneTapButton.Layout.Height.Small(rawValue: height) {
            layoutHeight = .small(height)
        }

        self.config.buttonHeight = layoutHeight
        self.heightSliderLabel.text = self.heightSliderLabelText
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(
                equalTo: self.descriptionLabel.bottomAnchor
            ),
            self.scrollView.leadingAnchor.constraint(
                equalTo: self.view.leadingAnchor
            ),
            self.scrollView.trailingAnchor.constraint(
                equalTo: self.view.trailingAnchor
            ),
            self.scrollView.bottomAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.bottomAnchor
            ),
        ])
    }

    private func setupSettings() {
        self.view.addSubview(self.scrollView)
        self.scrollView.addSubview(self.contentView)

        self.contentView.addSubview(self.heightSegmentControlLabel)
        self.contentView.addSubview(self.heightSegmentControl)

        self.contentView.addSubview(self.heightSliderLabel)
        self.contentView.addSubview(self.heightSlider)

        self.contentView.addSubview(self.cornerRadiusLabel)
        self.contentView.addSubview(self.cornerRadiusSlider)
        self.contentView.addSubview(self.presentButton)

        NSLayoutConstraint.activate([
            self.contentView.topAnchor.constraint(
                equalTo: self.scrollView.topAnchor
            ),
            self.contentView.leadingAnchor.constraint(
                equalTo: self.scrollView.leadingAnchor
            ),
            self.contentView.trailingAnchor.constraint(
                equalTo: self.scrollView.trailingAnchor
            ),
            self.contentView.bottomAnchor.constraint(
                equalTo: self.scrollView.bottomAnchor
            ),

            self.contentView.widthAnchor.constraint(
                equalTo: self.scrollView.widthAnchor
            ),

            // MARK: - height segment control
            self.heightSegmentControlLabel.topAnchor.constraint(
                equalTo: self.contentView.topAnchor, constant: 16
            ),
            self.heightSegmentControlLabel.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.heightSegmentControlLabel.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.heightSegmentControlLabel.heightAnchor.constraint(
                equalToConstant: 30
            ),

            self.heightSegmentControl.topAnchor.constraint(
                equalTo: self.heightSegmentControlLabel.bottomAnchor, constant: 16
            ),
            self.heightSegmentControl.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.heightSegmentControl.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.heightSegmentControl.heightAnchor.constraint(
                equalToConstant: 30
            ),

            // MARK: - height slider
            self.heightSliderLabel.topAnchor.constraint(
                equalTo: self.heightSegmentControl.bottomAnchor, constant: 16
            ),
            self.heightSliderLabel.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.heightSliderLabel.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.heightSliderLabel.heightAnchor.constraint(
                equalToConstant: 30
            ),

            self.heightSlider.topAnchor.constraint(
                equalTo: self.heightSliderLabel.bottomAnchor, constant: 16
            ),
            self.heightSlider.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.heightSlider.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.heightSlider.heightAnchor.constraint(
                equalToConstant: 30
            ),

            // MARK: corner radius slider

            self.cornerRadiusLabel.topAnchor.constraint(
                equalTo: self.heightSlider.bottomAnchor, constant: 16
            ),
            self.cornerRadiusLabel.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.cornerRadiusLabel.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.cornerRadiusLabel.heightAnchor.constraint(
                equalToConstant: 30
            ),

            self.cornerRadiusSlider.topAnchor.constraint(
                equalTo: self.cornerRadiusLabel.bottomAnchor, constant: 16
            ),
            self.cornerRadiusSlider.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.cornerRadiusSlider.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.cornerRadiusSlider.heightAnchor.constraint(
                equalToConstant: 30
            ),

            self.presentButton.topAnchor.constraint(
                equalTo: self.cornerRadiusSlider.bottomAnchor, constant: 16
            ),
            self.presentButton.centerXAnchor.constraint(
                equalTo: self.contentView.centerXAnchor
            ),
            self.presentButton.bottomAnchor.constraint(
                equalTo: self.contentView.bottomAnchor, constant: -16
            ),
        ])

        self.heightSegmentControlChanged()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSettings()
        self.setupConstraints()
        self.view.setNeedsLayout()
    }

    @objc
    func cornerRadiusSliderChanged() {
        self.config.buttonCornerRadius = CGFloat(
            min(
                max(self.cornerRadiusSlider.minimumValue, self.cornerRadiusSlider.value),
                self.cornerRadiusSlider.maximumValue
            )
        )
        self.cornerRadiusLabel.text = self.cornerRadiusLabelText
    }

    @objc
    private func onOpenSheet(sender: AnyObject) {
        self.presentButton.isEnabled = false
        let sheetConfig = GroupSubscriptionSheet(
            subscribeToGroupId: self.debugSettings.groupId,
            buttonConfiguration: .init(
                height: self.config.buttonHeight,
                cornerRadius: self.config.buttonCornerRadius
            )
        ) { result in
            switch result {
            case .success:
                self.showAlert(message: "Успешная подписка")
            case .failure(let error):
                self.showAlert(message: "Не удалось подписаться: \(error)")
            }
        } accessTokenProvider: { force, completion in
            guard let session = self.vkid?.currentAuthorizedSession else {
                self.presentButton.isEnabled = true
                self.showAlert(message: "Нет сессии")
                return
            }
            session.getFreshAccessToken(forceRefresh: force) { result in
                self.presentButton.isEnabled = true
                switch result {
                case .success((let accessToken, _)):
                    completion(.success(accessToken.value))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        guard let vkid = self.vkid else { return }
        vkid.ui(for: sheetConfig).uiViewController { [weak self] result in
            self?.presentButton.isEnabled = true
            switch result {
            case .success(let viewController):
                self?.present(viewController, animated: true)
            case .failure(let error):
                self?.showAlert(message: "Не удалось создать шторку подписки: \(error)")
            }
        }
    }

    @objc
    func heightSegmentControlChanged() {
        var values: [Float] = []

        switch self.heightSegmentControl.selectedSegmentIndex {
        case 0:
            OneTapButton.Layout.Height.Small.allCases.forEach {
                values.append(Float($0.rawValue))
            }
        case 1:
            OneTapButton.Layout.Height.Medium.allCases.forEach {
                values.append(Float($0.rawValue))
            }
        case 2:
            OneTapButton.Layout.Height.Large.allCases.forEach {
                values.append(Float($0.rawValue))
            }
        default:
            break
        }

        self.heightSlider.values = values
        self.heightSlider.value = 0
        self.heightSlider.handleValueChange(sender: self.heightSlider)
    }
}

internal struct GroupSubscriptionCustomization {
    var theme: GroupSubscriptionSheet.Theme
    var buttonHeight: OneTapButton.Layout.Height
    var buttonCornerRadius: CGFloat
}
