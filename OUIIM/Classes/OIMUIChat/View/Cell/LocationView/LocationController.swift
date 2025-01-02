
import Foundation

final class LocationController: CellBaseController {
    
    weak var view: LocationView? {
        didSet {
            view?.reloadData()
        }
    }
    
    var mapURL: String?
    var address: String?
    var name: String?
    
    private var source: LocationMessageSource!
    
    init(source: LocationMessageSource, messageID: String, bubbleController: BubbleController) {
        super.init(messageID: messageID, bubbleController: bubbleController)
        
        self.source = source
        configData()
    }
    
    private func configData() {
        mapURL = source.url?.absoluteString
        address = source.address
        name = source.name
    }
    
    func action() {
        onTap?(.location(source))
    }
}
