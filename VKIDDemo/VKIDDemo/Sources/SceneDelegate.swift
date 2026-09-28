import UIKit
import VKID

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var vkid: VKID?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard
            let windowScene = scene as? UIWindowScene,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else {
            return
        }

        self.vkid = appDelegate.vkid

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = appDelegate.makeRootViewController()
        self.window = window
        window.makeKeyAndVisible()

        self.scene(scene, openURLContexts: connectionOptions.urlContexts)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            _ = self.vkid?.open(url: context.url)
        }
    }
}
