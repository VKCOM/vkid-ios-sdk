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

final class ControlsViewController: VKIDDemoViewController, UITableViewDataSource, UITableViewDelegate {
    private enum Cells: String, CaseIterable {
        case oneTapButton = "OneTapButton"
        case oneTapBottomSheet = "OneTapBottomSheet"
        case oAuthListWidget = "OAuthListWidget"
        case groupSubscriptionSheet = "GroupSubscriptionSheet"
        case captcha = "Captcha"
    }

    override var supportsScreenSplitting: Bool { true }

    private lazy var controlsTableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: String(describing: UITableViewCell.self)
        )
        tableView.backgroundColor = .clear

        tableView.translatesAutoresizingMaskIntoConstraints = false

        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.controlsTableView)
        self.setupConstraints()
    }

    private func setupConstraints() {
        self.twoColumnLayoutConstraints = [
            self.controlsTableView.topAnchor.constraint(equalTo: self.rightSideContentView.topAnchor),
            self.controlsTableView.leadingAnchor
                .constraint(equalTo: self.rightSideContentView.leadingAnchor),
            self.controlsTableView.trailingAnchor
                .constraint(equalTo: self.rightSideContentView.trailingAnchor),
            self.controlsTableView.bottomAnchor
                .constraint(equalTo: self.rightSideContentView.bottomAnchor),
        ]
        self.oneColumnLayoutConstraints = [
            self.controlsTableView.topAnchor.constraint(
                equalTo: self.descriptionLabel.bottomAnchor,
                constant: 8
            ),
            self.controlsTableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.controlsTableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.controlsTableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
        ]
    }

    override func updateViewConstraints() {
        switch self.layoutType {
        case .oneColumn:
            NSLayoutConstraint.deactivate(self.twoColumnLayoutConstraints)
            NSLayoutConstraint.activate(self.oneColumnLayoutConstraints)
        case .twoColumn:
            NSLayoutConstraint.deactivate(self.oneColumnLayoutConstraints)
            NSLayoutConstraint.activate(self.twoColumnLayoutConstraints)
        }
        super.updateViewConstraints()
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Cells.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: UITableViewCell.self),
            for: indexPath
        )
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        cell.textLabel?.text = Cells.allCases[indexPath.row].rawValue
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch Cells.allCases[indexPath.row] {
        case .oneTapButton:
            let controller = OneTapButtonCustomizationController(
                title: "Кастомизация",
                subtitle: "OneTapButton",
                description: "Нажмите на кнопку, чтобы включить или выключить анимацию",
                debugSettings: self.debugSettings,
                api: self.api
            )
            controller.vkid = self.vkid
            self.navigationController?.pushViewController(
                controller,
                animated: true
            )
        case .oneTapBottomSheet:
            let controller = OneTapBottomSheetCustomizationController(
                title: "Кастомизация",
                subtitle: "OneTapBottomSheet",
                description: "Настройте параметры конфигурации",
                debugSettings: self.debugSettings,
                api: self.api
            )
            controller.vkid = self.vkid
            controller.debugSettings = self.debugSettings
            self.navigationController?.pushViewController(
                controller,
                animated: true
            )
        case .oAuthListWidget:
            let controller = OAuthListWidgetCustomizationController(
                title: "Кастомизация",
                subtitle: "OAuthListWidget",
                description: "Настройте параметры конфигурации",
                debugSettings: self.debugSettings,
                api: self.api
            )
            controller.vkid = self.vkid
            controller.debugSettings = self.debugSettings
            self.navigationController?.pushViewController(
                controller,
                animated: true
            )
        case .groupSubscriptionSheet:
            let controller = GroupSubscriptionCustomizationController(
                title: "Кастомизация",
                subtitle: "GroupSubscriptionSheet",
                description: "Настройте параметры конфигурации",
                debugSettings: self.debugSettings,
                api: self.api
            )
            controller.vkid = self.vkid
            controller.debugSettings = self.debugSettings
            self.navigationController?.pushViewController(
                controller,
                animated: true
            )
        case .captcha:
            let controller = CaptchaViewController(
                title: "Captcha",
                subtitle: "VKCaptchaHandler",
                description: "Пройдите капчу",
                debugSettings: self.debugSettings,
                api: self.api
            )
            controller.vkid = self.vkid
            controller.debugSettings = self.debugSettings
            self.navigationController?.pushViewController(
                controller,
                animated: true
            )
        }
    }
}
