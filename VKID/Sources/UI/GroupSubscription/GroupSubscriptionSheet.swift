//
// Copyright (c) 2025 - present, LLC “V Kontakte”
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
import VKIDCore

/// Ошибки при создании вью контроллера с данными по подписке на сообщество
public enum GroupSubscriptionSheetCreationError: String, Error {
    // Невалидный 'Access Token'
    case invalidAccessToken
    // Пользователь уже участник сообщества
    case alreadyMember
    // Сообщество закрыто
    case groupClosed
    // Пользователь авторизовался с помощью аккаунта VK ID, который не прошел процедуру дорегистрации — не создал учетную запись в социальной сети ВКонтакте
    case isServiceAccount
    // В Access Token отсутствует доступ `groups`
    case scopeMissing
    // При выполнении запроса произошла неизвестная ошибка
    case unknown
    // Ограничение по настройке лимита
    case localLimitReached
    // Показ подписки на сообщество не разрешен
    case subscriptionNotAllowed
}

/// Конфигурация подписки на сообщество
public struct GroupSubscriptionSheet: AsyncUIViewControllerElement {
    public typealias UIViewControllerType = UIViewController
    public typealias Factory = VKID
    public typealias ViewControllerElementError = GroupSubscriptionSheetCreationError

    private let subscribeToGroupId: String
    private let onCompleteSubscription: GroupSubscriptionCompletion?
    private let buttonConfiguration: ButtonConfiguration
    private let accessTokenProvider: any AuthorizationProviding
    private let sheetCornerRadius: CGFloat
    internal let theme: Theme
    private let presenter: UIKitPresenter
    private var userId: UserID?
    internal static var snackbarTime: DispatchTimeInterval = .seconds(4)

    public func _uiViewController(
        factory: Self.Factory,
        completion: @escaping (Result<Self.UIViewControllerType, ViewControllerElementError>) -> Void
    ) -> Void {
        guard self.isLocalLimitToShowNotReached(factory: factory) else {
            completion(.failure(.localLimitReached))
            return
        }

        self.accessTokenProvider.getAuthorizer(needToRefresh: false) { result in
            switch result {
            case .success(let authorization):
                factory.rootContainer.groupSubscriptionService.fetchGroupInfo(
                    groupId: self.subscribeToGroupId,
                    authorization: authorization
                ) { result in
                    let handler = GroupSubscriptionCreationHandler(
                        subscribeToGroupId: self.subscribeToGroupId,
                        factory: factory,
                        accessTokenProvider: self.accessTokenProvider,
                        // strong self capture is intentional
                        viewControllerCreator: self.createViewController(
                            groupInfo:groupMembersInfo:friendsCount:membersCount:vkid:authorizer:
                        )
                    )
                    handler.handle(
                        result: result,
                        authorizer: authorization.authorizer,
                        completion: completion
                    )
                }
            default:
                completion(.failure(.invalidAccessToken))
            }
        }
    }

    final class GroupSubscriptionCreationHandler {
        let subscribeToGroupId: String
        var isRefreshedAccessToken = Synchronized(wrappedValue: false)
        let factory: GroupSubscriptionSheet.Factory
        let accessTokenProvider: any AuthorizationProviding
        let viewControllerCreator: (
            (
                GroupInfo,
                [GroupMemberInfo],
                Int,
                Int,
                VKID,
                Authorizer
            ) -> GroupSubscriptionSheet.UIViewControllerType
        )?

        init(
            subscribeToGroupId: String,
            factory: GroupSubscriptionSheet.Factory,
            accessTokenProvider: any AuthorizationProviding,
            viewControllerCreator: (
                (
                    GroupInfo,
                    [GroupMemberInfo],
                    Int,
                    Int,
                    VKID,
                    Authorizer
                ) -> GroupSubscriptionSheet.UIViewControllerType
            )?
        ) {
            self.factory = factory
            self.accessTokenProvider = accessTokenProvider
            self.viewControllerCreator = viewControllerCreator
            self.subscribeToGroupId = subscribeToGroupId
        }

