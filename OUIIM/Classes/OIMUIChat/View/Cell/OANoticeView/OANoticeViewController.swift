
import Foundation
import Kingfisher

final class OANoticeViewController: CellBaseController {

    weak var view: OANoticeView? {
        didSet {
            view?.reloadData()
        }
    }
        
    var source: NoticeMessageSource!
    
    init(messageID: String, source: NoticeMessageSource, bubbleController: BubbleController) {
        super.init(messageID: messageID, bubbleController: bubbleController)
        
        self.source = source
    }
    
    func action() {
        onTap?(.notice(source))
    }
}
