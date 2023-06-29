import Foundation
import UIKit

final class VideoController {

    weak var view: VideoView? {
        didSet {
            view?.reloadData()
        }
    }

    weak var delegate: ReloadDelegate?
    
    var state: VideoViewState {
        guard let image else {
            return .loading
        }
        return .image(image)
    }

    private var image: UIImage?

    private let messageId: String
    
    var duration: String?

    private let source: MediaMessageSource

    private let bubbleController: BubbleController

    init(source: MediaMessageSource, messageId: String, bubbleController: BubbleController) {
        self.source = source
        self.messageId = messageId
        self.bubbleController = bubbleController
        self.duration = #"\#(source.duration!)""#
        loadImage()
    }
    
    private func loadImage() {
        if let image = source.image {
            self.image = image
            view?.reloadData()
        } else {
            guard let url = source.thumb?.url else { return }
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
        delegate?.didTapContent(with: messageId, data: .video(source, isLocallyStored: true))
    }
}
