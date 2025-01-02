import Foundation
import UIKit
import Kingfisher

final class VideoController: CellBaseController {
    
    weak var view: VideoView? {
        didSet {
            view?.reloadData()
        }
    }
    
    var size: CGSize = CGSize(width: 120, height: 120)
    var image: UIImage?
    var duration: String?
    var source: MediaMessageSource!
    
    init(source: MediaMessageSource, messageID: String, bubbleController: BubbleController) {
        super.init(messageID: messageID, bubbleController: bubbleController)
        
        self.source = source
        self.duration = formatTime(seconds: TimeInterval(source.duration ?? 0))
        
        if let size = source.thumb?.size {
            self.size = size
        }
        
        loadImage()
    }
    
    private func formatTime(seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        
        if let formattedString = formatter.string(from: seconds) {
            return formattedString
        } else {
            return "00:00:00"
        }
    }
    
    private func loadImage() {
        if let image = source.image {
            self.image = image
            view?.reloadData()
        }
    }
    
    func action() {
        onTap?(.video(source, isLocallyStored: true))
    }
}
