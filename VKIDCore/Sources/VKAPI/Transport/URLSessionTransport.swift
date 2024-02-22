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

import Foundation

public final class URLSessionTransport: NSObject, VKAPITransport {
    private let urlRequestBuilder: URLRequestBuilding
    private let requestInterceptors: [VKAPIRequestInterceptor]
    private let responseInterceptors: [VKAPIResponseInterceptor]
    private let genericParameters: VKAPIGenericParameters
    private let defaultHeaders: VKAPIRequest.Headers
    private let sslPinningValidator: SSLPinningValidating
    private let logger: Logging
    private let processingQueue: DispatchQueue
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    private lazy var session: URLSession = {
        let delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1 // make serial
        delegateQueue.underlyingQueue = self.processingQueue
        return URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: delegateQueue
        )
    }()

    public init(
        urlRequestBuilder: URLRequestBuilding,
        requestInterceptors: [VKAPIRequestInterceptor] = [],
        responseInterceptors: [VKAPIResponseInterceptor] = [],
        genericParameters: VKAPIGenericParameters,
        defaultHeaders: [String: String],
        sslPinningConfiguration: SSLPinningConfiguration,
        logger: Logging = Logger(subsystem: "VKAPI")
    ) {
        self.urlRequestBuilder = urlRequestBuilder
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
        self.genericParameters = genericParameters
        self.defaultHeaders = defaultHeaders
        self.sslPinningValidator = SSLPinningValidator(configuration: sslPinningConfiguration)
        self.logger = logger
        self.processingQueue = DispatchQueue(label: "com.vkid.core.transport.processingQueue")
    }

    public func execute<T: VKAPIResponse>(
        request: VKAPIRequest,
        callbackQueue: DispatchQueue,
        completion: @escaping (Result<T, VKAPIError>) -> Void
    ) {
        let internalCompletion = { (result: Result<T, VKAPIError>) in
            callbackQueue.async {
                completion(result)
            }
        }

        self.processingQueue.async {
            var mutableRequest = request
            mutableRequest.add(parameters: self.genericParameters.dictionaryRepresentation)
            mutableRequest.add(headers: self.defaultHeaders, overwriteIfAlreadyExists: false)
            self.requestInterceptors.intercept(
                request: mutableRequest
            ) { [weak self] result in
                guard let self else { return }

                self.processingQueue.async {
                    do {
                        let interceptedRequest = try result.get()
                        self.logger.info(
                            "Ready to start: \(interceptedRequest.id) \(interceptedRequest.path)"
                        )
                        let urlRequest = try self.urlRequestBuilder.buildURLRequest(from: interceptedRequest)
                        self.execute(
                            urlRequest,
                            for: interceptedRequest
                        ) {
                            self.interceptResponse(
                                $0,
                                from: interceptedRequest,
                                completion: internalCompletion
                            )
                        }
                    } catch {
                        self.interceptResponse(
                            .failure(error as? VKAPIError ?? .unknown),
                            from: (try? result.get()) ?? mutableRequest,
                            completion: internalCompletion
                        )
                    }
                }
            }
        }
    }

    private func interceptResponse<T: VKAPIResponse>(
        _ response: Result<T, VKAPIError>,
        from request: VKAPIRequest,
        completion: @escaping (Result<T, VKAPIError>) -> Void
    ) {
        dispatchPrecondition(condition: .onQueue(self.processingQueue))

        self.responseInterceptors.intercept(
            response: response,
            from: request
        ) { result in
            switch result {
            case .continue(_, response: let resp):
                completion(resp)
            case .retry(request: let request):
                self.execute(request: request, completion: completion)
            case .interrupt(error: let error):
                completion(.failure(error))
            }
        }
    }

    private func execute<T: VKAPIResponse>(
        _ urlRequest: URLRequest,
        for request: VKAPIRequest,
        completion: @escaping (Result<T, VKAPIError>) -> Void
    ) {
        dispatchPrecondition(condition: .onQueue(self.processingQueue))

        self.logger.info("\(request.id) starting...")

        let task = self.session.dataTask(
            with: urlRequest
        ) { data, response, error in
            dispatchPrecondition(condition: .onQueue(self.processingQueue))

            if let error {
                self.logger.error("\(request.id) failed with error: \(error)")
                completion(.failure(.networkConnectionFailed(error)))
                return
            }
            guard let data else {
                self.logger.error("\(request.id) server returned no data")
                completion(.failure(.noResponseDataProvided))
                return
            }

            self.logger.info("\(request.id) successfully completed")

            do {
                let decoded: T
                switch request.host {
                case .id:
                    decoded = try self.handleIdHostResponse(
                        response as? HTTPURLResponse,
                        data: data
                    )
                case .api:
                    decoded = try self.handleAPIHostResponse(
                        response as? HTTPURLResponse,
                        data: data
                    )
                case .oauth:
                    decoded = try self.handleOAuthHostResponse(
                        response as? HTTPURLResponse,
                        data: data
                    )
                }
                completion(.success(decoded))
            } catch let error as VKAPIError {
                completion(.failure(error))
            } catch {
                completion(.failure(.responseDecodingFailed(error)))
            }
        }
        task.resume()
    }

    private func handleAPIHostResponse<T: VKAPIResponse>(
        _ response: HTTPURLResponse?,
        data: Data
    ) throws -> T {
        dispatchPrecondition(condition: .onQueue(self.processingQueue))

        let apiResponse = try jsonDecoder.decode(
            APIHostResponse<T>.self,
            from: data
        )
        switch apiResponse {
        case .response(let resp):
            return resp
        case .error(let err):
            throw err.apiError
        }
    }

    private func handleOAuthHostResponse<T: VKAPIResponse>(
        _ response: HTTPURLResponse?,
        data: Data
    ) throws -> T {
        dispatchPrecondition(condition: .onQueue(self.processingQueue))

        if let response, response.statusCode >= 400 {
            let error = try self.jsonDecoder.decode(
                OAuthHostErrorResponse.self,
                from: data
            )
            throw error.apiError
        } else {
            return try self.jsonDecoder.decode(T.self, from: data)
        }
    }

    private func handleIdHostResponse<T: VKAPIResponse>(
        _ response: HTTPURLResponse?,
        data: Data
    ) throws -> T {
        dispatchPrecondition(condition: .onQueue(self.processingQueue))

        return try self.jsonDecoder.decode(T.self, from: data)
    }
}

extension URLSessionTransport: URLSessionDelegate {
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        dispatchPrecondition(condition: .onQueue(self.processingQueue))

        let host = challenge.protectionSpace.host
        let validationResult = self.sslPinningValidator.validateChallenge(challenge)
        switch validationResult {
        case .trustedDomain(let trust):
            self.logger.info("Allow secure connection to trusted host: \(host)")
            completionHandler(.useCredential, URLCredential(trust: trust))
        case .domainNotPinned:
            self.logger.warning("\(host) is not pinned. Continue with default handling.")
            completionHandler(.performDefaultHandling, nil)
        case .noMatchingPins:
            self.logger.error("No matching pins for \(host). Canceling connection.")
            completionHandler(.cancelAuthenticationChallenge, nil)
        case .failedToProcessServerCertificate:
            self.logger.error("Failed to process server certificate for \(host)")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
