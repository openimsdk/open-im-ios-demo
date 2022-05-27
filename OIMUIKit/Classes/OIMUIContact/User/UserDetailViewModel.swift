





import Foundation

class UserDetailViewModel {
    var userId: String?
    
    func createSingleChat(onComplete: @escaping (MessageListViewModel) -> Void) {
        guard let userId = userId else {
            return
        }

        IMController.shared.getConversation(sessionType: .c2c, sourceId: userId) { (conversation: ConversationInfo?) in
            guard let conversation = conversation else {
                return
            }

            let model = MessageListViewModel.init(userId: userId, conversation: conversation)
            onComplete(model)
        }
    }
}
