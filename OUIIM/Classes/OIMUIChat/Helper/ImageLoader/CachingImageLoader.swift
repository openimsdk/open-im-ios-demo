
import Foundation
import UIKit

public protocol ImageLoader {

    func loadImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void)
}


let loader = CachingImageLoader(cache: imageCache, loader: DefaultImageLoader())


public struct CachingImageLoader<C: AsyncKeyValueCaching>: ImageLoader where C.CachingKey == CacheableImageKey, C.Entity == UIImage {

    private let cache: C

    private let loader: ImageLoader

    public init(cache: C, loader: ImageLoader) {
        self.cache = cache
        self.loader = loader
    }

    public func loadImage(from url: URL,
                          completion: @escaping (Result<UIImage, Error>) -> Void) {
        let imageKey = CacheableImageKey(url: url)
        cache.getEntity(for: imageKey, completion: { result in
            guard case .failure = result else {
                completion(result)
                return
            }
            self.loader.loadImage(from: url, completion: { result in
                switch result {
                case let .success(image):
                    try? self.cache.store(entity: image, for: imageKey)
                    completion(.success(image))
                case .failure:
                    completion(result)
                }
            })
        })
    }

}
