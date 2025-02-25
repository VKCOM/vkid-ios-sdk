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

package final class ImageLoader {
    package typealias ImageResult = Result<(image: UIImage, url: URL), ImageLoadingError>

    // MARK: - LoadingError

    package enum ImageLoadingError: Error {
        case imageNotLoaded
        case dataIsCorrupted
        case unknown
    }

    package static let shared: ImageLoader = .init()

    private let lock: NSLock
    private let cache: URLCache
    private let session: URLSession

    private init() {
        self.lock = NSLock()
        self.cache = URLCache()

        let config = URLSessionConfiguration.default
        config.urlCache = self.cache
        config.requestCachePolicy = .reloadRevalidatingCacheData
        config.httpMaximumConnectionsPerHost = 5

        self.session = URLSession(configuration: config)
    }

    package func getImage(for url: URL, completion: @escaping (ImageResult) -> Void) {
        self.lock.lock()

        let request = URLRequest(url: url)

        if let image = cachedImage(with: request) {
            self.lock.unlock()
            completion(
                .success((image: image, url: url))
            )
        } else {
            self.session.dataTask(
                with: request,
                completionHandler: { [weak self] data, response, error in
                    defer { self?.lock.unlock() }

                    guard error == nil, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                        completion(.failure(.imageNotLoaded))
                        return
                    }

                    guard let data, let image = UIImage(data: data) else {
                        completion(.failure(.dataIsCorrupted))
                        return
                    }

                    completion(.success((image: image, url: url)))
                }
            ).resume()
        }
    }

    package func cachedImage(with request: URLRequest) -> UIImage? {
        let data = self.cache.cachedResponse(for: request)?.data
        return data.flatMap(UIImage.init)
    }

    package func clearStorage() {
        self.cache.removeAllCachedResponses()
    }
}
