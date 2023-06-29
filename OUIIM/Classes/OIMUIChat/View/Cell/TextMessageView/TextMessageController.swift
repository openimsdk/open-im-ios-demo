
import Foundation

final class TextMessageController {

    weak var view: TextMessageView? {
        didSet {
            view?.reloadData()
        }
    }

    let text: String?
    
    let attributedString: NSAttributedString?

    let type: MessageType
    
    var highlight: Bool = false

    private let bubbleController: BubbleController

    init(text: String? = nil, attributedString: NSAttributedString? = nil, highlight: Bool = false, type: MessageType, bubbleController: BubbleController) {
        self.text = text
        self.attributedString = attributedString
        self.highlight = highlight
        self.type = type
        self.bubbleController = bubbleController
    }
}
