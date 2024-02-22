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

import QuartzCore

/// Поскольку  при переходе приложения из активного режима в фоновой, все находящиеся на слое анимации удаляются.
/// И при этом есть необходимость их восстанавливать, при возвращении приложения в активный режим.
/// Была разарботана сущность, занимающаяся резервным копированием и восстановлением анимаций.
extension CALayer {
    private enum Keys {
        static let layerAnimationBackup: String = "layerAnimationBackup"
    }

    private var layerAnimationBackup: LayerAnimationBackup? {
        guard let layerAnimationBackup = self.value(
            forKey: Keys.layerAnimationBackup
        ) as? LayerAnimationBackup else {
            return nil
        }

        return layerAnimationBackup
    }

    /// Включаем восстановление анимаций, при переходе приложения из фонового в активный режим.
    public func shouldRestoreAnimationsOnBecomeActive(_ value: Bool, for keys: Set<String>) {
        if value {
            defer { layerAnimationBackup?.add(keys: keys) }

            guard self.layerAnimationBackup == nil else {
                return
            }

            self.setValue(
                LayerAnimationBackup(layer: self),
                forKey: Keys.layerAnimationBackup
            )
        } else {
            guard self.layerAnimationBackup?.isEmpty == true else {
                self.layerAnimationBackup?.remove(keys: keys)
                return
            }

            self.setValue(
                nil,
                forKey: Keys.layerAnimationBackup
            )
        }
    }
}
