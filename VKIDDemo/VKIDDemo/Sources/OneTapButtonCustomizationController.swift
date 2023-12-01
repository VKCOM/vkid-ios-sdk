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
import VKID

final class OneTapButtonCustomizationController: VKIDDemoViewController {
    var config: OneTapButtonConfiguration = .init(
        oneTapButtonStyle: .primary(),
        oneTapButtonTheme: .matchingColorScheme(.system),
        oneTapButtonHeight: .large(.h48),
        oneTapButtonCornerRadius: 5,
        oneTapButtonKind: .regular
    )

    var oneTapButton: UIView? {
        let control = vkid?.ui(for: self.config.oneTapButton).uiView()
        control?.translatesAutoresizingMaskIntoConstraints = false
        return control
    }

    var currentButton: UIView?

    lazy var measureLabel: UILabel = {
        let label = UILabel()
        label.text = "Measure"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var measureSwitcherLabel: UILabel = {
        let label = UILabel()
        label.text = "Show measure"
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var measureSwitcher: UISwitch = {
        let switcher = UISwitch()
        switcher.isOn = true
        switcher.onTintColor = UIColor.azure
        switcher.addTarget(self, action: #selector(self.measureSwitcherChanged), for: .valueChanged)
        switcher.translatesAutoresizingMaskIntoConstraints = false
        return switcher
    }()

    lazy var styleSegmentControlLabel: UILabel = {
        let label = UILabel()
        label.text = "Style"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var styleSegmentControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl()
        segmentControl.insertSegment(withTitle: ".primary", at: 0, animated: false)
        segmentControl.insertSegment(withTitle: ".secondary", at: 1, animated: false)

        segmentControl.addTarget(self, action: #selector(self.styleSegmentControlChanged), for: .allEvents)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentControl
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

    lazy var layoutLabel: UILabel = {
        let label = UILabel()
        label.text = "Layout"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var kindSegmentControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl()
        segmentControl.insertSegment(withTitle: ".regular", at: 0, animated: false)
        segmentControl.insertSegment(withTitle: ".logoOnly", at: 1, animated: false)

        segmentControl.addTarget(self, action: #selector(self.kindSegmentControlChanged), for: .valueChanged)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentControl
    }()

    var widthSliderLabelText: String {
        "Width \(Int(self.widthSlider.value)) pt"
    }

    lazy var widthSliderLabel: UILabel = {
        let label = UILabel()
        label.text = self.widthSliderLabelText
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var widthSlider: UISlider = {
        let slider = UISlider()
        slider.addTarget(self, action: #selector(self.widthSliderChanged), for: .allEvents)
        slider.minimumValue = 32
        slider.maximumValue = Float(self.view.frame.width) - 32
        slider.value = 300
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
        slider.maximumValue = Float(self.currentButton?.frame.height ?? 0)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    var measureView: MeasureView = {
        let debugView = MeasureView()
        debugView.translatesAutoresizingMaskIntoConstraints = false
        return debugView
    }()

    var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.setupSettings()
        self.updateOneTapButton()

        self.view.setNeedsLayout()
    }

    @objc
    func measureSwitcherChanged() {
        self.measureView.isHidden = !self.measureSwitcher.isOn
    }

    @objc
    func kindSegmentControlChanged() {
        switch self.kindSegmentControl.selectedSegmentIndex {
        case 0:
            self.widthSlider.alpha = 1.0
            self.widthSlider.isUserInteractionEnabled = true
            self.config.oneTapButtonKind = .regular
        case 1:
            self.widthSlider.alpha = 0.4
            self.widthSlider.isUserInteractionEnabled = false
            self.config.oneTapButtonKind = .logoOnly
        default:
            break
        }

        self.updateOneTapButton()
    }

    @objc
    func styleSegmentControlChanged() {
        switch self.styleSegmentControl.selectedSegmentIndex {
        case 0:
            self.config.oneTapButtonStyle = .primary()
        case 1:
            self.config.oneTapButtonStyle = .secondary()
        default:
            break
        }

        self.updateOneTapButton()
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

    @objc
    func widthSliderChanged() {
        self.widthSlider.value = ceil(self.widthSlider.value)
        self.widthSliderLabel.text = self.widthSliderLabelText
        self.updateOneTapButton()
    }

    @objc
    func cornerRadiusSliderChanged() {
        self.config.oneTapButtonCornerRadius = CGFloat(
            min(
                max(self.cornerRadiusSlider.minimumValue, self.cornerRadiusSlider.value),
                self.cornerRadiusSlider.maximumValue
            )
        )
        self.cornerRadiusLabel.text = self.cornerRadiusLabelText

        self.updateOneTapButton()
    }

    private func heightSliderChanged(height: CGFloat) {
        var layoutHeight: OneTapButton.Layout.Height = .small(.h32)

        if let height = OneTapButton.Layout.Height.Large(rawValue: height) {
            layoutHeight = .large(height)
        } else if let height = OneTapButton.Layout.Height.Medium(rawValue: height) {
            layoutHeight = .medium(height)
        } else if let height = OneTapButton.Layout.Height.Small(rawValue: height) {
            layoutHeight = .small(height)
        }

        self.config.oneTapButtonHeight = layoutHeight
        self.heightSliderLabel.text = self.heightSliderLabelText
        self.updateOneTapButton()
    }

    private func updateConfigurationSettings() {
        if let button = self.currentButton {
            self.cornerRadiusSlider.maximumValue = Float(
                min(
                    button.frame.size.height / 2,
                    button.frame.size.width / 2
                )
            )
        }
        self.config.oneTapButtonCornerRadius = CGFloat(
            min(
                max(self.cornerRadiusSlider.minimumValue, self.cornerRadiusSlider.value),
                self.cornerRadiusSlider.maximumValue
            )
        )
    }

    private func updateOneTapButton() {
        self.updateConfigurationSettings()

        self.currentButton?.removeFromSuperview()

        guard let oneTapButton = self.oneTapButton else { return }

        self.currentButton = oneTapButton
        oneTapButton.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(oneTapButton)

        NSLayoutConstraint.activate([
            oneTapButton.topAnchor.constraint(equalTo: self.descriptionLabel.bottomAnchor, constant: 64),
            oneTapButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            oneTapButton.widthAnchor.constraint(equalToConstant: CGFloat(self.widthSlider.value)),
        ])

        oneTapButton.layoutIfNeeded()

        self.measureView.targetView = oneTapButton
    }

    private func setupSettings() {
        self.heightSegmentControlChanged()

        self.view.addSubview(self.scrollView)
        self.view.addSubview(self.measureView)

        self.scrollView.addSubview(self.contentView)

        self.contentView.addSubview(self.measureLabel)
        self.contentView.addSubview(self.measureSwitcher)
        self.contentView.addSubview(self.measureSwitcherLabel)

        self.contentView.addSubview(self.styleSegmentControl)
        self.contentView.addSubview(self.styleSegmentControlLabel)

        self.contentView.addSubview(self.heightSegmentControlLabel)
        self.contentView.addSubview(self.heightSegmentControl)

        self.contentView.addSubview(self.heightSliderLabel)
        self.contentView.addSubview(self.heightSlider)

        self.contentView.addSubview(self.kindSegmentControl)
        self.contentView.addSubview(self.layoutLabel)

        self.contentView.addSubview(self.widthSliderLabel)
        self.contentView.addSubview(self.widthSlider)

        self.contentView.addSubview(self.cornerRadiusLabel)
        self.contentView.addSubview(self.cornerRadiusSlider)

        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(
                equalTo: self.descriptionLabel.bottomAnchor, constant: 164
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

            // MARK: - measure switcher
            self.measureLabel.topAnchor.constraint(
                equalTo: self.contentView.topAnchor, constant: 16
            ),
            self.measureLabel.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.measureLabel.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),

            self.measureSwitcher.topAnchor.constraint(
                equalTo: self.measureLabel.bottomAnchor, constant: 16
            ),
            self.measureSwitcher.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.measureSwitcher.heightAnchor.constraint(
                equalToConstant: 30
            ),

            self.measureSwitcherLabel.trailingAnchor.constraint(
                equalTo: self.measureSwitcher.leadingAnchor, constant: -16
            ),
            self.measureSwitcherLabel.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.measureSwitcherLabel.centerYAnchor.constraint(
                equalTo: self.measureSwitcher.centerYAnchor
            ),

            // MARK: - style swithcer

            self.styleSegmentControlLabel.topAnchor.constraint(
                equalTo: self.measureSwitcherLabel.bottomAnchor, constant: 64
            ),
            self.styleSegmentControlLabel.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.styleSegmentControlLabel.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.styleSegmentControlLabel.heightAnchor.constraint(
                equalToConstant: 30
            ),

            self.styleSegmentControl.topAnchor.constraint(
                equalTo: self.styleSegmentControlLabel.bottomAnchor, constant: 16
            ),
            self.styleSegmentControl.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.styleSegmentControl.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.styleSegmentControl.heightAnchor.constraint(
                equalToConstant: 30
            ),

            // MARK: - height segment control
            self.heightSegmentControlLabel.topAnchor.constraint(
                equalTo: self.styleSegmentControl.bottomAnchor, constant: 64
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

            // MARK: - width switcher

            self.layoutLabel.topAnchor.constraint(
                equalTo: self.heightSlider.bottomAnchor, constant: 64
            ),
            self.layoutLabel.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.layoutLabel.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.layoutLabel.heightAnchor.constraint(
                equalToConstant: 30
            ),

            self.kindSegmentControl.topAnchor.constraint(
                equalTo: self.layoutLabel.bottomAnchor, constant: 16
            ),
            self.kindSegmentControl.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.kindSegmentControl.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.kindSegmentControl.heightAnchor.constraint(
                equalToConstant: 30
            ),

            // MARK: corner radius slider

            self.cornerRadiusLabel.topAnchor.constraint(
                equalTo: self.kindSegmentControl.bottomAnchor, constant: 16
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

            // MARK: - width slider

            self.widthSliderLabel.topAnchor.constraint(
                equalTo: self.cornerRadiusSlider.bottomAnchor, constant: 16
            ),
            self.widthSliderLabel.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.widthSliderLabel.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.widthSliderLabel.heightAnchor.constraint(
                equalToConstant: 30
            ),

            self.widthSlider.topAnchor.constraint(
                equalTo: self.widthSliderLabel.bottomAnchor, constant: 16
            ),
            self.widthSlider.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.widthSlider.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.widthSlider.heightAnchor.constraint(
                equalToConstant: 30
            ),
            self.widthSlider.bottomAnchor.constraint(
                equalTo: self.contentView.bottomAnchor, constant: -16
            ),
        ])
    }
}

internal struct OneTapButtonConfiguration {
    var oneTapButtonStyle: OneTapButton.Appearance.Style

    var oneTapButtonTheme: OneTapButton.Appearance.Theme

    var oneTapButtonHeight: OneTapButton.Layout.Height

    var oneTapButtonCornerRadius: CGFloat

    var oneTapButtonKind: OneTapButton.Layout.Kind

    var oneTapButton: OneTapButton {
        OneTapButton(
            appearance: self.oneTapButtonAppearance,
            layout: self.oneTapButtonLayout
        ) { control in
            if control.isAnimating {
                control.stopAnimating()
            } else {
                control.startAnimating()
            }
        }
    }

    var oneTapButtonAppearance: OneTapButton.Appearance {
        OneTapButton.Appearance(
            style: self.oneTapButtonStyle,
            theme: self.oneTapButtonTheme
        )
    }

    var oneTapButtonLayout: OneTapButton.Layout {
        OneTapButton.Layout(
            kind: self.oneTapButtonKind,
            height: self.oneTapButtonHeight,
            cornerRadius: self.oneTapButtonCornerRadius
        )
    }
}