        func refreshAccessToken(
            completion: @escaping (
                Result<GroupSubscriptionSheet.UIViewControllerType,ViewControllerElementError>
            ) -> Void
        ) {
            if self.isRefreshedAccessToken.wrappedValue {
                completion(.failure(.invalidAccessToken))
                return
            }

            // strong self capture is intentional
            self.accessTokenProvider.getAuthorizer(
                needToRefresh: true
            ) { result in
                switch result {
                case .success(let authorization):
                    self.isRefreshedAccessToken.wrappedValue = true
                    self.factory.rootContainer.groupSubscriptionService.fetchGroupInfo(
                        groupId: self.subscribeToGroupId,
                        authorization: authorization
                    ) { result in
                        self.handle(
                            result: result,
                            authorizer: authorization.authorizer,
                            completion: completion
                        )
                    }
                default:
                    completion(.failure(.unknown))
                }
            }
        }

        func handle(
            result: Result<
                (
                    GroupInfo, [GroupMemberInfo],
                    friendsCount: Int,
                    membersCount: Int,
                    isServiceAccount: Bool,
                    show: Bool
                ),
                VKAPIError
            >,
            authorizer: Authorizer,
            completion: @escaping (
                Result<GroupSubscriptionSheet.UIViewControllerType,ViewControllerElementError>
            ) -> Void
        ) {
            switch result {
            case .success((
                let groupInfo,
                let groupMembersInfo,
                let friendsCount,
                let membersCount,
                let isServiceAccount,
                let show
            )):
                guard show else {
                    completion(.failure(.subscriptionNotAllowed))
                    return
                }
                guard let isGroupMember = groupInfo.isMember else {
                    completion(.failure(.scopeMissing))
                    return
                }
                guard !isGroupMember else {
                    completion(.failure(.alreadyMember))
                    return
                }
                guard !isServiceAccount else {
                    completion(.failure(.isServiceAccount))
                    return
                }
                guard !groupInfo.isClosed else {
                    completion(.failure(.groupClosed))
                    return
                }
                guard let viewController = self.viewControllerCreator?(
                    groupInfo,
                    groupMembersInfo,
                    friendsCount,
                    membersCount,
                    factory,
                    authorizer
                ) else {
                    completion(.failure(.unknown))
                    return
                }
                completion(.success(viewController))
            case .failure(let error):
                switch error {
                case .invalidAccessToken:
                    self.refreshAccessToken(completion: completion)
                default: completion(.failure(.unknown))
                }
            }
        }
    }

    /// Создает конфигурацию подписки на сообщество
    /// - Parameters:
    ///   - subscribeToGroupId: идентификатор сообщества
    ///   - buttonConfiguration: настроки кнопок подписки
    ///   - theme: тема подпискии на сообщество
    ///   - sheetCornerRadius: радиус скругления вью контроллера подписки на сообщество
    ///   - presenter: Презентер для отображения дополнительных UI элементов, например снекбар.
    ///   - onCompleteSubscription: Колбек с результатом подписки на сообщество.
    ///   - accessTokenProvider: Колбек с комплишеном предоставления 'accessToken'
    public init(
        subscribeToGroupId: String,
        buttonConfiguration: ButtonConfiguration? = nil,
        theme: Theme = .matchingColorScheme(.current),
        sheetCornerRadius: CGFloat = 24.0,
        presenter: UIKitPresenter = .newUIWindow,
        onCompleteSubscription: GroupSubscriptionCompletion?,
        accessTokenProvider: @escaping (
            _ needToRefresh: Bool,
            _ completion: @escaping (Result<String, Error>) -> Void
        ) -> Void
    ) {
        self.subscribeToGroupId = subscribeToGroupId
        self.onCompleteSubscription = onCompleteSubscription
        self.buttonConfiguration = buttonConfiguration ?? ButtonConfiguration()
        self.accessTokenProvider = ExternalAccessTokenProvider(handler: accessTokenProvider)
        self.sheetCornerRadius = sheetCornerRadius
        self.theme = theme
        self.presenter = presenter
    }

    internal init(
        groupSubscriptionConfiguration: GroupSubscriptionConfiguration,
        userSession: UserSession
    ) {
        self.subscribeToGroupId = groupSubscriptionConfiguration.subscribeToGroupId
        self.onCompleteSubscription = groupSubscriptionConfiguration.onCompleteSubscription
        self.buttonConfiguration = switch groupSubscriptionConfiguration.buttonType {
        case .inheritedOrDefault:
            groupSubscriptionConfiguration.inheritedButtonConfig
        case .custom(let buttonConfig):
            buttonConfig
        }
        self.accessTokenProvider = UserSessionAccessTokenProvider(userSession: userSession)
        self.sheetCornerRadius = groupSubscriptionConfiguration.sheetCornerRadius
        self.theme = groupSubscriptionConfiguration.theme
        self.presenter = groupSubscriptionConfiguration.presenter
        self.userId = userSession.userId
    }

