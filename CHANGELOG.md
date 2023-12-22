# CHANGELOG

> **Note**\
> Описание основных изменений в релизах VK ID SDK. Наш SDK следует [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- [Базовая авторизация](https://id.vk.com/business/go/docs/ru/vkid/latest/vk-id/connection/ios/auth)
- [Авторизация по кнопке OneTap](https://id.vk.com/business/go/docs/ru/vkid/latest/vk-id/connection/ios/onetap)
- [Шторка авторизации](https://id.vk.com/business/go/docs/ru/vkid/latest/vk-id/connection/ios/onetap)
