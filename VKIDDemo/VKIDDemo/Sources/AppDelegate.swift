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

import VKCaptchaSDK
// Only for debug purposes. Do not use in your projects.
@_spi(VKIDPrivate)
@_spi(VKIDDebug)
import VKID
import VKIDCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var vkid: VKID?
    var window: UIWindow?

    private let debugSettings = DebugSettingsStorage()

    var api: API?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        guard
            let clientId = InfoPlist.clientId, !clientId.isEmpty,
            let clientSecret = InfoPlist.clientSecret, !clientSecret.isEmpty
        else {
            preconditionFailure("Info.plist does not contain correct values for CLIENT_ID and CLIENT_SECRET keys")
        }

        do {
            try VKID.shared.set(
                config: Configuration(
                    appCredentials: AppCredentials(
                        clientId: clientId,
                        clientSecret: clientSecret
                    ),
                    appearance: .init(
                        locale: .init(
                            rawValue: self.debugSettings.currentLanguageCode ?? ""
                        ) ?? .system
                    ),
                    loggingEnabled: self.debugSettings.loggingEnabled,
                    wrapperSDK: self.debugSettings.flutterFlagEnabled ? .flutter : .none,
                    // Only for debug purposes
                    network: NetworkConfiguration(
                        isSSLPinningEnabled: self.debugSettings.isSSLPinningEnabled,
                        customDomainTemplate: self.debugSettings.customDomainTemplate
                    ),
                    groupSubscriptionsLimit:
                    self.debugSettings.groupSubscriptionsLimitEnabled ?
                        GroupSubscriptionsLimit(
                            maxSubsctiptionsToShow:
                            self.debugSettings.groupShowingCountLimit ?? 0,
                            periodInDays: self.debugSettings.limitPeriodInDays ?? 0
                        ) : nil
                )
            )
            self.vkid = VKID.shared
        } catch {
            preconditionFailure("Failed to set configuration for VKID: \(error)")
        }

        let tabBarController = UITabBarController()
        self.api = API(debugSettings: self.debugSettings)
        tabBarController.viewControllers = [
            self.makeAuthViewController(),
            self.makeCustomizationViewController(),
            self.makeAccountViewController(),
        ]

        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = tabBarController
        self.window?.makeKeyAndVisible()

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        self.vkid?.open(url: url) ?? false
    }

    private func makeAuthViewController() -> UIViewController {
        let bundleVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] ?? ""
        let authViewController = AuthViewController(
            title: "Авторизация VKID",
            subtitle: "Вход с помощью VKID",
            description: "Нажмите на кнопку, чтобы начать авторизацию",
            navigationTitle: "VKID Version: \(VKID.sdkVersion)\nBuild: \(bundleVersion)",
            debugSettings: self.debugSettings,
            api: self.api
        )
        authViewController.tabBarItem = UITabBarItem(
            title: "Авторизация",
            image: UIImage(resource: .house),
            tag: 0
        )
        authViewController.vkid = self.vkid
        authViewController.debugSettings = self.debugSettings
        authViewController.api = self.api

        return UINavigationController(
            rootViewController: authViewController
        )
    }

    private func makeCustomizationViewController() -> UIViewController {
        let customizationViewController = ControlsViewController(
            title: "Кастомизация",
            subtitle: "Примеры контролов из VK ID SDK",
            description: "Выберите контрол из списка, чтобы посмотреть его детальные настройки",
            debugSettings: self.debugSettings,
            api: self.api
        )
        customizationViewController.vkid = self.vkid
        customizationViewController.tabBarItem = UITabBarItem(
            title: "Кастомизация",
            image: UIImage(resource: .leafFill),
            tag: 1
        )
        return UINavigationController(
            rootViewController: customizationViewController
        )
    }

    private func makeAccountViewController() -> UIViewController {
        let userSessionsViewController = UserSessionsViewController(
            title: "Сессии",
            subtitle: "Данные о сессиях",
            description: """
                Здесь отображается список сохраненных
                авторизованных сессий.
                """,
            debugSettings: self.debugSettings,
            api: self.api
        )
        userSessionsViewController.vkid = self.vkid
        userSessionsViewController.tabBarItem = UITabBarItem(
            title: "Сессии",
            image: UIImage(resource: .personCropCircleFill),
            tag: 2
        )
        return UINavigationController(
            rootViewController: userSessionsViewController
        )
    }
}
