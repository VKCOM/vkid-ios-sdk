<div align="center">
  <h1 align="center">
    <img src="logo.svg" width="150" alt="VK ID SDK Logo">
  </h1>
  <p align="center">
    VK ID SDK — библиотека для авторизации пользователей iOS приложений с помощью аккаунта VK ID.
  </p>
</div>

## Предварительно

Общий план интеграции и в целом что такое VK ID можно прочитать [здесь](https://id.vk.com/business/go/docs/vkid/latest/start-page).

Чтобы подключить VK ID SDK, сначала получите ID приложения (app_id) и защищенный ключ (client_secret). Для этого создайте приложение в [кабинете подключения VK ID](https://platform.vk.com/docs/vkid/latest/create-application).

## Требования к приложению
* iOS 12.0 и выше
* Swift 5.7 и выше

## Установка

### Swift Package Manager
Добавьте VKID как зависимость в ваш `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/VKCOM/vkid-ios-sdk.git", .upToNextMajor(from: "0.0.1-alpha"))
]
```

### CocoaPods
Добавьте в ваш `Podfile`:
```ruby
pod 'VKID', ~> '0.0.1-alpha'
```
Выполните следующие команды, чтобы установить зависимости:
```shell
pod install --repo-update
```

## Интеграция

### Настройка Info.plist
Для поддержки бесшовной авторизации через провайдер (клиент ВКонтакте или другое официальное приложение VK) внесите в ваш `Info.plist` следующие изменения:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>vkauthorize-silent</string>
</array>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>auth_callback</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>vk123456</string> // Вместо 123456 подставьте ID вашего приложения.
        </array>
    </dict>
</array>
```

### Поддержка Universal Links
VK ID SDK взаимодействует с провайдерами авторизации через [Universal Links](https://developer.apple.com/ios/universal-links/).
При [настройке VK ID](https://id.vk.com/business/go/docs/vkid/latest/plan#Podgotovka-k-integracii) в кабинете его подключения укажите Universal Link, по которой провайдер авторизации откроет ваше приложение. Добавьте [поддержку Universal Links](https://developer.apple.com/documentation/xcode/supporting-associated-domains?language=objc) в приложение.

### Инициализация VK ID SDK
Все взаимодействие с VK ID SDK происходит через объект `VKID`.
```swift
import VKID

do {
    let vkid = try VKID(
        config: Configuration(
            appCredentials: AppCredentials(
                clientId: clientId,         // ID вашего приложения (app_id)
                clientSecret: clientSecret  // ваш защищенный ключ (client_secret)
            )
        )
    )
} catch {
    preconditionFailure("Failed to initialize VKID: \(error)")
}
```

### Авторизация
Флоу авторизации запускается вызовом метода `authorize`:
```swift
vkid.authorize(
    using: .uiViewController(self)
) { result in
    do {
        let session = try result.get()
        print("Auth succeeded with token: \(session.accessToken)")
    } catch AuthError.cancelled {
        print("Auth cancelled by user")
    } catch {
        print("Auth failed with error: \(error)")
    }
}
```

Так же необходимо поддержать открытие ссылки при возврате в ваше приложение из провайдера авторизации. Для этого в вашем `AppDelegate` сделайте следующие изменения:
```swift
func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
) -> Bool {
    return self.vkid.open(url: url)
}
```

Если ваше приложение использует `UIScene`, то нужно реализовать следующий метод из `UISceneDelegate`:
```swift
func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
) {
    URLContexts.forEach { ctx in
        self.vkid.open(url: ctx.url)
    }
}
```

### Запуск авторизации по кнопке One Tap
Чтобы создать кнопку авторизации One Tap, сконфигурируйте `OneTapButton` и получите `UIView`:
```swift
let oneTap = OneTapButton(onCompleteAuth: { result in
    do {
        let session = try result.get()
        print("Auth succeeded with token: \(session.accessToken)")
    } catch AuthError.cancelled {
        print("Auth cancelled by user")
    } catch {
        print("Auth failed with error: \(error)")
    }
})
let oneTapTrampoline = vkid.ui(for: oneTap)
let uiView = oneTapTrampoline.uiView()
```

При необходимости вы можете настроить кнопку:
```swift
let oneTap = OneTapButton(
    appearance: OneTapButton.Appearance(style: .primary(), theme: .system),
    layout: .regular(),
    presenter: .newUIWindow
)
```

Также можно переопределить поведение при нажатии на кнопку:
```swift
let oneTap = OneTapButton(onTap: { activityIndicating in
    activityIndicating.startAnimating()
    // aвторизация
    activityIndicating.stopAnimating()
})
```

## Демонстрация

SDK поставляется с примером приложения, где можно посмотреть работу авторизации.
В папке [VKIDDemo](VKIDDemo) содержится тестовое приложение. Для корректной работы тестового приложения укажите параметры `CLIENT_ID` и `CLIENT_SECRET` вашего приложения VKID в файле [Info.plist](VKIDDemo/VKIDDemo/Resources/Info.plist).

## Документация

- [Что такое VK ID](https://id.vk.com/business/go/docs/vkid/latest/start-page)
- [Создание приложения](https://platform.vk.com/docs/vkid/latest/create-application)
- [Требования к дизайну](https://platform.vk.com/docs/vkid/latest/guidelines/design-rules)
