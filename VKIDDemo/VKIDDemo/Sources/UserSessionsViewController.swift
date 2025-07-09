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
        2
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        if indexPath.section == 0 {
            guard let session = vkid?.authorizedSessions[indexPath.row] else {
                return UISwipeActionsConfiguration(actions: [])
            }
            return UISwipeActionsConfiguration(actions: [
                self.action(tableView: tableView,
                            title: "Инфо",
                            session: session,
                            color: UIColor.lightGray,
                            handler: self.show(session:completion:)),
                self.action(tableView: tableView,
                            title: "Обновить данные",
                            session: session,
                            color: UIColor.azure,
                            handler: self.fetchUser(in:completion:)),
                self.action(tableView: tableView,
                            title: "Обновить токен",
                            session: session,
                            color: UIColor.systemGreen)
                { session, completion in
                    session.getFreshAccessToken(forceRefresh: true) { [weak self] result in
                        self?.handleRefresh(session: session, result: result)
                        tableView.reloadData()
                    }
                },
                self.action(tableView: tableView,
                            title: "Логаут",
                            session: session,
                            color: UIColor.systemRed,
                            handler: self.logout(from:completion:)),
            ])
        } else {
            guard let legacySession = vkid?.legacyAuthorizedSessions[indexPath.row] else {
                return UISwipeActionsConfiguration(actions: [])
            }
            var actions = [
                self.action(tableView: tableView,
                            title: "Логаут",
                            session: legacySession,
                            color: UIColor.systemRed,
                            handler: self.logout(from:completion:)),
            ]
            if !self.debugSettings.confidentialFlowEnabled {
                let migrationAction = UIContextualAction(
                    style: .normal,
                    title: "Мигрировать в OAuth2"
                ) { _,_,_ in
                    self.migrate(legacySession: legacySession)
                }
                migrationAction.backgroundColor = .azure
                actions.append(migrationAction)
            }
            return UISwipeActionsConfiguration(actions: actions)
        }
    }

    private func migrate(legacySession: LegacyUserSession) {
        var secrets: PKCESecrets?
        if self.debugSettings.providedPKCESecretsEnabled {
            guard let authSecrets = try? PKCESecrets() else {
                fatalError("PKCE secrets not generated")
            }
            secrets = authSecrets
            print("PKCE Secrets: \(authSecrets)")
        }
        self.vkid?
            .oAuth2MigrationManager
            .migrate(
                from: legacySession,
                secrets: secrets
            ) { [weak self] result in
                self?.sessionsTableView.reloadData()
                self?.handleMigration(
                    result: result,
                    legacyAccessToken: legacySession.accessToken.value
                )
            }
    }

    private func action(
        tableView: UITableView,
        title: String,
        session: UserSession,
        color: UIColor,
        handler: @escaping (UserSession, @escaping () -> Void) -> Void
    ) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: title) { _,_,_ in
            handler(session) {
                tableView.reloadData()
            }
        }
        action.backgroundColor = color
        return action
    }

    private func action(
        tableView: UITableView,
        title: String,
        session: LegacyUserSession,
        color: UIColor,
        handler: @escaping (LegacyUserSession, @escaping () -> Void) -> Void
    ) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: title) { _,_,_ in
            handler(session) {
                tableView.reloadData()
            }
        }
        action.backgroundColor = color
        return action
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ?
            vkid?.authorizedSessions.count ?? 0 :
            vkid?.legacyAuthorizedSessions.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let vkid,
            let cell = tableView.dequeueReusableCell(
                withIdentifier: UserSessionInfoTableViewCell.Constants.identifier,
                for: indexPath
            ) as? UserSessionInfoTableViewCell
        else {
            return UITableViewCell()
        }
        let sessionData: SessionData = indexPath.section == 0 ?
            .init(from: vkid.authorizedSessions[indexPath.row]) :
            .init(from: vkid.legacyAuthorizedSessions[indexPath.row])
        cell.apply(session: sessionData)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            guard let userSession = vkid?.authorizedSessions[indexPath.row] else { return }
            self.presentActionSheet(for: userSession)
        } else {
            guard let legacySession = vkid?.legacyAuthorizedSessions[indexPath.row] else { return }
            self.presentActionSheet(for: legacySession)
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Sessions:" : "Legacy sessions:"
    }

    func presentActionSheet(for legacySession: LegacyUserSession) {
        let alertViewController = UIAlertController(
            title: "Действия над устаревшей сессией",
            message: "Выберите действия, которые хотите выполнить над сессией",
            preferredStyle: .actionSheet
        )
        if !self.debugSettings.confidentialFlowEnabled {
            alertViewController.addAction(
                UIAlertAction(
                    title: "Мигрировать в OAuth2",
                    style: .default
                ) { [weak self] _ in
                    self?.migrate(legacySession: legacySession)
                }
            )
        }
        alertViewController.addAction(
            UIAlertAction(
                title: "Логаут",
                style: .destructive
            ) { [weak self] _ in
                legacySession.logout { result in
                    self?.sessionsTableView.reloadData()
                    self?.handleLegacyLogout(
                        legacySession: legacySession,
                        result: result
                    )
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

    private func presentActionSheet(for session: UserSession) {
        let alertViewController = UIAlertController(
            title: "Действия над сессией",
            message: "Выберите действия, которые хотите выполнить над сессией",
            preferredStyle: .actionSheet
        )
        alertViewController.addAction(
            UIAlertAction(
                title: "Информация о сессии",
                style: .default
            ) { [weak self] _ in
                self?.show(session: session) {
                    self?.sessionsTableView.reloadData()
                }
            }
        )
        alertViewController.addAction(
            UIAlertAction(
                title: "Обновить токен",
                style: .default
            ) { [weak self] _ in
                self?.refreshToken(in: session) { result in
                    self?.handleRefresh(session: session, result: result)
                    self?.sessionsTableView.reloadData()
                }
            }
        )
        alertViewController.addAction(
            UIAlertAction(
                title: "Oбновить данные",
                style: .default
            ) { [weak self] _ in
                self?.fetchUser(in: session) {
                    self?.sessionsTableView.reloadData()
                }
            }
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
        if let popoverController = alertViewController.popoverPresentationController {
            popoverController.sourceView = self.view // to set the source of your alert
            popoverController.sourceRect = CGRect(
                x: self.view.bounds.midX,
                y: self.view.bounds.midY,
                width: 0,
                height: 0
            ) // you can set this as per your requirement.
            popoverController.permittedArrowDirections = [] // to hide the arrow of any particular direction
        }

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

    private func logout(from legacySession: LegacyUserSession, completion: @escaping () -> Void) {
        legacySession.logout { [weak self] result in
            self?.sessionsTableView.reloadData()
            self?.handleLegacyLogout(
                legacySession: legacySession,
                result: result
            )
        }
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

    private func refreshToken(in session: UserSession, completion: @escaping (TokenRefreshingResult) -> Void) {
        session.getFreshAccessToken(forceRefresh: true) { result in
            if case .success = result {
                DispatchQueue.main.async { completion(result) }
            }
        }
    }

    private func fetchUser(in session: UserSession, completion: @escaping () -> Void) {
        session.fetchUser { result in
            switch result {
            case .success:
                DispatchQueue.main.async { completion() }
            default: break
            }
        }
    }

    private func show(session: UserSession, completion: @escaping () -> Void) {
        self.showAlert(message: session.debugDescription, completion: completion)
    }

    private func handleMigration(
        result: Result<UserSession, OAuth2MigrationError>,
        legacyAccessToken: String
    ) {
        switch result {
        case .success(let session):
            self.presentAlert(
                title: "Миграция выполнена успешно",
                message: "Пользователь, для которого была выполнена миграция \(session.userId.value)"
            )
        case.failure(let error):
            self.presentAlert(
                title: "Не удалось выполнить миграцию",
                message: """
                    Не удалось выполнить миграцию для токена '\(legacyAccessToken.prefix(10))...'
                    Причина: \(error)
                    """
            )
        }
    }

    private func handleRefresh(
        session: UserSession,
        result: TokenRefreshingResult
    ) {
        switch result {
        case .success((_,_)):
            self.presentAlert(
                title: "Обновление токенов выполнено успешно",
                message: "Пользователь, для которого было выполнено обновление токенов \(session.userId.value)"
            )
        case .failure(let error):
            self.presentAlert(
                title: "Не удалось обновить токены",
                message: "Не удалось обновить токены для пользователя \(session.userId.value)\nПричина: \(error)"
            )
        }
    }

    private func handleLegacyLogout(legacySession: LegacyUserSession, result: LogoutResult) {
        switch result {
        case .success:
            self.presentAlert(
                title: "Логаут устаревшей сессии выполнен успешно",
                message: "Пользователь, для которого был выполнен логаут \(legacySession.accessToken.userId.value)"
            )
        case.failure(let error):
            let message = """
                Не удалось выполнить логаут для пользователя \(legacySession.accessToken.userId.value).
                Причина: \(error)"
                """
            self.presentAlert(
                title: "Логаут устаревшей сессии не выполнен",
                message: message
            )
        }
    }
}

extension UserSessionsViewController: VKIDObserver {
    func vkid(
        _ vkid: VKID,
        didUpdateUserIn session: UserSession,
        with result: UserFetchingResult
    ) {
        switch result {
        case .success:
            self.presentAlert(
                title: "Обновление данных выполнено успешно",
                message: "Пользователь, для которого было выполнено обновление данных \(session.userId.value)"
            )
        case .failure(let error):
            self.presentAlert(
                title: "Не удалось обновить данные",
                message: "Не удалось обновить данные пользователя \(session.userId.value)\nПричина: \(error)"
            )
        }
    }

    func vkid(_ vkid: VKID, didRefreshAccessTokenIn session: UserSession, with result: TokenRefreshingResult) {
        switch result {
        case .success:
            print("successfully refreshed tokens for: \(session.userId.value)")
        case .failure(let error):
            print("failed refresh token for \(session.userId.value): \(error)")
        }
    }

    func vkid(_ vkid: VKID, didStartAuthUsing oAuth: OAuthProvider) {}
    func vkid(_ vkid: VKID, didCompleteAuthWith result: AuthResult, in oAuth: OAuthProvider) {}

    func vkid(_ vkid: VKID, didLogoutFrom session: UserSession, with result: LogoutResult) {
        switch result {
        case .success(()):
            self.presentAlert(
                title: "Логаут выполнен успешно",
                message: "Пользователь, для которого был выполнен логаут \(session.userId.value)"
            )
        case .failure(let error):
            self.presentAlert(
                title: "Логаут не выполнен",
                message: "Не удалось выполнить логаут для пользователя \(session.userId.value)\nПричина: \(error)"
            )
        }
    }
}
