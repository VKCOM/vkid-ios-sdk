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

final class UserSessionsViewController: VKIDDemoViewController, UITableViewDataSource, UITableViewDelegate {
    override var supportsScreenSplitting: Bool { true }

    private lazy var sessionsTableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            UserSessionInfoTableViewCell.self,
            forCellReuseIdentifier: UserSessionInfoTableViewCell.Constants.identifier
        )
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false

        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.vkid?.add(observer: self)

        self.view.addSubview(self.sessionsTableView)
        self.setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.sessionsTableView.reloadData()
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

    private func setupConstraints() {
        self.twoColumnLayoutConstraints = [
            self.sessionsTableView.topAnchor.constraint(equalTo: self.rightSideContentView.topAnchor),
            self.sessionsTableView.leadingAnchor
                .constraint(equalTo: self.rightSideContentView.leadingAnchor),
            self.sessionsTableView.trailingAnchor
                .constraint(equalTo: self.rightSideContentView.trailingAnchor),
            self.sessionsTableView.bottomAnchor
                .constraint(equalTo: self.rightSideContentView.bottomAnchor),
        ]
        self.oneColumnLayoutConstraints = [
            self.sessionsTableView.topAnchor.constraint(
                equalTo: self.descriptionLabel.bottomAnchor,
                constant: 8
            ),
            self.sessionsTableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.sessionsTableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.sessionsTableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
        ]
    }

    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        "Логаут"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        vkid?.authorizedSessions.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let session = vkid?.authorizedSessions[indexPath.row],
            let cell = tableView.dequeueReusableCell(
                withIdentifier: UserSessionInfoTableViewCell.Constants.identifier,
                for: indexPath
            ) as? UserSessionInfoTableViewCell
        else {
            return UITableViewCell()
        }

        cell.apply(session: session)

        return cell
    }

    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete, let session = vkid?.authorizedSessions[indexPath.row] {
            self.logout(from: session) { [indexPath] in
                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.endUpdates()
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let userSession = vkid?.authorizedSessions[indexPath.row] else { return }

        self.presentActionSheet(for: userSession)
    }

    private func logout(from session: UserSession, completion: @escaping () -> Void) {
        session.logout { result in
            switch result {
            case .success():
                DispatchQueue.main.async { completion() }
            default: break
            }
        }
    }

    private func presentActionSheet(for session: UserSession) {
        let alertViewController = UIAlertController(
            title: "Действия над сессией",
            message: "Выберите действия, которые хотите выполнить над сессией",
            preferredStyle: .actionSheet
        )
        alertViewController.addAction(
            UIAlertAction(
                title: "Логаут",
                style: .destructive
            ) { [weak self] _ in
                self?.logout(from: session) {
                    self?.sessionsTableView.reloadData()
                }
            }
        )
        alertViewController.addAction(
            UIAlertAction(
                title: "Отменить",
                style: .cancel
            )
        )

        self.present(alertViewController, animated: true)
    }

    private func presentAlert(title: String, message: String) {
        let alertViewController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alertViewController.addAction(
            UIAlertAction(title: "Ок", style: .cancel)
        )
        self.present(alertViewController, animated: true)
    }
}

extension UserSessionsViewController: VKIDObserver {
    func vkid(_ vkid: VKID, didStartAuthUsing oAuth: OAuthProvider) {}
    func vkid(_ vkid: VKID, didCompleteAuthWith result: AuthResult, in oAuth: OAuthProvider) {}

    func vkid(_ vkid: VKID, didLogoutFrom session: UserSession, with result: LogoutResult) {
        switch result {
        case .success(()):
            self.presentAlert(
                title: "Логаут выполнен успешно",
                message: "Пользователь, для которого был выполнен логаут \(session.user.id.value)"
            )
        case .failure(let error):
            self.presentAlert(
                title: "Логаут не выполнен",
                message: "Не удалось выполнить логаут для пользователя \(session.user.id.value)\nПричина: \(error)"
            )
        }
    }
}
