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

import XCTest
@testable import VKID

final class AuthURLBuilderTests: XCTestCase {
    private var builder: AuthURLBuilder!

    private let secrets = PKCESecrets(
        codeVerifier: "test_code_vefifier_1@3$5",
        codeChallenge: "test_code_challenge_1@3$5",
        codeChallengeMethod: .sha256
    )
    private let credentials = AppCredentials(clientId: "test_client_id_1@3$5", clientSecret: "test_client_secret_1@3$5")

    override func setUpWithError() throws {
        self.builder = AuthURLBuilderImpl()
    }

    override func tearDownWithError() throws {
        self.builder = nil
    }

    func testBuildProviderAuthURLInvalidURLString() {
        let secrets = PKCESecrets(codeVerifier: "", codeChallenge: "", codeChallengeMethod: .sha256)
        let credentials = AppCredentials(clientId: "", clientSecret: "")
        XCTAssertThrowsError(
            try self.builder.buildProviderAuthURL(
                from: "http://example.com:-80/",
                with: secrets,
                credentials: credentials
            )
        ) { error in
            guard case AuthFlowError.invalidAuthConfigTemplateURL = error
            else { return XCTFail("Invalid error type/class - \(error)") }
        }
    }

    func testBuildProviderAuthURLWithValidParameters() {
        do {
            let result = try builder.buildProviderAuthURL(
                from: "http://example.com/",
                with: self.secrets,
                credentials: self.credentials
            )

            let urlComponents = URLComponents(url: result, resolvingAgainstBaseURL: true)
            let commonQueryItems = createCommonQueryItems(secrets: secrets, credentials: credentials)
            let expectedQueryItems = commonQueryItems + [
                .authProviderMethod,
                .init(
                    name: "client_id",
                    value: credentials.clientId
                ),
            ]
            XCTAssertEqual(urlComponents?.queryItems, expectedQueryItems)

            let expectedURL =
                URL(
                    string: "http://example.com/?redirect_uri=vk\(credentials.clientId)://vk.com/blank.html&response_type=code&state=\(self.secrets.state)&code_challenge=\(self.secrets.codeChallenge)&code_challenge_method=\(self.secrets.codeChallengeMethod)&vkconnect_auth_provider_method=external_auth&client_id=\(self.credentials.clientId)"
                )
            XCTAssertEqual(expectedURL, result)
        } catch {
            XCTFail("Error in build URL from valid string: \(error)")
        }
    }

    func testBuildProviderAuthURLWithEmptyParameters() {
        do {
            let secrets = PKCESecrets(codeVerifier: "", codeChallenge: "", codeChallengeMethod: .sha256)
            let credentials = AppCredentials(clientId: "", clientSecret: "")

            let result = try builder.buildProviderAuthURL(from: "", with: secrets, credentials: credentials)

            let urlComponents = URLComponents(url: result, resolvingAgainstBaseURL: true)
            let commonQueryItems = createCommonQueryItems(secrets: secrets, credentials: credentials)
            let expectedQueryItems = commonQueryItems + [
                .authProviderMethod,
                .init(
                    name: "client_id",
                    value: credentials.clientId
                ),
            ]
            XCTAssertEqual(urlComponents?.queryItems, expectedQueryItems)

            let expectedURL =
                URL(
                    string: "?redirect_uri=vk\(credentials.clientId)://vk.com/blank.html&response_type=code&state=\(secrets.state)&code_challenge=\(secrets.codeChallenge)&code_challenge_method=\(secrets.codeChallengeMethod)&vkconnect_auth_provider_method=external_auth&client_id=\(credentials.clientId)"
                )
            XCTAssertEqual(expectedURL, result)
        } catch {
            XCTFail("Error in build URL from valid string: \(error)")
        }
    }

    func testBuildWebViewAuthURLInvalidURLString() {
        let appearance = Appearance()

        XCTAssertThrowsError(
            try self.builder.buildWebViewAuthURL(
                from: "http://example.com:-80/",
                with: self.secrets,
                credentials: self.credentials,
                appearance: appearance
            )
        ) { error in
            guard case AuthFlowError.invalidAuthConfigTemplateURL = error
            else { return XCTFail("Invalid error type/class - \(error)") }
        }
    }

    func testBuildWebViewAuthURLWithValidParameters() {
        do {
            let appearance = Appearance(colorScheme: .dark, locale: .ru)

            let result = try builder.buildWebViewAuthURL(
                from: "http://example.com/",
                with: self.secrets,
                credentials: self.credentials,
                appearance: appearance
            )

            let urlComponents = URLComponents(url: result, resolvingAgainstBaseURL: true)
            let commonQueryItems = createCommonQueryItems(secrets: secrets, credentials: credentials)
            let expectedQueryItems = commonQueryItems + [
                .init(
                    name: "scheme",
                    value: "space_gray"
                ),
                .init(
                    name: "lang_id",
                    value: "0"
                ),
            ]
            XCTAssertEqual(urlComponents?.queryItems, expectedQueryItems)

            let expectedURL =
                URL(
                    string: "http://example.com/?redirect_uri=vk\(credentials.clientId)://vk.com/blank.html&response_type=code&state=\(self.secrets.state)&code_challenge=\(self.secrets.codeChallenge)&code_challenge_method=\(self.secrets.codeChallengeMethod)&scheme=space_gray&lang_id=0"
                )
            XCTAssertEqual(expectedURL, result)
        } catch {
            XCTFail("Error in build URL from valid string: \(error)")
        }
    }

    func testBuildWebViewAuthURLEmptyQueryItems() {
        do {
            let secrets = PKCESecrets(codeVerifier: "", codeChallenge: "", codeChallengeMethod: .sha256)
            let credentials = AppCredentials(clientId: "", clientSecret: "")
            let appearance = Appearance(colorScheme: .light, locale: .en)

            let result = try builder.buildWebViewAuthURL(
                from: "",
                with: secrets,
                credentials: credentials,
                appearance: appearance
            )

            let urlComponents = URLComponents(url: result, resolvingAgainstBaseURL: true)
            let commonQueryItems = createCommonQueryItems(secrets: secrets, credentials: credentials)
            let expectedQueryItems = commonQueryItems + [
                .init(
                    name: "scheme",
                    value: "bright_light"
                ),
                .init(
                    name: "lang_id",
                    value: "3"
                ),
            ]
            XCTAssertEqual(urlComponents?.queryItems, expectedQueryItems)

            let expectedURL =
                URL(
                    string: "?redirect_uri=vk\(credentials.clientId)://vk.com/blank.html&response_type=code&state=\(secrets.state)&code_challenge=\(secrets.codeChallenge)&code_challenge_method=\(secrets.codeChallengeMethod)&scheme=bright_light&lang_id=3"
                )
            XCTAssertEqual(expectedURL, result)
        } catch {
            XCTFail("Error in build URL from valid string: \(error)")
        }
    }
}

extension AuthURLBuilderTests {
    private func createCommonQueryItems(secrets: PKCESecrets, credentials: AppCredentials) -> [URLQueryItem] {
        [
            .init(name: "redirect_uri", value: redirectURL(for: credentials.clientId).absoluteString),
            .init(name: "response_type", value: "code"),
            .init(name: "state", value: secrets.state),
            .init(name: "code_challenge", value: secrets.codeChallenge),
            .init(name: "code_challenge_method", value: secrets.codeChallengeMethod.rawValue),
        ]
    }
}
