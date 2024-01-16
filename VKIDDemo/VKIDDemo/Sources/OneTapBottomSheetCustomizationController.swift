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

final class OneTapBottomSheetCustomizationController: VKIDDemoViewController,
    UIPickerViewDelegate,
    UITextFieldDelegate
{
    internal typealias TargetActionText = OneTapBottomSheet.TargetActionText

    private var oneTapButtonHeight: OneTapButton.Layout.Height = .medium()
    private var oneTapButtonCornerRadius: CGFloat {
        CGFloat(
            min(
                max(self.cornerRadiusSlider.minimumValue, self.cornerRadiusSlider.value),
                self.cornerRadiusSlider.maximumValue
            )
        )
    }

    private var targetActionTexts: [TargetActionText] {
        let serviceName = self.serviceName
        let texts: [TargetActionText] = [
            TargetActionText.applyFor,
            TargetActionText.orderCheckout,
            TargetActionText.registerForEvent,
            TargetActionText.signIn,
            TargetActionText.orderCheckoutAtService(serviceName),
            TargetActionText.signInToService(serviceName),
        ]
        return texts
    }

    private var serviceName: String = "\"Service Name\""

    private lazy var heightSegmentControlLabel: UILabel = {
        let label = UILabel()
        label.text = "Height"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var heightSegmentControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl()
        segmentControl.insertSegment(withTitle: ".small", at: 0, animated: false)
        segmentControl.insertSegment(withTitle: ".medium", at: 1, animated: false)
        segmentControl.insertSegment(withTitle: ".large", at: 2, animated: false)

        segmentControl.addTarget(self, action: #selector(self.heightSegmentControlChanged), for: .allEvents)
        segmentControl.selectedSegmentIndex = 1
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentControl
    }()

    private var heightSliderLabelText: String {
        "OneTapButton Height \(Int(self.heightSlider.actualValue)) pt"
    }

    private lazy var heightSliderLabel: UILabel = {
        let label = UILabel()
        label.text = self.heightSliderLabelText
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var heightSlider: StepSlider = {
        let slider = StepSlider(frame: .zero)
        slider.setup()
        slider.callback = { height in
            self.heightSliderChanged(height: CGFloat(height))
        }
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    private var cornerRadiusLabelText: String {
        "OneTapButton Corner radius \(Int(self.cornerRadiusSlider.value)) pt"
    }

    private lazy var cornerRadiusLabel: UILabel = {
        let label = UILabel()
        label.text = self.cornerRadiusLabelText
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var cornerRadiusSlider: UISlider = {
        let slider = UISlider()
        slider.addTarget(
            self,
            action: #selector(self.cornerRadiusSliderChanged),
            for: .allEvents
        )
        slider.minimumValue = 0
        slider.maximumValue = Float(0.5 * self.oneTapButtonHeight.rawValue)
        slider.value = 8
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    private lazy var serviceNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter Service Name"
        textField.font = .systemFont(ofSize: 16)
        textField.addTarget(self, action: #selector(self.onServiceNameChanged), for: .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.returnKeyType = UIReturnKeyType.done
        textField.delegate = self
        return textField
    } ()

    private lazy var pickerViewLabel: UILabel = {
        let label = UILabel()
        label.text = "Target action"
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var pickerView: PickerView = {
        let pickerView = PickerView(items: self.targetActionTexts)
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.delegate = self
        return pickerView
    } ()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.bounces = true
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var presentButton: UIButton = {
        let bt = UIButton(type: .system)
        bt.setTitle(
            "Present BottomSheet",
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
            action: #selector(self.onOpenOneTapSheet(sender:)),
            for: .touchUpInside
        )

        bt.translatesAutoresizingMaskIntoConstraints = false
        return bt
    }()

    private lazy var autoDismissSwitcherLabel: UILabel = {
        let label = UILabel()
        label.text = "Auto dismiss on auth success"
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var autoDismissSwitcher: UISwitch = {
        let switcher = UISwitch()
        switcher.isOn = true
        switcher.onTintColor = UIColor.azure
        switcher.translatesAutoresizingMaskIntoConstraints = false
        return switcher
    }()

    private lazy var oAuthListWidgetSwitcherLabel: UILabel = {
        let label = UILabel()
        label.text = "OAuthListWidget is enabled"
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var oAuthListWidgetSwitcher: UISwitch = {
        let switcher = UISwitch()
        switcher.isOn = false
        switcher.onTintColor = UIColor.azure
        switcher.translatesAutoresizingMaskIntoConstraints = false
        return switcher
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        self.addPresentBottomSheetButton()
        self.addContentView()
        self.addSettingsControls()
    }

    private func addPresentBottomSheetButton() {
        self.view.addSubview(self.presentButton)
        NSLayoutConstraint.activate([
            self.presentButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.presentButton.topAnchor.constraint(equalTo: self.descriptionLabel.bottomAnchor, constant: 32),
        ])
    }

    private func addContentView() {
        self.view.addSubview(self.scrollView)
        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: self.presentButton.bottomAnchor, constant: 32),
            self.scrollView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
        ])

        self.scrollView.addSubview(self.contentView)
        NSLayoutConstraint.activate([
            self.contentView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor),
            self.contentView.topAnchor.constraint(equalTo: self.scrollView.topAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor),
            self.contentView.widthAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.widthAnchor),
        ])
    }

    private func addSettingsControls() {
        self.heightSegmentControlChanged()

        self.contentView.addSubview(self.heightSegmentControlLabel)
        self.contentView.addSubview(self.heightSegmentControl)

        self.contentView.addSubview(self.heightSliderLabel)
        self.contentView.addSubview(self.heightSlider)

        self.contentView.addSubview(self.cornerRadiusLabel)
        self.contentView.addSubview(self.cornerRadiusSlider)

        self.contentView.addSubview(self.serviceNameTextField)

        self.contentView.addSubview(self.pickerViewLabel)
        self.contentView.addSubview(self.pickerView)

        self.contentView.addSubview(self.autoDismissSwitcherLabel)
        self.contentView.addSubview(self.autoDismissSwitcher)

        self.contentView.addSubview(self.oAuthListWidgetSwitcherLabel)
        self.contentView.addSubview(self.oAuthListWidgetSwitcher)

        NSLayoutConstraint.activate([
            self.heightSegmentControlLabel.topAnchor.constraint(
                equalTo: self.contentView.topAnchor
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

            self.serviceNameTextField.topAnchor.constraint(
                equalTo: self.cornerRadiusSlider.bottomAnchor, constant: 16
            ),
            self.serviceNameTextField.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.serviceNameTextField.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.serviceNameTextField.heightAnchor.constraint(
                equalToConstant: 30
            ),

            self.pickerViewLabel.topAnchor.constraint(
                equalTo: self.serviceNameTextField.bottomAnchor, constant: 16
            ),
            self.pickerViewLabel.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.pickerViewLabel.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.pickerViewLabel.heightAnchor.constraint(
                equalToConstant: 30
            ),

            self.pickerView.topAnchor.constraint(
                equalTo: self.pickerViewLabel.bottomAnchor, constant: 0
            ),
            self.pickerView.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.pickerView.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.pickerView.heightAnchor.constraint(
                equalToConstant: 70
            ),

            self.autoDismissSwitcher.topAnchor.constraint(
                equalTo: self.pickerView.bottomAnchor, constant: 16
            ),
            self.autoDismissSwitcher.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.autoDismissSwitcher.heightAnchor.constraint(
                equalToConstant: 30
            ),

            self.autoDismissSwitcherLabel.trailingAnchor.constraint(
                equalTo: self.autoDismissSwitcher.leadingAnchor, constant: -16
            ),
            self.autoDismissSwitcherLabel.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.autoDismissSwitcherLabel.centerYAnchor.constraint(
                equalTo: self.autoDismissSwitcher.centerYAnchor
            ),

            self.oAuthListWidgetSwitcher.topAnchor.constraint(
                equalTo: self.autoDismissSwitcher.bottomAnchor, constant: 16
            ),
            self.oAuthListWidgetSwitcher.trailingAnchor.constraint(
                equalTo: self.contentView.trailingAnchor, constant: -16
            ),
            self.oAuthListWidgetSwitcher.heightAnchor.constraint(
                equalToConstant: 30
            ),
            self.oAuthListWidgetSwitcher.bottomAnchor.constraint(
                equalTo: self.contentView.bottomAnchor, constant: -16
            ),

            self.oAuthListWidgetSwitcherLabel.trailingAnchor.constraint(
                equalTo: self.oAuthListWidgetSwitcher.leadingAnchor, constant: -16
            ),
            self.oAuthListWidgetSwitcherLabel.leadingAnchor.constraint(
                equalTo: self.contentView.leadingAnchor, constant: 16
            ),
            self.oAuthListWidgetSwitcherLabel.centerYAnchor.constraint(
                equalTo: self.oAuthListWidgetSwitcher.centerYAnchor
            ),
        ])
    }

    /// UIPickerViewDelegate

    func pickerView(
        _ pickerView: UIPickerView,
        viewForRow row: Int,
        forComponent component: Int,
        reusing view: UIView?
    ) -> UIView {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.text = self.targetActionTexts[row].title

        return label
    }

    /// UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

    /// Actions handling

    @objc
    private func onOpenOneTapSheet(sender: AnyObject) {
        let actionText = self.targetActionTexts[self.pickerView.selectedRow(inComponent: 0)]
        let onCompleteAuth: AuthResultCompletion = { [weak self] result in
            do {
                let session = try result.get()
                print("Auth succeeded with\n\(session)")
                self?.alertPresentationController.showAlert(message: session.debugDescription)
            } catch AuthError.cancelled {
                print("Auth cancelled by user")
            } catch {
                print("Auth failed with error: \(error)")
                self?.alertPresentationController.showAlert(message: "Ошибка авторизации")
            }
        }

        let sheet = OneTapBottomSheet(
            serviceName: self.serviceName,
            targetActionText: actionText,
            oneTapButton: .init(
                height: self.oneTapButtonHeight,
                cornerRadius: self.oneTapButtonCornerRadius
            ),
            alternativeOAuthProviders: self.oAuthListWidgetSwitcher.isOn ?
                [.mail, .ok] : [],
            autoDismissOnSuccess: self.autoDismissSwitcher.isOn,
            onCompleteAuth: onCompleteAuth
        )

        let controller = self.vkid?.ui(for: sheet).uiViewController()
        if let controller {
            self.present(controller, animated: true)
        }
    }

    private var alertPresentationController: UIViewController {
        self.presentedViewController ?? self
    }

    @objc
    private func heightSegmentControlChanged() {
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
        self.heightSlider.value = 2
        self.heightSlider.handleValueChange(sender: self.heightSlider)
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

        self.oneTapButtonHeight = layoutHeight
        self.heightSliderLabel.text = self.heightSliderLabelText
        self.cornerRadiusSlider.maximumValue = Float(0.5 * self.oneTapButtonHeight.rawValue)
    }

    @objc
    private func cornerRadiusSliderChanged() {
        self.cornerRadiusLabel.text = self.cornerRadiusLabelText
    }

    @objc
    private func onServiceNameChanged() {
        self.serviceName = (self.serviceNameTextField.text ?? "").isEmpty
            ? "\"Service Name\""
            : self.serviceNameTextField.text!
        self.pickerView.items = self.targetActionTexts
        self.pickerView.reloadComponent(0)
    }

    @objc
    func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
            as? CGRect else { return }
        let keyboardHeight = keyboardSize.height - self.view.safeAreaInsets.bottom

        self.scrollView.contentInset.bottom = keyboardHeight
        self.scrollView.scrollRectToVisible(self.serviceNameTextField.frame, animated: true)
    }

    @objc
    func keyboardWillHide(notification: NSNotification) {
        self.scrollView.contentInset.bottom = 0
    }
}
