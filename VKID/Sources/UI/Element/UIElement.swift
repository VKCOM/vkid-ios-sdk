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
import SwiftUI
import UIKit

/// Базовый протокол для реализации UI элементов в VK ID SDK
public protocol UIElement {
    /// Определяет фабрику, которая может создавать данный UIElement
    associatedtype Factory: UIFactory
}

/// Фабрика для получения UI элементов
///
/// UI фабрика способна возвращать элементы для разных UI фреймворков.
/// Это реализовано при помощи ``UITrampoline``, который
/// позволяет получить SwiftUI.View, UIView или UIViewController,
/// в зависимости от поддерживаемого типа ``UIElement``-ом
public protocol UIFactory {
    /// Получение UI трамплина
    /// - Parameters:
    ///  - element: UI элемент, отображение которого необходимо получить
    /// - Returns: ``UITrampoline``
    func ui<Element: UIElement>(for element: Element) -> UITrampoline<Element> where Element.Factory == Self
}

/// Базовая реализация метода для создания представления элемента
extension UIFactory {
    public func ui<Element: UIElement>(for element: Element) -> UITrampoline<Element> where Element.Factory == Self {
        .init(element: element, factory: self)
    }
}

/// UI элемент с представлением в виде UIView
public protocol UIViewElement: UIElement {
    /// Тип представления, поддерживаемый данным UIElement.
    associatedtype UIViewType: UIView

    func _uiView(factory: Self.Factory) -> Self.UIViewType
}

/// UI элемент с представлением в виде UIViewController
public protocol UIViewControllerElement: UIElement {
    /// Тип представления, поддерживаемый данным UIElement.
    associatedtype UIViewControllerType: UIViewController

    func _uiViewController(factory: Self.Factory) -> Self.UIViewControllerType
}

/// UI элемент с представлением в виде SwiftUI.View
@available(iOS 13.0, *)
public protocol SwiftUIViewElement: UIElement {
    /// Тип представления, поддерживаемый данным UIElement.
    associatedtype ViewType: View

    func _view(factory: Self.Factory) -> Self.ViewType
}

/// Позволяет получать представления, поддерживаемые указанным ``UIElement``
public struct UITrampoline<Element: UIElement> {
    private let element: Element
    private let factory: Element.Factory

    internal init(element: Element, factory: Element.Factory) {
        self.element = element
        self.factory = factory
    }

    /// Создает UIView представление для указанного ``UIElement``
    /// - Returns: наследник UIView
    public func uiView() -> Element.UIViewType where Element: UIViewElement {
        self.element._uiView(factory: self.factory)
    }

    /// Создает UIViewController представление для указанного ``UIElement``
    /// - Returns: наследник UIViewController
    public func uiViewController() -> Element.UIViewControllerType where Element: UIViewControllerElement {
        self.element._uiViewController(factory: self.factory)
    }

    /// Создает SwiftUI.View представление для указанного ``UIElement``
    /// - Returns: реализация SwiftUI.View
    @available(iOS 13.0, *)
    public func view() -> Element.ViewType where Element: SwiftUIViewElement {
        self.element._view(factory: self.factory)
    }
}
