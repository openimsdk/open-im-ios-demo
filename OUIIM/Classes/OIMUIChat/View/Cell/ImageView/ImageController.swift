import Foundation
import UIKit

final class ImageController {

    weak var view: ImageView? {
        didSet {
            view?.reloadData()
        }
    }

    weak var delegate: ReloadDelegate?
    
    var state: ImageViewState {
        guard let image else {
            return .loading
        }
        return .image(image)
    }

    private var image: UIImage?

    private let messageId: String

    private let source: MediaMessageSource

    private let bubbleController: BubbleController

    init(source: MediaMessageSource, messageId: String, bubbleController: BubbleController) {
        self.source = source
        self.messageId = messageId
        self.bubbleController = bubbleController
        loadImage()
    }
    
    private func loadImage() {
        if let image = source.image {
            self.image = image
            view?.reloadData()
        } else {
            guard let url = source.source.url else { return }
            if let image = try? imageCache.getEntity(for: .init(url: url)) {
                self.image = image
                view?.reloadData()
            } else {
                loader.loadImage(from: url) { [weak self] _ in
                    guard let self else {
                        return
                    }
                    
                    self.delegate?.reloadMessage(with: self.messageId)
                }
            }
        }
    }

    func action() {
        delegate?.didTapContent(with: messageId, data: .image(source, isLocallyStored: true))
    }
}
