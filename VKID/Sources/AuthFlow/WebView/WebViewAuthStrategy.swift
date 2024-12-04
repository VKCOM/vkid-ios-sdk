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

import AuthenticationServices
import Foundation
import SafariServices
import VKIDCore

internal protocol WebViewAuthStrategy {
    func authInWebView(
        at authURL: URL,
        redirectURL: URL,
        presenter: UIKitPresenter,
        completion: @escaping (Result<AuthCodeResponse, AuthFlowError>) -> Void
    )
}

internal final class WebAuthenticationSessionStrategy: NSObject, WebViewAuthStrategy {
    internal struct Dependencies: Dependency {
        let responseParser: AuthCodeResponseParser
        let applicationManager: ApplicationManager
    }

    private var authSession: ASWebAuthenticationSession?
    private var subscribeToken: NSObjectProtocol?
    private var presenter: UIKitPresenter?

    private let deps: Dependencies

    init(deps: Dependencies) {
        self.deps = deps
    }

    deinit {
        self.unsubscribeFromAppDidEnterBackground()
    }

    func authInWebView(
        at authURL: URL,
        redirectURL: URL,
        presenter: UIKitPresenter,
        completion: @escaping (Result<AuthCodeResponse, AuthFlowError>) -> Void
    ) {
        func complete(with result: Result<AuthCodeResponse, AuthFlowError>) {
            self.unsubscribeFromAppDidEnterBackground()
            completion(result)
        }

        guard let redirectScheme = redirectURL.scheme else {
            complete(with: .failure(.invalidRedirectURL(redirectURL)))
            return
        }

        self.presenter = presenter

        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: redirectScheme
        ) { [weak self] url, error in
            guard let self else { return }

            if let error {
                if let sessionError = error as? ASWebAuthenticationSessionError {
                    switch sessionError.code {
                    case .canceledLogin:
                        complete(with: .failure(.authCancelledByUser))
                    // При некорректно указанном провайдере срабатывает callbackURLScheme,
                    // но все равно запускает авторизацию, отлавливаем явно эту ошибку, чтобы не остановить процесс.
                    case .presentationContextInvalid:
                        break
                    case .presentationContextNotProvided:
                        complete(with: .failure(.webViewAuthSessionFailedToStart))
                    @unknown default:
                        complete(with: .failure(.webViewAuthSessionFailedToStart))
                    }
                } else {
                    complete(with: .failure(.webViewAuthFailed(error)))
                }
            } else if let url {
                do {
                    let response = try self.deps.responseParser.parseAuthCodeResponse(from: url)
                    complete(with: .success(response))
                } catch let e as AuthFlowError {
                    complete(with: .failure(e))
                } catch {
                    complete(with: .failure(.invalidAuthCallbackURL))
                }
            } else {
                complete(with: .failure(.invalidAuthCallbackURL))
            }
        }

        if #available(iOS 13.0, *) {
            session.presentationContextProvider = self
        }

        guard session.start() else {
            complete(with: .failure(.webViewAuthSessionFailedToStart))
            return
        }

        self.authSession = session

        /// При блокировке экрана системный алерт авторизации пропадает, не вызывая никаких коллбэков
        /// Здесь отлавливаем этот случай
        self.subscribeToken = self.subscribeOnAppDidEnterBackground {
            if !self.deps.applicationManager.isTopMostViewControllerSafariController {
                session.cancel()
                complete(with: .failure(.authCancelledByUser))
            }
        }
    }

    private func subscribeOnAppDidEnterBackground(_ completion: @escaping () -> Void) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .current
        ) { _ in
            completion()
        }
    }

    private func unsubscribeFromAppDidEnterBackground() {
        self.subscribeToken.map(NotificationCenter.default.removeObserver)
        self.subscribeToken = nil
    }
}

@available(iOS 13.0, *)
extension WebAuthenticationSessionStrategy: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        self.deps.applicationManager.activeWindow ?? ASPresentationAnchor()
    }
}

internal final class SafariViewControllerStrategy: NSObject, WebViewAuthStrategy {
    internal struct Dependencies: Dependency {
        let appInteropHandler: AppInteropCompositeHandling
        let responseParser: AuthCodeResponseParser
    }

    private var completion: ((Result<AuthCodeResponse, AuthFlowError>) -> Void)?
    private var callbackHandler: ClosureBasedURLHandler?

    private let deps: Dependencies

    init(deps: Dependencies) {
        self.deps = deps
    }

    func authInWebView(
        at authURL: URL,
        redirectURL: URL,
        presenter: UIKitPresenter,
        completion: @escaping (Result<AuthCodeResponse, AuthFlowError>) -> Void
    ) {
        let safari = SFSafariViewController(url: authURL)
        safari.delegate = self
        presenter.present(safari)

        let handler = ClosureBasedURLHandler { [weak self] url in
            safari.dismiss(animated: true)
            guard let self else {
                return false
            }
            do {
                let response = try self.deps.responseParser.parseAuthCodeResponse(from: url)
                self.complete(with: .success(response))
            } catch let e as AuthFlowError {
                self.complete(with: .failure(e))
            } catch {
                self.complete(with: .failure(.invalidAuthCallbackURL))
            }
            return true
        }

        self.deps.appInteropHandler.attach(handler: handler)
        self.completion = completion
        self.callbackHandler = handler
    }

    private func complete(with result: Result<AuthCodeResponse, AuthFlowError>) {
        self.completion?(result)
        self.completion = nil
        self.callbackHandler.map(self.deps.appInteropHandler.detach(handler:))
        self.callbackHandler = nil
    }
}

extension SafariViewControllerStrategy: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.complete(with: .failure(.authCancelledByUser))
    }
}
