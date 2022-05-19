//






import Foundation

class UserDetailViewModel {
    var user: FullUserInfo?
    let items: [RowType] = [.remark, .identifier, .profile]
    func createSingleChat(onComplete: @escaping (MessageListViewModel) -> Void) {
        guard let userId = user?.userID else {
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
    
    enum RowType {
        case remark
        case identifier
        case profile
        
        var title: String {
            switch self {
            case .remark:
                return "备注"
            case .identifier:
                return "ID"
            case .profile:
                return "个人资料"
            }
        }
    }
}