    /// Конфигурация кнопки
    public struct ButtonConfiguration {
        /// Детерминированная высота кнопки
        public let height: OneTapButton.Layout.Height

        /// Радиус скругления контуров кнопки
        public let cornerRadius: CGFloat

        public init(
            height: OneTapButton.Layout.Height = .medium(),
            cornerRadius: CGFloat = 8.0
        ) {
            self.height = height
            self.cornerRadius = cornerRadius
        }
    }

    public struct Theme {
        internal struct Colors {
            internal var background: any Color
            internal var title: any Color
            internal var subtitle: any Color
            internal var groupInfo: any Color

            internal var primaryButtonBackground: any Color
            internal var primaryButtonTitle: any Color

            internal var retryButtonBackground: any Color
            internal var retryButtonTitle: any Color

            internal var activityIndicatorColor: any Color
        }

        internal struct Images {
            internal var vkidLogo: any Image
            internal var closeButton: any Image
            internal var failImage: any Image
        }

        internal var colors: Colors
        internal var images: Images
        internal var colorScheme: Appearance.ColorScheme

        /// Создает тему, соответствующую указанной цветовой схеме
        /// - Parameter scheme: цветовая схема
        /// - Returns: тема для шторки авторизации
        public static func matchingColorScheme(_ scheme: Appearance.ColorScheme) -> Self {
            switch scheme {
            case .system:
                let light = self.matchingColorScheme(.light)
                let dark = self.matchingColorScheme(.dark)
                return .init(
                    colors: .init(
                        background: DynamicColor(
                            light: light.colors.background.value,
                            dark: dark.colors.background.value
                        ),
                        title: DynamicColor(
                            light: light.colors.title.value,
                            dark: dark.colors.title.value
                        ),
                        subtitle: DynamicColor(
                            light: light.colors.subtitle.value,
                            dark: dark.colors.subtitle.value
                        ),
                        groupInfo: DynamicColor(
                            light: light.colors.groupInfo.value,
                            dark: dark.colors.groupInfo.value
                        ),
                        primaryButtonBackground: DynamicColor(
                            light: light.colors.primaryButtonBackground.value,
                            dark: dark.colors.primaryButtonBackground.value
                        ),
                        primaryButtonTitle: DynamicColor(
                            light: light.colors.primaryButtonTitle.value,
                            dark: dark.colors.primaryButtonTitle.value
                        ),
                        retryButtonBackground: DynamicColor(
                            light: light.colors.retryButtonBackground.value,
                            dark: dark.colors.retryButtonBackground.value
                        ),
                        retryButtonTitle: DynamicColor(
                            light: light.colors.retryButtonTitle.value,
                            dark: dark.colors.retryButtonTitle.value
                        ),
                        activityIndicatorColor: DynamicColor(
                            light: light.colors.activityIndicatorColor.value,
                            dark: dark.colors.activityIndicatorColor.value
                        )
                    ),
                    images: .init(
                        vkidLogo: DynamicImage(
                            light: light.images.vkidLogo.value,
                            dark: dark.images.vkidLogo.value
                        ),
                        closeButton: DynamicImage(
                            light: light.images.closeButton.value,
                            dark: dark.images.closeButton.value
                        ),
                        failImage: DynamicImage(
                            light: light.images.failImage.value,
                            dark: dark.images.failImage.value
                        )
                    ),
                    colorScheme: scheme
                )
            case .light:
                return .init(
                    colors: .init(
                        background: UIColor.groupModalCardBackgroundLight,
                        title: UIColor.blackTitleLight,
                        subtitle: UIColor.greySubtitleLight,
                        groupInfo: UIColor.greySubtitleLight,
                        primaryButtonBackground: UIColor.groupSubscribeLight,
                        primaryButtonTitle: UIColor.white,
                        retryButtonBackground: UIColor.groupCancelLight,
                        retryButtonTitle: UIColor.textAccentThemed,
                        activityIndicatorColor: UIColor.white
                    ),
                    images: .init(
                        vkidLogo: UIImage.vkLogoLight,
                        closeButton: UIImage.cancelLight,
                        failImage: UIImage.cancelCircle
                    ),
                    colorScheme: scheme
                )
            case .dark:
                return .init(
                    colors: .init(
                        background: UIColor.groupModalCardBackgroundDark,
                        title: UIColor.blackTitleDark,
                        subtitle: UIColor.greySubtitleDark,
                        groupInfo: UIColor.greySubtitleDark,
                        primaryButtonBackground: UIColor.groupSubscribeDark,
                        primaryButtonTitle: UIColor.black,
                        retryButtonBackground: UIColor.groupCancelDark,
                        retryButtonTitle: UIColor.white,
                        activityIndicatorColor: UIColor.black
                    ),
                    images: .init(
                        vkidLogo: UIImage.vkLogoDark,
                        closeButton: UIImage.cancelDark,
                        failImage: UIImage.cancelCircle
                    ),
                    colorScheme: scheme
                )
            }
        }
    }

