
import Foundation

final class CardController: CellBaseController {
    
    weak var view: CardView? {
        didSet {
            view?.reloadData()
        }
    }
    
    var faceURL: String?
    var name: String?

    private var source: CardMessageSource!
    
    init(source: CardMessageSource, messageID: String, bubbleController: BubbleController) {
        super.init(messageID: messageID, bubbleController: bubbleController)
        
        self.source = source
        configData()
    }
    
    private func configData() {
        self.name = source.user.name
        self.faceURL = source.user.faceURL
    }
    
    func action() {
        onTap?(.card(source))
    }
}
