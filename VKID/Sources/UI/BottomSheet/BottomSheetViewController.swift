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

/// Протокол для контента шторки
protocol BottomSheetContent: AnyObject {
    /// Делегат для оповещения контейнера об изменившихся размерах контента
    var contentDelegate: BottomSheetContentDelegate? { get set }

    /// Спрашиваем у контента какой размер он будет занимать при указанном доступном размере родительского контейнера
    /// - Parameter parentSize: размер контейнера для отображения контента
    /// - Returns: размер контента, необходимый для отображения в указанном контейнере
    func preferredContentSize(withParentContainerSize parentSize: CGSize) -> CGSize
}

/// Дефолтная реализация для расчета размера контента
extension BottomSheetContent {
    func preferredContentSize(withParentContainerSize parentSize: CGSize) -> CGSize {
        parentSize
    }
}

/// Делегат для оповещения контейнера об изменившихся размерах контента
protocol BottomSheetContentDelegate: AnyObject {
    /// Сообщаем контейнеру, что размер контента изменился
    /// - Parameter content: отображаемый контент
    func bottomSheetContentDidInvalidateContentSize(_ content: BottomSheetContent)
}

/// Тип для контроллера с контентом внутри шторки
typealias BottomSheetContentViewController = UIViewController & BottomSheetContent

/// Набор методов для оповещения о закрытии шторки
protocol BottomSheetViewControllerDelegate: AnyObject {
    func bottomSheetViewControllerDidDismiss(_ controller: BottomSheetViewController)
}

/// Конфигурация лейаута шторки
struct BottomSheetLayoutConfiguration {
    /// Радиус скругления углов шторки
    package var cornerRadius: CGFloat

    /// Отступы от краев родительского контейнера в дополнение к его safeAreaInsets
    package var edgeInsets: UIEdgeInsets {
        UIDevice.current.orientation.isLandscape ? landscapeEdgeInsets : portraitEdgeInsets
    }

    /// Отступы от краев родительского контейнера в дополнение к его safeAreaInsets в 'portrait'
    package var portraitEdgeInsets: UIEdgeInsets

    /// Отступы от краев родительского контейнера в дополнение к его safeAreaInsets в 'landscape'
    package var landscapeEdgeInsets: UIEdgeInsets

    package var bottomSheetWidth: BottomSheetWidth

    package init(
        cornerRadius: CGFloat,
        portraitEdgeInsets: UIEdgeInsets,
        landscapeEdgeInsets: UIEdgeInsets = .zero,
        bottomSheetWidth: BottomSheetWidth = .default) {
        self.cornerRadius = cornerRadius
        self.portraitEdgeInsets = portraitEdgeInsets
        self.landscapeEdgeInsets = landscapeEdgeInsets
        self.bottomSheetWidth = bottomSheetWidth
    }
}

enum BottomSheetWidth: Int {
    case `default` = 420
    case small = 446
    case medium = 484
    case large = 522
    case extraLarge = 560

    func larger() -> Self? {
        switch self {
        case .default: .small
        case .small: .medium
        case .medium: .large
        case .large: .extraLarge
        case .extraLarge: nil
        }
    }

    var imageSize: (CGFloat, CGFloat) {
        switch self{
        case .default: (192, 120)
        case .small: (130, 130)
        case .medium: (168, 168)
        case .large: (206, 206)
        case .extraLarge: (244, 244)
        }
    }
}

/// Контейнер для отображения шторки
open class BottomSheetViewController: UIViewController, BottomSheetContent {
    weak var delegate: BottomSheetViewControllerDelegate?
    weak var contentDelegate: BottomSheetContentDelegate?

    internal let contentViewController: BottomSheetContentViewController
    private var _transitioningDelegate: BottomSheetTransitioningDelegate?

    let layoutConfiguration: BottomSheetLayoutConfiguration
    internal let presenter: UIKitPresenter?
    private var adaptiveWidth: Bool = false

    /// Инициализирует контейнер с указанным контроллером для отображения контента
    /// - Parameter contentViewController: контроллер для отображения контента шторки
    /// - Parameter layoutConfiguration: конфигурация лейаута шторки
    /// - Parameter presenter: презентер шторки
    init(
        contentViewController: BottomSheetContentViewController,
        layoutConfiguration: BottomSheetLayoutConfiguration,
        presenter: UIKitPresenter? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.presenter = presenter
        self.contentViewController = contentViewController
        self.layoutConfiguration = layoutConfiguration
        super.init(nibName: nil, bundle: nil)
        self._transitioningDelegate = BottomSheetTransitioningDelegate(
            bottomSheetInsets: layoutConfiguration.portraitEdgeInsets,
            presenter: presenter,
            bottomSheetWidth: layoutConfiguration.bottomSheetWidth
        ) {
            onDismiss?()
        }
        self.transitioningDelegate = self._transitioningDelegate
        self.modalPresentationStyle = .custom
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer.cornerRadius = self.layoutConfiguration.cornerRadius
        self.view.layer.masksToBounds = true
        self.addContentViewController(self.contentViewController)
    }

    package func preferredContentSize(withParentContainerSize parentSize: CGSize) -> CGSize {
        self.contentViewController.preferredContentSize(withParentContainerSize: parentSize)
    }
}

extension BottomSheetViewController {
    private func addContentViewController(
        _ controller: BottomSheetContentViewController
    ) {
        controller.contentDelegate = self
        self.addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(controller.view) {
            $0.pinToEdges()
        }
        controller.didMove(toParent: self)
    }
}

extension BottomSheetViewController: BottomSheetContentDelegate {
    func bottomSheetContentDidInvalidateContentSize(_ content: BottomSheetContent) {
        self.relayoutPresentationContainerView()
    }
}