    private func createViewController(
        groupInfo: GroupInfo,
        groupMembersInfo: [GroupMemberInfo],
        friendsCount: Int,
        membersCount: Int,
        vkid: VKID,
        authorizer: Authorizer
    ) -> UIViewController {
        var contentController: Synchronized<UIViewController?> = Synchronized(wrappedValue: nil)
        let viewController = GroupSubscriptionContentViewController(
            groupConfiguration: .init(
                groupId: groupInfo.id,
                userId: self.userId,
                groupAvatar: groupInfo.groupAvatar,
                vkLogo: .logoLight,
                title: groupInfo.name,
                subtitle: groupInfo.description,
                members: groupMembersInfo,
                countOfMembers: membersCount,
                countOfFriends: friendsCount,
                buttonConfig: self.buttonConfiguration,
                theme: .matchingColorScheme(self.theme.colorScheme),
                isVerified: groupInfo.isVerified,
                subscribe: { subscribeCompletion in
                    self.accessTokenProvider.getAuthorizer(needToRefresh: false) { result in
                        switch result {
                        case .success(let authorization):
                            vkid.rootContainer.groupSubscriptionService.subscribeToGroup(
                                groupId: self.subscribeToGroupId,
                                authorization: authorization
                            ) { result in
                                switch result {
                                case .success(let success):
                                    if success {
                                        contentController.wrappedValue?.dismiss(animated: true) {
                                            self.showSnackbar(
                                            ) {
                                                vkid.rootContainer.groupSubscriptionAnalytics.sendAnalytics(
                                                    groupId: groupInfo.id,
                                                    themeType: self.theme.colorScheme,
                                                    authorizer: authorizer,
                                                    eventType: .success
                                                )
                                            } onDismiss: {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                    [
                                                        onCompleteSubscription = self.onCompleteSubscription
                                                    ] in
                                                    onCompleteSubscription?(.success(()))
                                                }
                                            }
                                        }
                                    }
                                    subscribeCompletion(.success(success))
                                case.failure(let error):
                                    subscribeCompletion(.failure(error))
                                }
                            }
                        case .failure:
                            subscribeCompletion(.failure(.invalidAccessToken))
                        }
                    }
                },
                onSubscribeCompletion: self.onCompleteSubscription
            ),
            vkidAnalitycs: vkid.rootContainer.groupSubscriptionAnalytics,
            authorizer: authorizer,
            subscriptionStorageService: vkid.rootContainer.subscriptionStorageService,
            limits: vkid.groupSubscriptionsLimit
        )
        let sheet = BottomSheetViewController(
            contentViewController: viewController,
            layoutConfiguration: .init(
                cornerRadius: 14,
                edgeInsets: .init(
                    top: 0,
                    left: 16,
                    bottom: 32,
                    right: 16
                )
            )
        )
        contentController.wrappedValue = sheet
        return sheet
    }

    private func showSnackbar(
        onLoad: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        let viewController = SnackbarContentViewController(
            snackbarConfig:
            SnackbarSheetConfig(
                text: "vkid_group_subscription_snackbar_label".localized,
                theme: .matchingColorScheme(.current)
            )
        ) {
            onLoad?()
        } onDismiss: {
            onDismiss?()
        }
        let sheet = BottomSheetViewController(
            contentViewController: viewController,
            layoutConfiguration: .init(
                cornerRadius: 8,
                edgeInsets: .init(
                    top: 0,
                    left: 8,
                    bottom: 8,
                    right: 8
                )
            )
        )
        self.presenter.present(sheet, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.snackbarTime) {
            self.presenter.dismiss(sheet)
        }
    }

    private func isLocalLimitToShowNotReached(factory: Factory) -> Bool {
        guard let userId, let limit = factory.groupSubscriptionsLimit else {
            return true
        }
        if let info = factory.rootContainer.subscriptionStorageService
            .getSubscriptionInfo(forUserId: userId)
        {
            return info.subscriptionShownHistory.filter {
                $0 > Date.addingOrSubtractingDaysFromNow(-Int(limit.periodInDays))
            }.count < limit.maxSubscriptionsToShow
        }
        return limit.maxSubscriptionsToShow >= 0
    }
}

