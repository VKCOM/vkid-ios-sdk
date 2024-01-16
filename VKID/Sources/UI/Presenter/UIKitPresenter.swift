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

/// Абстракция для показа и скрытия UIViewController
public protocol UIKitPresenting {
    func present(_ controller: UIViewController, animated: Bool, completion: (() -> Void)?)
    func dismiss(_ controller: UIViewController, animated: Bool, completion: (() -> Void)?)

    var presentingWindow: UIWindow? { get }
}

// MARK: - UIKitPresenter

/// Содержит в себе готовые способы показа UIViewController
///
/// Для показа экранов VK ID SDK, есть 3 готовых механизма показа экранов
///
/// 1. ``newUIWindow`` - показывает экран на новом UIWindow
/// 2. ``uiWindow(_:)`` - показывает экран на заданном UIWindow
/// 3. ``uiViewController(_:)`` - показывает экран на заданном UIViewController
/// 4. ``custom(_:)`` - показывает экран при помощи кастомной логики
public struct UIKitPresenter: UIKitPresenting {
    private let presenting: UIKitPresenting

    fileprivate init(_ presenting: UIKitPresenting) {
        self.presenting = presenting
    }

    /// Агрегация протокола ``UIKitPresenting``, чтобы можно было вызывать present напрямую
    public func present(_ controller: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        self.presenting.present(controller, animated: animated, completion: completion)
    }

    /// Агрегация протокола ``UIKitPresenting``, чтобы можно было вызывать dismiss напрямую
    public func dismiss(_ controller: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        self.presenting.dismiss(controller, animated: animated, completion: completion)
    }

    public var presentingWindow: UIWindow? {
        self.presenting.presentingWindow
    }
}

extension UIKitPresenter {
    public static let newUIWindow: Self = .init(NewUIWindowPresenter())

    public static func uiWindow(_ window: UIWindow) -> Self {
        .init(UIWindowPresenter(window))
    }

    public static func uiViewController(_ viewController: UIViewController) -> Self {
        .init(UIViewControllerPresenter(viewController))
    }

    public static func custom(_ presenting: UIKitPresenting) -> Self {
        .init(presenting)
    }
}

// MARK: - UIViewControllerPresenter

struct UIViewControllerPresenter: UIKitPresenting {
    private weak var viewController: UIViewController?

    fileprivate init(_ viewController: UIViewController) {
        self.viewController = viewController
    }

    func present(_ controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
        self.viewController?.present(controller, animated: animated, completion: completion)
    }

    func dismiss(_ controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
        self.viewController?.dismiss(animated: animated, completion: completion)
    }

    var presentingWindow: UIWindow? {
        self.viewController?.view.window
    }
}

// MARK: - UIWindowPresenter

struct UIWindowPresenter: UIKitPresenting {
    private let window: UIWindow

    fileprivate init(_ window: UIWindow) {
        self.window = window
    }

    func present(_ controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
        self.window.rootViewController?.present(controller, animated: animated, completion: completion)
    }

    func dismiss(_ controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
        self.window.rootViewController?.dismiss(animated: animated, completion: completion)
    }

    var presentingWindow: UIWindow? {
        self.window
    }
}

// MARK: - NewUIWindowPresenter

struct NewUIWindowPresenter: UIKitPresenting {
    private let window: UIWindow

    public init() {
        self.window = UIWindow()
        self.window.backgroundColor = .clear
        self.window.rootViewController = UIViewController()
        self.window.isUserInteractionEnabled = true
        self.window.isHidden = true
    }

    public func present(_ controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
        self.moveWindowToActiveScene()
        self.window.rootViewController?.present(controller, animated: animated)
    }

    public func dismiss(_ controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
        self.window.rootViewController?.dismiss(animated: animated) {
            self.removeWindow()
            completion?()
        }
    }

    public var presentingWindow: UIWindow? {
        self.window
    }

    private func moveWindowToActiveScene() {
        guard let keyWindow = UIApplication.shared.keyWindow else {
            return
        }
        if #available(iOS 13.0, *) {
            self.window.windowScene = keyWindow.windowScene
        }
        self.window.frame = keyWindow.frame
        self.window.isHidden = false
        self.window.makeKeyAndVisible()
    }

    private func removeWindow() {
        if #available(iOS 13.0, *) {
            self.window.windowScene = nil
        }

        self.window.isHidden = true
        self.window.resignKey()
    }
}
