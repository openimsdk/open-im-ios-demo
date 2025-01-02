import Foundation
import OUICore

protocol ChatControllerDelegate: AnyObject {
    func isInGroup(with isIn: Bool)
    func update(with sections: [Section], requiresIsolatedProcess: Bool)
    func updateUnreadCount(count: Int)
    func didTapContent(with id: String, data: Message.Data)
    func onlineStatus(status: UserStatusInfo)
    func groupInfoChanged(info: GroupInfo)
    func friendInfoChanged(info: FriendInfo)
    func typingStateChanged(to state: TypingState)
}

extension ChatControllerDelegate {
    func isInGroup(with _: Bool) {}
    func updateUnreadCount(_: Int) {}
    func didTapContent(with _: String, _:  Message.Data) {}
    func onlineStatus(_: UserStatusInfo) {}
    func groupInfoChanged(_: GroupInfo) {}
    func friendInfoChanged(_: FriendInfo) {}
    func typingStateChanged(to state: TypingState) {}
}
