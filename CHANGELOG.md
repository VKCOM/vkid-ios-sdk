# CHANGELOG

> **Note**\
> Описание основных изменений в релизах VK ID SDK. Наш SDK следует [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.3.3 - 2024-09-04

### Added
- Файл манифеста `PrivacyInfo.xcprivacy`, описывающий какие пользовательские данные использует VK ID SDK. Подробнее в статье Apple про [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)

### Fixed
- Проблема при авторизации через веб-вью с прыжком в приложение `VK`.

## 1.3.2 - 2024-06-04

### Fixed
- Необходимость явно импортировать `VKIDCore` при установке через SPM

## 1.3.1 - 2024-05-27

### Fixed
- Проблема с использованием ресурсов SDK при установке через CocoaPods

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
- [Базовая авторизация](https://id.vk.com/business/go/docs/ru/vkid/latest/vk-id/connection/ios/auth)
- [Авторизация по кнопке OneTap](https://id.vk.com/business/go/docs/ru/vkid/latest/vk-id/connection/ios/onetap)
- [Шторка авторизации](https://id.vk.com/business/go/docs/ru/vkid/latest/vk-id/connection/ios/onetap)
