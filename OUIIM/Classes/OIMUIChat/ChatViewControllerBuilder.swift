import Foundation
import UIKit
import OUICore

public struct ChatViewControllerBuilder {

    // anchorMessageID 搜索消息，跳转到聊天记录，使用。
    public func build(_ conversation: ConversationInfo, anchorID: String? = nil) -> UIViewController {
        let dataProvider = DefaultDataProvider(conversation: conversation, anchorID: anchorID)
        let messageController = DefaultChatController(dataProvider: dataProvider,
                                                      senderID: IMController.shared.uid,
                                                      receiverId: conversation.conversationType == .c2c ?
                                                      conversation.userID! : conversation.groupID!,
                                                      conversationType: conversation.conversationType,
                                                      conversation: conversation)
        dataProvider.delegate = messageController
        
        let editNotifier = EditNotifier()
        let swipeNotifier = SwipeNotifier()
        let extractedExpr = DefaultChatCollectionDataSource(editNotifier: editNotifier,
                                                            swipeNotifier: swipeNotifier,
                                                            reloadDelegate: messageController,
                                                            editingDelegate: messageController)
        let dataSource = extractedExpr

        
        let messageViewController = ChatViewController(chatController: messageController,
                                                       dataSource: dataSource,
                                                       editNotifier: editNotifier,
                                                       swipeNotifier: swipeNotifier)
        messageController.delegate = messageViewController
        
        return messageViewController
    }
    
    public init() {}
}
