# CHANGELOG

> **Note**\
> Описание основных изменений в релизах VK ID SDK. Наш SDK следует [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
## 2.7.1 - 2025-09-11

### Changed
+ ВКонтакте переходит на домен vk.ru — теперь все API-интеграции и авторизации будут доступны только через него.

## 2.7.0 - 2025-07-09

### Added
+ Теперь используем в SDK синглтон. Предоставляем shared-объект: `VKID.shared`. Перед использованием объекта сконфигурируйте его — `VKID.shared.set(config:)` — например, это можно сделать при запуске приложения.
+ Добавили поддержку Captcha. Теперь она обрабатывается в запросах, которые делает VK ID SDK, по умолчанию.

### Changed
+ Локализация текстов полностью переведена на Strings Catalogs — `.xcstrings`

## 2.5.0 - 2025-06-09

### Added
+ Добавили окно подписки на сообщество — с его помощью вы можете предложить пользователю после авторизации в сервисе подписаться на ваше сообщество ВКонтакте. Подписка на сообщество позволяет выстраивать прямой контакт с аудиторией и даёт бизнесу ряд преимуществ, например рост органического трафика за счёт вовлечения аудитории ВКонтакте, возможность информировать подписчиков о новостях, акциях и обновлениях. Подробнее о подключении окна подписки читайте в [документации](!!ru/vkid/latest/vk-id/connection/group-subscription/group-subscription-ios.mdx). 

### Changed
+ Изменили [работу локали](!!ru/vkid/latest/vk-id/connection/start-integration/ios/instal.mdx#Nastrojka-lokali-UI-komponentov): теперь её можно настроить для UI всего SDK, а не только в WebView. 
+ Сделали небольшие визуальные улучшения виджета 3 в 1.
## 2.4.1 - 2025-03-11

### Added
+ В `OneTapBottomSheet` добавлен метод `autoShow(configuration:,factory:)`, который позволяет автоматически показывать шторку авторизации сразу при входе пользователя в приложение или с задержкой. [Подробнее](https://id.vk.ru/about/business/go/docs/ru/vkid/latest/vk-id/connection/elements/onetap-drawer/floating-onetap-ios#Nastrojka-avtomaticheskogo-otobrazheniya-shtorki)
## 2.3.1 - 2024-12-05

### Fixed
+ Убрали предупреждение `'exchangeAuthCode (_:completion:) is deprecated`.

## 2.3.0 - 2024-12-04

### Added
+ Добавлен протокол `AuthCodeHandler`, который предоставляет `AuthorizationCode` для обмена кода авторизации на токены на бэкенде. 
+ Для удобства добавлена возможность отключения логов. 
+ Добавлена возможность выбрать альтернативные провайдеры авторизации и заголовок OneTap в одном инициализаторе. 
+ Для удобства добавлена проверка ID приложения (clientId) из Info.plist. 
+ Добавлена возможность авторизации только в WebView, без прыжка в провайдер авторизации. 

### Fixed
+ Теперь сallback о завершении авторизации `vkid(_:, didCompleteAuthWith:, in:)` вызывается после закрытия контроллера с WebView. В этом сallback вы можете менять иерархию UIViewController-ов, не используя дополнительные задержки через DispatchQueue.main.asyncAfter.

## 2.2.1 - 2024-09-11

### Fixed
- Исправлена проблема при авторизации через WebView с прыжком в приложение `VK`. Теперь всё работает корректно.

## 1.3.3 - 2024-09-04

### Added
- В соответствии с [требованиями Apple](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files) добавлен файл манифеста 'PrivacyInfo.xcprivacy', который описывает, какие пользовательские данные использует VK ID SDK.

### Fixed
- Исправлена проблема при авторизации через WebView с прыжком в приложение `VK`. Теперь всё работает корректно.

## 2.2.0 - 2024-08-27

### Changed
- Поддержали ребрендинг Почты Mail: в SDK обновлены все экраны с логотипом Почты, а также изменено название сервиса с Mail.ru на Mail. Доработки в коде из-за ребрендинга не требуются.

### Fixed
- Ранее, если приложение `VK` сворачивалось до того, как оно загрузилось, могла наблюдаться проблема с двойным вызовом `completion` авторизации. Исправлено. Теперь всё работает корректно.

## 2.1.0 - 2024-08-08

### Added
- Добавлена возможность выбрать текст кнопки One Tap, который увидит пользователь. Это позволяет адаптировать кнопку для разных сценариев — например, для получения услуги отобразить текст «Записаться c VK ID» . Подробнее о настройке текста в кнопке читайте в [документации](https://id.vk.ru/about/business/go/docs/ru/vkid/latest/vk-id/connection/elements/onetap-button/onetap-ios).
- В соответствии с [требованиями Apple](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files) добавлен файл манифеста `PrivacyInfo.xcprivacy`, который описывает, какие пользовательские данные использует VK ID SDK.

## 2.0.0 - 2024-06-25

### Added
- [VK ID](https://id.vk.ru/about/business/go/docs/ru/vkid/latest/vk-id/intro/plan) теперь поддерживает авторизацию по [протоколу OAuth 2.1](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1-10). За счет работы авторизации на передовом стандарте обеспечивается высокая защита пользовательских данных.
- Для пользователя добавлена возможность входа через аккаунты «Одноклассников» и Mail.ru. Для отображения кнопок входа через эти сервисы интегрируйте [виджет 3 в 1](https://id.vk.ru/about/business/go/docs/ru/vkid/latest/vk-id/intro/main#Vidzhet-3-v-1) — блок с кнопками будет располагаться на окне авторизации вашего сервиса — или подключите [дополнительные OAuth](https://id.vk.ru/about/business/go/docs/ru/vkid/latest/vk-id/intro/main#Podklyuchenie-dopolnitelnyh-OAuth) — для показа кнопок на окне авторизации VK ID.

### Changed
- **Breaking changes:** Изменения в публичных интерфейсах `AuthConfiguration`, `OAuthListWidget`, `OneTapButton`, `OneTapBottomSheet`. Для перехода с SDK предыдущей версии и поддержки этих изменений воспользуйтесь [инструкцией](https://id.vk.ru/about/business/go/docs/ru/vkid/latest/vk-id/connection/migration/ios/oauth-2.1).

## 1.3.2 - 2024-06-05

### Fixed
- Ошибка сборки модуля `VKID` при установке через Swift Package Manager

## 2.0.0-alpha.2 - 2024-05-28

### Added
- Тип `Scope`, описывающий права доступа при авторизации
- Поля `AccessToken.scope` и `RefreshToken.scope`, содержащие разрешенные права для указанных токенов 

### Fixed
- Проблема с использованием ресурсов SDK при установке через CocoaPods

### Removed
- Возможность миграции токенов по `confidentialClientFlow`

### Changed
- **Breaking changes:** Переименовали поле `scopes -> scope` в `AuthConfiguration`. Теперь поле `AuthConfiguration.scope` имеет кастомный тип `Scope` вместо `Set<String>`

## 1.3.1 - 2024-05-27

### Fixed
- Проблема с использованием ресурсов SDK при установке через CocoaPods

## 2.0.0-alpha - 2024-05-20

### Added
- Поддержка авторизации по протоколу [OAuth 2.1](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1-10)
- Поддержка входа через аккаунты Одноклассников и Mail

### Changed
- **Breaking changes:** изменения в публичных интерфейсах `AuthConfiguration`, `OAuthListWidget`, `OneTapButton`, `OneTapBottomSheet`.


## 1.3.0 - 2024-02-22

### Added
- Отображение состояний процесса авторизации (в прогрессе, успех, ошибка) в шторке `OneTapBottomSheet`
- Хранение авторизованной сессии `VKID.currentAuthorizedSession` между перезапусками приложения
- Возможность логаута из авторизованной сессии (`UserSession.logout`)

## 1.2.2 - 2024-02-16

### Fixed
- Логика проверки SSL Pinning

## 1.2.1 - 2024-01-25

### Fixed
- При получении данных пользователя поле `User.phone` всегда было маскированным.

## 1.2.0 - 2024-01-16

### Added
- Возможность получить данные пользователя после авторизации в VK ID. В объект `UserSession` (результат успешной авторизации) добавлено поле `user`.

## 1.1.0 - 2023-12-22

### Added
- Beta версия авторизации 3 в 1 (`OAuthListWidget`).

### Fixed
- Анимация открытия и закрытия шторки авторизации
- Невозможность повторного логина до перезапуска приложения при наличии авторизованной сессии
- Версия swift-tools-version: 5.9.0 в Package.swift. До этого была указана неверная.

## 1.0.1 - 2023-12-08

### Fixed
- Установка VK ID SDK с помощью [CocoaPods](https://cocoapods.org)
- Некорректный лейаут шторки авторизации во время переворота экрана на некоторых устройствах

## 1.0.0 - 2023-12-01

### Added
- [Базовая авторизация](https://id.vk.ru/business/go/docs/ru/vkid/latest/vk-id/connection/ios/auth)
- [Авторизация по кнопке OneTap](https://id.vk.ru/business/go/docs/ru/vkid/latest/vk-id/connection/ios/onetap)
- [Шторка авторизации](https://id.vk.ru/business/go/docs/ru/vkid/latest/vk-id/connection/ios/onetap)