/// Ошибки при подписке на сообщество
public enum GroupSubscriptionError: Error {
    // Пользователь закрыл окно с подпиской
    case closedByUser
    // Пользователь отменил подписку
    case canceledByUser
    // Не валидный 'Access Token'
    case invalidAccessToken
    // Ошибка подписки на сообщество
    case failedSubscription
    // Ошибка создания вью контроллера с данными по сообществу
    case failedToCreate(GroupSubscriptionSheetCreationError)
    // Неизвестная ошибка
    case unknown
}

/// Результат подписки на сообщество
public typealias GroupSubscriptionResult = Result<Void, GroupSubscriptionError>
public typealias GroupSubscriptionCompletion = (GroupSubscriptionResult) -> Void

internal final class UserSessionAccessTokenProvider: AuthorizationProviding {
    typealias Authorizer = UserSession
    var authorizer: Authorizer

    func getAuthorizer(needToRefresh: Bool, completion: @escaping (Result<Authorization, Error>) -> Void) {
        self.authorizer.getFreshAccessToken(
            forceRefresh: needToRefresh,
            completion: { _ in
                completion(.success(.userSession(self.authorizer)))
            }
        )
    }

    init(userSession: UserSession) {
        self.authorizer = userSession
    }
}

internal final class ExternalAccessTokenProvider: AuthorizationProviding {
    typealias Authorizer = String

    private let handler: (_ needToRefresh: Bool, _ completion: @escaping (Result<String, Error>) -> Void) -> Void

    func getAuthorizer(needToRefresh: Bool, completion: @escaping (Result<Authorization, Error>) -> Void) {
        self.handler(needToRefresh) { result in
            switch result {
            case.success(let accessToken):
                completion(.success(.externalAccessToken(accessToken)))
            case.failure(let error):
                completion(.failure(error))
            }
        }
    }

    init(handler: @escaping (_: Bool, @escaping (Result<String, Error>) -> Void) -> Void) {
        self.handler = handler
    }
}

internal protocol AuthorizationProviding {
    associatedtype Authorizer
    func getAuthorizer(needToRefresh: Bool, completion: @escaping (Result<Authorization, Error>) -> Void)
}

/// Конфигурация для автоматического показа подписки после авторизации в VK ID SDK
public struct GroupSubscriptionConfiguration {
    public private(set) var subscribeToGroupId: String
    public private(set) var onCompleteSubscription: GroupSubscriptionCompletion?
    public private(set) var buttonType: ButtonType
    public private(set) var sheetCornerRadius: CGFloat
    internal var presenter: UIKitPresenter = .newUIWindow
    internal var inheritedButtonConfig: GroupSubscriptionSheet.ButtonConfiguration = .init()
    internal var theme: GroupSubscriptionSheet.Theme = .matchingColorScheme(.current)

    /// Создает конфигурацию для автоматического показа подписки на сообщество
    /// - Parameters:
    ///   - subscribeToGroupId: идентификатор сообщества
    ///   - onCompleteSubscription: Колбек с результатом подписки
    ///   - buttonType: настройка кнопок
    ///   - sheetCornerRadius: радиус скругления модального окна
    public init(
        subscribeToGroupId: String,
        onCompleteSubscription: GroupSubscriptionCompletion? = nil,
        buttonType: ButtonType = .inheritedOrDefault,
        sheetCornerRadius: CGFloat = 24.0
    ) {
        self.subscribeToGroupId = subscribeToGroupId
        self.onCompleteSubscription = onCompleteSubscription
        self.buttonType = buttonType
        self.sheetCornerRadius = sheetCornerRadius
    }
}

// Настройка кнопок для подписки на сообщество для автоматического показа
extension GroupSubscriptionConfiguration {
    public enum ButtonType {
        /// Конфигурация кнопки будет подтянута из текущей конфигурации OneTap, OneTapBottomSheet или OAuthListWidget.
        case inheritedOrDefault
        /// Кастомизация кнопки
        case custom(GroupSubscriptionSheet.ButtonConfiguration)
    }
}

extension Authorization {
    fileprivate var authorizer: Authorizer {
        switch self {
        case .userSession(let session): .session(userId: session.userId.value)
        case .externalAccessToken(let token): .externalAccessToken(token)
        }
    }
}
