//
// Copyright (c) 2024 - present, LLC “V Kontakte”
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
@testable import VKIDCore

final class VKIDSSLPinningTests: XCTestCase {
    private var api: VKAPI<Auth>!
    private var appCredentials: AppCredentials!

    override func setUpWithError() throws {
        let env = ProcessInfo.processInfo.environment
        guard
            let clientId = env["VKID_DEMO_IOS_CLIENT_ID"],
            let clientSecret = env["VKID_DEMO_IOS_CLIENT_SECRET"]
        else {
            XCTFail("VKID_DEMO_IOS_CLIENT_ID and VKID_DEMO_IOS_CLIENT_SECRET are not provided")
            return
        }

        self.appCredentials = AppCredentials(
            clientId: clientId,
            clientSecret: clientSecret
        )
        let transport = URLSessionTransport(
            urlRequestBuilder: URLRequestBuilder(
                apiHosts: APIHosts(hostname: Env.apiHost)
            ),
            genericParameters: VKAPIGenericParameters(
                deviceId: DeviceId.currentDeviceId.description,
                clientId: self.appCredentials.clientId,
                apiVersion: Env.VKAPIVersion,
                vkidVersion: Env.VKIDVersion
            ),
            defaultHeaders: [
                "User-Agent": "\(UserAgent.default) VKID/\(Env.VKIDVersion)",
            ],
            sslPinningConfiguration: .init(domains: [.vkcom])
        )
        self.api = .init(transport: transport)
    }

    override func tearDownWithError() throws {
        self.api = nil
        self.appCredentials = nil
    }

    func testRequestIsCancelledIfTrafficIsSniffed() {
        let requestCompleted = self.expectation(description: "Request completed")

        self.api
            .getAnonymousToken
            .execute(with: .init(
                anonymousToken: nil,
                clientId: self.appCredentials.clientId,
                clientSecret: self.appCredentials.clientSecret
            )) { result in
                switch result {
                case .failure(.cancelled):
                    XCTAssertTrue(true, "Expected behaviour, request cancelled.")
                default:
                    XCTFail("Request should be cancelled")
                }
                requestCompleted.fulfill()
            }

        self.wait(for: [requestCompleted], timeout: 60)
    }

    func testRequestIsSucceededIfTrafficIsNotSniffed() {
        let requestCompleted = self.expectation(description: "Request completed")

        self.api
            .getAnonymousToken
            .execute(with: .init(
                anonymousToken: nil,
                clientId: self.appCredentials.clientId,
                clientSecret: self.appCredentials.clientSecret
            )) { result in
                switch result {
                case .success:
                    XCTAssertTrue(true, "Expected behaviour, request successfully completed.")
                default:
                    XCTFail("Request should complete successfully")
                }
                requestCompleted.fulfill()
            }

        self.wait(for: [requestCompleted], timeout: 60)
    }
}
