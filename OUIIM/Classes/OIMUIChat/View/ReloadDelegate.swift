
import Foundation

protocol ReloadDelegate: AnyObject {

    func reloadMessage(with id: String)
    func resendMessage(messageID: String)
    func removeMessage(messageID: String, completion:(() -> Void)?)
}

extension ReloadDelegate {
    func resendMessage(_: String) {}
    func removeMessage(_: String) {}
}

protocol GestureDelegate: AnyObject {
    func longPress(with message: Message, sourceView: UIView, point: CGPoint)
    func onTapEdgeAligningView()

    func didTapAvatar(with user: User)
    func didTapContent(with id: String, data: Message.Data)
}

extension GestureDelegate {
    func longPress(with _: String, _: UIView, _: CGPoint) {}
    func onTapEdgeAligningView() {}

    func didTapAvatar(with _: User) {}
    func didTapContent(with _: String, _: Message.Data) {}
}
