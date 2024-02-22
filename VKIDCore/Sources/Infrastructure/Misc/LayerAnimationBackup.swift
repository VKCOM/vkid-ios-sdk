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

/// Сущность, создающая резервные копии анимаций на слое.
/// Используется для сохранения анимаций, когда приложение уходит в фоновой режим - `background`,
/// и возвращаюшая их на слой, когда приложение переходит в активный режим - `foreground`.
internal final class LayerAnimationBackup {
    /// Флаг, указывающий на наличие ключей в хранилище.
    internal var isEmpty: Bool {
        self.keys.isEmpty
    }

    private var keys: Set<String> = []

    private weak var layer: CALayer?
    private var animationMetas: [String: CAAnimation] = [:]

    /// Инициализатор резервного копирования анимаций на слое
    /// - Parameter layer: Слой, на котором необходимо зарезервировать анимации в фоне.
    internal init(layer: CALayer) {
        self.layer = layer

        self.setupNotifications()
    }

    @objc
    private func appDidBecomeActive() {
        self.restoreAnimations()
    }

    @objc
    private func appWillResignActive() {
        self.backupAnimations()
    }

    /// Добавление ключей, по которым будет резервироваться анимация
    internal func add(keys: Set<String>) {
        self.keys.formUnion(keys)
    }

    /// Удаление ключей, по которым будет резервироваться анимация
    internal func remove(keys: Set<String>) {
        self.keys.subtract(keys)
        keys.forEach { self.animationMetas.removeValue(forKey: $0) }
    }

    /// Резервное копирование анимаций на слое
    internal func backupAnimations() {
        guard !self.isEmpty else {
            self.animationMetas.removeAll()
            return
        }

        self.keys.forEach { key in
            guard let animation = self.layer?.animation(forKey: key) else { return }

            self.animationMetas[key] = animation
        }
    }

    /// Восстановление анимаций из резервной копии
    internal func restoreAnimations() {
        self.animationMetas.forEach { animationMeta in
            self.layer?.add(
                animationMeta.value,
                forKey: animationMeta.key
            )
        }
        self.animationMetas.removeAll()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
