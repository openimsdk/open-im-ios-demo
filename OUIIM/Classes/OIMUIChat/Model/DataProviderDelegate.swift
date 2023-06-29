
import OUICore

protocol DataProviderDelegate: AnyObject {

    func received(message: MessageInfo)
    
    func typingStateChanged(to state: TypingState)

    func lastReadIdsChanged(to ids: [String], readUserID: String?)

    func lastReceivedIdChanged(to id: String)
    
    func isInGroup(with isIn: Bool)
}
