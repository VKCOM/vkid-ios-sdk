<div align="center">
  <h1 align="center">
    <img src="logo.svg" width="150" alt="VK ID SDK Logo">
  </h1>
  <p align="center">
    VK ID SDK — библиотека для авторизации пользователей iOS приложений с помощью аккаунта VK ID.
  </p>
</div>

---

:information_source: Версия VK ID SDK 2.0.0-alpha поддерживает авторизацию по протоколу [OAuth 2.1](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1-10), а также способы входа через аккаунты Одноклассников и Mail.ru. Если вы хотите участвовать в тестировании этой версии SDK или узнать о ней подробнее, напишите нам на почту devsupport@corp.vk.com.

---

- [Предварительно](#предварительно)
- [Требования к приложению](#требования-к-приложению)
- [Установка](#установка)
    - [Swift Package Manager](#swift-package-manager)
    - [CocoaPods](#cocoapods)
- [Авторизация по кнопке OneTap](https://id.vk.com/about/business/go/docs/ru/vkid/latest/vk-id-2/connection/ios/onetap)
- [Шторка авторизации](https://id.vk.com/about/business/go/docs/ru/vkid/latest/vk-id-2/connection/ios/floating-onetap)
- [Пользовательские сессии](https://id.vk.com/about/business/go/docs/ru/vkid/latest/vk-id-2/connection/ios/sessions)
- [Демонстрация](#демонстрация)
- [Документация](https://vkcom.github.io/vkid-ios-sdk/documentation/vkid/)

## Предварительно

Общий план интеграции и в целом что такое VK ID можно прочитать [здесь](https://id.vk.com/about/business/go/docs/ru/vkid/latest/vk-id-2/intro/start-page).

Чтобы подключить VK ID SDK, сначала получите ID приложения (app_id) и защищенный ключ (client_secret). Для этого создайте приложение в [кабинете подключения VK ID](https://id.vk.com/business/go).

## Требования к приложению
* iOS 12.0 и выше
* Swift 5.9 и выше

## Установка

### Swift Package Manager
Добавьте VKID как зависимость в ваш `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/VKCOM/vkid-ios-sdk.git", .exact("2.0.0-alpha"))
]
```

### CocoaPods
Добавьте в ваш `Podfile`:
```ruby
pod 'VKID', '2.0.0-alpha'
```
Выполните следующие команды, чтобы установить зависимости:
```shell
pod install --repo-update
```

Более подробно об установке VK ID SDK можно прочитать в статье [Как установить SDK](https://id.vk.com/about/business/go/docs/ru/vkid/latest/vk-id/connection/ios/install).

## Демонстрация

SDK поставляется с демо-приложением [VKIDDemo](VKIDDemo), где можно посмотреть работу авторизации и как кастомизируются предоставляемые визуальные компоненты. Для корректной работы демо-приложения укажите параметры `CLIENT_ID` и `CLIENT_SECRET` вашего приложения VKID в файле [Info.plist](VKIDDemo/VKIDDemo/Resources/Info.plist).
