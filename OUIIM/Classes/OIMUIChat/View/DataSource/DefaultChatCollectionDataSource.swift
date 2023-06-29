

import ChatLayout
import Foundation
import UIKit
// 调整成右侧头像
//typealias TextMessageCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, TextMessageView, StatusView>>>
typealias TextMessageCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, TextMessageView, ChatAvatarView>>>

@available(iOS 13, *)
typealias URLCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, URLView, ChatAvatarView>>>

typealias ImageCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, ImageView, ChatAvatarView>>>
typealias VideoCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, VideoView, ChatAvatarView>>>


typealias UserTitleCollectionCell = ContainerCollectionViewCell<SwappingContainerView<EdgeAligningView<UILabel>, UIImageView>>
typealias TitleCollectionCell = ContainerCollectionViewCell<UILabel>
typealias TypingIndicatorCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<VoidViewFactory, TypingIndicator, VoidViewFactory>>>

typealias TextTitleView = ContainerCollectionReusableView<UILabel>

final class DefaultChatCollectionDataSource: NSObject, ChatCollectionDataSource {
    
    private unowned var reloadDelegate: ReloadDelegate
    
    private unowned var editingDelegate: EditingAccessoryControllerDelegate
    
    private let editNotifier: EditNotifier
    
    private let swipeNotifier: SwipeNotifier
        
    var sections: [Section] = [] {
        didSet {
            oldSections = oldValue
        }
    }
    
    private var oldSections: [Section] = []
    
    init(editNotifier: EditNotifier,
         swipeNotifier: SwipeNotifier,
         reloadDelegate: ReloadDelegate,
         editingDelegate: EditingAccessoryControllerDelegate) {
        self.reloadDelegate = reloadDelegate
        self.editingDelegate = editingDelegate
        self.editNotifier = editNotifier
        self.swipeNotifier = swipeNotifier
    }
    
    func prepare(with collectionView: UICollectionView) {
        collectionView.register(TextMessageCollectionCell.self, forCellWithReuseIdentifier: TextMessageCollectionCell.reuseIdentifier)
        collectionView.register(ImageCollectionCell.self, forCellWithReuseIdentifier: ImageCollectionCell.reuseIdentifier)
        collectionView.register(VideoCollectionCell.self, forCellWithReuseIdentifier: VideoCollectionCell.reuseIdentifier)
        
        collectionView.register(UserTitleCollectionCell.self, forCellWithReuseIdentifier: UserTitleCollectionCell.reuseIdentifier)
        collectionView.register(TitleCollectionCell.self, forCellWithReuseIdentifier: TitleCollectionCell.reuseIdentifier)
        collectionView.register(TypingIndicatorCollectionCell.self, forCellWithReuseIdentifier: TypingIndicatorCollectionCell.reuseIdentifier)
        collectionView.register(TextTitleView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TextTitleView.reuseIdentifier)
        collectionView.register(TextTitleView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: TextTitleView.reuseIdentifier)
        if #available(iOS 13.0, *) {
            collectionView.register(URLCollectionCell.self, forCellWithReuseIdentifier: URLCollectionCell.reuseIdentifier)
        }
    }
    
    private func createTextCell(collectionView: UICollectionView,
                                messageId: String,
                                isSelected: Bool,
                                indexPath: IndexPath,
                                text: String? = nil,
                                attributedString: NSAttributedString? = nil,
                                anchor: Bool = false,
                                date: Date,
                                alignment: ChatItemAlignment,
                                user: User,
                                bubbleType: Cell.BubbleType,
                                status: MessageStatus,
                                messageType: MessageType) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextMessageCollectionCell.reuseIdentifier, for: indexPath) as! TextMessageCollectionCell
        
        setupMessageContainerView(cell.customView, messageId: messageId, isSelected: isSelected, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: user, messageID: messageId, alignment: alignment, bubble: bubbleType, status: status)
        setupSwipeHandlingAccessory(cell.customView.customView, date: date, accessoryConnectingView: cell.customView)
        
        let bubbleView = cell.customView.customView.customView
        let controller = TextMessageController(text: text,
                                               attributedString: attributedString,
                                               highlight: anchor,
                                               type: messageType,
                                               bubbleController: buildTextBubbleController(bubbleView: bubbleView,
                                                                                           messageType: messageType,
                                                                                           bubbleType: bubbleType))
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.delegate = bubbleView.customView
        
        return cell
    }
    
    @available(iOS 13, *)
    private func createURLCell(collectionView: UICollectionView, messageId: String, isSelected: Bool, indexPath: IndexPath, url: URL, date: Date, alignment: ChatItemAlignment, user: User, bubbleType: Cell.BubbleType, status: MessageStatus, messageType: MessageType) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: URLCollectionCell.reuseIdentifier, for: indexPath) as! URLCollectionCell
        setupMessageContainerView(cell.customView, messageId: messageId, isSelected: isSelected, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: user, messageID: messageId, alignment: alignment, bubble: bubbleType, status: status)
        
        setupSwipeHandlingAccessory(cell.customView.customView, date: date, accessoryConnectingView: cell.customView)
        
        let bubbleView = cell.customView.customView.customView
        let controller = URLController(url: url,
                                       messageId: messageId,
                                       bubbleController: buildBezierBubbleController(for: bubbleView, messageType: messageType, bubbleType: bubbleType))
        
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        controller.delegate = reloadDelegate
        cell.delegate = bubbleView.customView
        
        return cell
    }
    
    private func createImageCell(collectionView: UICollectionView,
                                 messageId: String,
                                 isSelected: Bool,
                                 indexPath: IndexPath,
                                 alignment: ChatItemAlignment,
                                 user: User,
                                 source: MediaMessageSource,
                                 forVideo: Bool = false,
                                 date: Date,
                                 bubbleType: Cell.BubbleType,
                                 status: MessageStatus,
                                 messageType: MessageType) -> ImageCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionCell.reuseIdentifier, for: indexPath) as! ImageCollectionCell
        
        setupMessageContainerView(cell.customView, messageId: messageId, isSelected: isSelected, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: user, messageID: messageId, alignment: alignment, bubble: bubbleType, status: status)
        
        setupSwipeHandlingAccessory(cell.customView.customView, date: date, accessoryConnectingView: cell.customView)
        
        let bubbleView = cell.customView.customView.customView
        let controller = ImageController(source: source,
                                         messageId: messageId,
                                         bubbleController: buildBezierBubbleController(for: bubbleView, messageType: messageType, bubbleType: bubbleType))
        
        controller.delegate = reloadDelegate
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.delegate = bubbleView.customView

        return cell
    }
    
    private func createVideoCell(collectionView: UICollectionView,
                                 messageId: String,
                                 isSelected: Bool,
                                 indexPath: IndexPath,
                                 alignment: ChatItemAlignment,
                                 user: User,
                                 source: MediaMessageSource,
                                 forVideo: Bool = false,
                                 date: Date,
                                 bubbleType: Cell.BubbleType,
                                 status: MessageStatus,
                                 messageType: MessageType) -> VideoCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCollectionCell.reuseIdentifier, for: indexPath) as! VideoCollectionCell
        
        setupMessageContainerView(cell.customView, messageId: messageId, isSelected: isSelected, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: user, messageID: messageId, alignment: alignment, bubble: bubbleType, status: status)
        
        setupSwipeHandlingAccessory(cell.customView.customView, date: date, accessoryConnectingView: cell.customView)
        
        let bubbleView = cell.customView.customView.customView
        let controller = VideoController(source: source,
                                         messageId: messageId,
                                         bubbleController: buildBezierBubbleController(for: bubbleView, messageType: messageType, bubbleType: bubbleType))
        
        controller.delegate = reloadDelegate
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.delegate = bubbleView.customView

        return cell
    }
    
    private func createTypingIndicatorCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TypingIndicatorCollectionCell.reuseIdentifier, for: indexPath) as! TypingIndicatorCollectionCell
        let alignment = ChatItemAlignment.leading
        cell.customView.alignment = alignment
        let bubbleView = cell.customView.customView.customView
        
        let controller = TypingIndicatorController(bubbleController: buildBlankBubbleController(bubbleView: bubbleView,
                                                                                                messageType: .incoming,
                                                                                                bubbleType: .normal))
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.customView.accessoryView?.isHiddenSafe = true
        
        return cell
    }
    // 名字
    private func createGroupTitle(collectionView: UICollectionView, indexPath: IndexPath, alignment: ChatItemAlignment, title: String) -> UserTitleCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserTitleCollectionCell.reuseIdentifier, for: indexPath) as! UserTitleCollectionCell
        cell.customView.spacing = 2
        
        cell.customView.customView.customView.text = title
        cell.customView.customView.customView.preferredMaxLayoutWidth = (collectionView.collectionViewLayout as? CollectionViewChatLayout)?.layoutFrame.width ?? collectionView.frame.width
        cell.customView.customView.customView.font = .preferredFont(forTextStyle: .caption2)
        cell.customView.customView.flexibleEdges = [.top]
        cell.customView.accessoryView.isHidden = true
        cell.contentView.layoutMargins = .zero
        
        return cell
    }
    
    // 设置时间组cell/系统提示cell
    private func createTipsTitle(collectionView: UICollectionView,
                                 indexPath: IndexPath,
                                 alignment: ChatItemAlignment,
                                 title: String? = nil,
                                 attributeTitle: NSAttributedString? = nil) -> TitleCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TitleCollectionCell.reuseIdentifier, for: indexPath) as! TitleCollectionCell
        cell.customView.preferredMaxLayoutWidth = (collectionView.collectionViewLayout as? CollectionViewChatLayout)?.layoutFrame.width ?? collectionView.frame.width
        if title != nil {
            cell.customView.text = title
            cell.customView.textColor = .gray
        } else {
            cell.customView.attributedText = attributeTitle
        }
        
        cell.customView.numberOfLines = 0
        cell.customView.font = .preferredFont(forTextStyle: .caption2)
        cell.contentView.layoutMargins = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        return cell
    }
    // 设置编辑状态
    private func setupMessageContainerView(_ messageContainerView: MessageContainerView<EditingAccessoryView, some Any>, messageId: String, isSelected: Bool, alignment: ChatItemAlignment) {
        messageContainerView.alignment = alignment
        if let accessoryView = messageContainerView.accessoryView {
            editNotifier.add(delegate: accessoryView)
            accessoryView.setIsEditing(editNotifier.isEditing)
            
            let controller = EditingAccessoryController(messageId: messageId)
            controller.view = accessoryView
            controller.delegate = editingDelegate
            accessoryView.setup(with: controller, isSelected: isSelected)
        }
    }
    
    /*private func setupCellLayoutView(_ cellView: CellLayoutContainerView<ChatAvatarView, some Any, StatusView>,
     user: User,
     alignment: ChatItemAlignment,
     bubble: Cell.BubbleType,
     status: MessageStatus) {
     cellView.alignment = .bottom
     cellView.leadingView?.isHiddenSafe = !alignment.isIncoming
     cellView.leadingView?.alpha = alignment.isIncoming ? 1 : 0
     cellView.trailingView?.isHiddenSafe = alignment.isIncoming
     cellView.trailingView?.alpha = alignment.isIncoming ? 0 : 1
     cellView.trailingView?.setup(with: status)
     
     if let avatarView = cellView.leadingView {
     let avatarViewController = AvatarViewController(user: user, bubble: bubble)
     avatarView.setup(with: avatarViewController)
     avatarViewController.view = avatarView
     }
     }*/
    // 这里没有右边头像, 是个已读标记
    /*private func setupMainMessageView(_ cellView: MainContainerView<ChatAvatarView, some Any, StatusView>,
     user: User,
     alignment: ChatItemAlignment,
     bubble: Cell.BubbleType,
     status: MessageStatus) {
     cellView.containerView.alignment = .bottom
     cellView.containerView.leadingView?.isHiddenSafe = !alignment.isIncoming
     cellView.containerView.leadingView?.alpha = alignment.isIncoming ? 1 : 0
     cellView.containerView.trailingView?.isHiddenSafe = alignment.isIncoming
     cellView.containerView.trailingView?.alpha = alignment.isIncoming ? 0 : 1
     cellView.containerView.trailingView?.setup(with: status)
     if let avatarView = cellView.containerView.leadingView {
     let avatarViewController = AvatarViewController(user: user, bubble: bubble)
     avatarView.setup(with: avatarViewController)
     avatarViewController.view = avatarView
     }
     }
     */
    // 设置头像
    private func setupMainMessageView(_ cellView: MainContainerView<ChatAvatarView, some Any, ChatAvatarView>,
                                      user: User,
                                      messageID: String,
                                      alignment: ChatItemAlignment,
                                      bubble: Cell.BubbleType,
                                      status: MessageStatus) {
        cellView.containerView.alignment = .top
        cellView.containerView.leadingView?.isHiddenSafe = !alignment.isIncoming
        cellView.containerView.leadingView?.alpha = alignment.isIncoming ? 1 : 0
        cellView.containerView.trailingView?.isHiddenSafe = alignment.isIncoming
        cellView.containerView.trailingView?.alpha = alignment.isIncoming ? 0 : 1
        cellView.leadingCountdownLabel.isHiddenSafe = alignment.isIncoming
        cellView.trailingCountdownLabel.isHiddenSafe = !alignment.isIncoming
        
        if let avatarView = cellView.containerView.leadingView {
            let avatarViewController = AvatarViewController(user: user, bubble: bubble)
            avatarViewController.delegate = reloadDelegate
            avatarView.setup(with: avatarViewController)
            avatarViewController.view = avatarView
        }
        
        if let avatarView = cellView.containerView.trailingView {
            let avatarViewController = AvatarViewController(user: user, bubble: bubble)
            avatarView.setup(with: avatarViewController)
            avatarViewController.view = avatarView
        }
    }
    /*
     private func setupSwipeHandlingAccessory(_ cellView: MainContainerView<ChatAvatarView, some Any, StatusView>,
     date: Date,
     accessoryConnectingView: UIView) {
     cellView.accessoryConnectingView = accessoryConnectingView
     cellView.accessoryView.setup(with: DateAccessoryController(date: date))
     cellView.accessorySafeAreaInsets = swipeNotifier.accessorySafeAreaInsets
     cellView.swipeCompletionRate = swipeNotifier.swipeCompletionRate
     swipeNotifier.add(delegate: cellView)
     }
     */
    // 设置右滑显示时间
    private func setupSwipeHandlingAccessory(_ cellView: MainContainerView<ChatAvatarView, some Any, ChatAvatarView>,
                                             date: Date,
                                             accessoryConnectingView: UIView) {
        cellView.accessoryConnectingView = accessoryConnectingView
        cellView.accessoryView.setup(with: DateAccessoryController(date: date))
        cellView.accessorySafeAreaInsets = swipeNotifier.accessorySafeAreaInsets
        cellView.swipeCompletionRate = swipeNotifier.swipeCompletionRate
        swipeNotifier.add(delegate: cellView)
    }
    
    private func buildBlankBubbleController(bubbleView: BezierMaskedView<some Any>,
                                           messageType: MessageType,
                                           bubbleType: Cell.BubbleType) -> BubbleController {
        let textBubbleController = BlankBubbleController(bubbleView: bubbleView, type: messageType, bubbleType: bubbleType)
        let bubbleController = BezierBubbleController(bubbleView: bubbleView, controllerProxy: textBubbleController, type: messageType, bubbleType: bubbleType)
        return bubbleController
    }
    
    private func buildTextBubbleController(bubbleView: BezierMaskedView<some Any>,
                                           messageType: MessageType,
                                           bubbleType: Cell.BubbleType) -> BubbleController {
        let textBubbleController = TextBubbleController(bubbleView: bubbleView, type: messageType, bubbleType: bubbleType)
        let bubbleController = BezierBubbleController(bubbleView: bubbleView, controllerProxy: textBubbleController, type: messageType, bubbleType: bubbleType)
        return bubbleController
    }
    
    private func buildBezierBubbleController(for bubbleView: BezierMaskedView<some Any>,
                                             messageType: MessageType,
                                             bubbleType: Cell.BubbleType) -> BubbleController {
        let contentBubbleController = FullCellContentBubbleController(bubbleView: bubbleView)
        let bubbleController = BezierBubbleController(bubbleView: bubbleView, controllerProxy: contentBubbleController, type: messageType, bubbleType: bubbleType)
        return bubbleController
    }
}

extension DefaultChatCollectionDataSource: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].cells.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = sections[indexPath.section].cells[indexPath.item]
        switch cell {
            
        case let .date(group):
            let cell = createTipsTitle(collectionView: collectionView, indexPath: indexPath, alignment: cell.alignment, title: group.value)
            
            return cell
        case let .systemMessage(group):
            let cell = createTipsTitle(collectionView: collectionView, indexPath: indexPath, alignment: cell.alignment, attributeTitle: group.value)
            
            return cell
        case let .messageGroup(group):
            let cell = createGroupTitle(collectionView: collectionView, indexPath: indexPath, alignment: cell.alignment, title: group.title)
            
            return cell
        case let .message(message, bubbleType: bubbleType):
            switch message.data {
            case let .text(source):
                let cell = createTextCell(collectionView: collectionView, messageId: message.id, isSelected: message.isSelected, indexPath: indexPath, text: source.text, anchor: message.isAnchor, date: message.date, alignment: cell.alignment, user: message.owner, bubbleType: bubbleType, status: message.status, messageType: message.type)
                
                return cell
                
            case let .attributeText(text):
                let cell = createTextCell(collectionView: collectionView, messageId: message.id, isSelected: message.isSelected, indexPath: indexPath, attributedString: text, date: message.date, alignment: cell.alignment, user: message.owner, bubbleType: bubbleType, status: message.status, messageType: message.type)
                
                return cell
            case let .custom(source):
                let cell = createTextCell(collectionView: collectionView, messageId: message.id, isSelected: message.isSelected, indexPath: indexPath, attributedString: source.attributedString, date: message.date, alignment: cell.alignment, user: message.owner, bubbleType: bubbleType, status: message.status, messageType: message.type)
                
                return cell
                
            case let .url(url, isLocallyStored: _):
                if #available(iOS 13.0, *) {
                    return createURLCell(collectionView: collectionView, messageId: message.id, isSelected: message.isSelected, indexPath: indexPath, url: url, date: message.date, alignment: cell.alignment, user: message.owner, bubbleType: bubbleType, status: message.status, messageType: message.type)
                } else {
                    return createTextCell(collectionView: collectionView, messageId: message.id, isSelected: message.isSelected, indexPath: indexPath, text: url.absoluteString, date: message.date, alignment: cell.alignment, user: message.owner, bubbleType: bubbleType, status: message.status, messageType: message.type)
                }
            case let .image(source, isLocallyStored: _):
                let cell = createImageCell(collectionView: collectionView, messageId: message.id, isSelected: message.isSelected, indexPath: indexPath, alignment: cell.alignment, user: message.owner, source: source, date: message.date, bubbleType: bubbleType, status: message.status, messageType: message.type)
                
                return cell
            case let .video(source, isLocallyStored: _):
                let cell = createVideoCell(collectionView: collectionView, messageId: message.id, isSelected: message.isSelected, indexPath: indexPath, alignment: cell.alignment, user: message.owner, source: source, date: message.date, bubbleType: bubbleType, status: message.status, messageType: message.type)
                
                return cell
            }
            
        case .typingIndicator:
            return createTypingIndicatorCell(collectionView: collectionView, indexPath: indexPath)
        default:
            fatalError()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                       withReuseIdentifier: TextTitleView.reuseIdentifier,
                                                                       for: indexPath) as! TextTitleView
            view.customView.text = sections[indexPath.section].title
            view.customView.preferredMaxLayoutWidth = 300
            view.customView.textColor = .lightGray
            view.customView.numberOfLines = 0
            view.customView.font = .preferredFont(forTextStyle: .caption2)
            return view
        case UICollectionView.elementKindSectionFooter:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                       withReuseIdentifier: TextTitleView.reuseIdentifier,
                                                                       for: indexPath) as! TextTitleView
            view.customView.text = nil
            return view
        default:
            fatalError()
        }
    }
}

extension DefaultChatCollectionDataSource: ChatLayoutDelegate {
    
    public func shouldPresentHeader(_ chatLayout: CollectionViewChatLayout, at sectionIndex: Int) -> Bool {
        true
    }
    
    public func shouldPresentFooter(_ chatLayout: CollectionViewChatLayout, at sectionIndex: Int) -> Bool {
        true
    }
    
    public func sizeForItem(_ chatLayout: CollectionViewChatLayout, of kind: ItemKind, at indexPath: IndexPath) -> ItemSize {
        switch kind {
        case .cell:
            let item = sections[indexPath.section].cells[indexPath.item]
            switch item {
            case let .message(message, bubbleType: _):
                switch message.data {
                case .text, .attributeText, .custom(_):
                    return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: 36))
                case let .image(_, isLocallyStored: isDownloaded):
                    return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: isDownloaded ? 180 : 80))
                case let .url(_, isLocallyStored: isDownloaded):
                    return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: isDownloaded ? 60 : 36))
                case let .video(_, isLocallyStored: isDownloaded):
                    return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: isDownloaded ? 120 : 80))
                }
            case .date, .systemMessage:
                return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: 18))
            case .typingIndicator:
                return .estimated(CGSize(width: 60, height: 36))
            case .messageGroup:
                return .estimated(CGSize(width: min(85, chatLayout.layoutFrame.width / 3), height: 18))
            }
        case .footer, .header:
            return .auto
        }
    }
    
    public func alignmentForItem(_ chatLayout: CollectionViewChatLayout, of kind: ItemKind, at indexPath: IndexPath) -> ChatItemAlignment {
        switch kind {
        case .header:
            return .center
        case .cell:
            let item = sections[indexPath.section].cells[indexPath.item]
            switch item {
            case .date, .systemMessage:
                return .center
            case .message:
                return .fullWidth
            case .messageGroup, .typingIndicator:
                return .leading
            }
        case .footer:
            return .trailing
        }
    }
    
    public func initialLayoutAttributesForInsertedItem(_ chatLayout: CollectionViewChatLayout, of kind: ItemKind, at indexPath: IndexPath, modifying originalAttributes: ChatLayoutAttributes, on state: InitialAttributesRequestType) {
        originalAttributes.alpha = 0
        guard state == .invalidation,
              kind == .cell else {
            return
        }
        switch sections[indexPath.section].cells[indexPath.item] {
            // Uncomment to see the effect
            //        case .messageGroup:
            //            originalAttributes.center.x -= originalAttributes.frame.width
            //        case let .message(message, bubbleType: _):
            //            originalAttributes.transform = .init(scaleX: 0.9, y: 0.9)
            //            originalAttributes.transform = originalAttributes.transform.concatenating(.init(rotationAngle: message.type == .incoming ? -0.05 : 0.05))
            //            originalAttributes.center.x += (message.type == .incoming ? -20 : 20)
        case .typingIndicator:
            originalAttributes.transform = .init(scaleX: 0.1, y: 0.1)
            originalAttributes.center.x -= originalAttributes.bounds.width / 5
        default:
            break
        }
    }
    
    public func finalLayoutAttributesForDeletedItem(_ chatLayout: CollectionViewChatLayout, of kind: ItemKind, at indexPath: IndexPath, modifying originalAttributes: ChatLayoutAttributes) {
        originalAttributes.alpha = 0
        guard kind == .cell else {
            return
        }
        switch oldSections[indexPath.section].cells[indexPath.item] {
            // Uncomment to see the effect
//                    case .messageGroup:
//                        originalAttributes.center.x -= originalAttributes.frame.width
//                    case let .message(message, bubbleType: _):
//                        originalAttributes.transform = .init(scaleX: 0.9, y: 0.9)
//                        originalAttributes.transform = originalAttributes.transform.concatenating(.init(rotationAngle: message.type == .incoming ? -0.05 : 0.05))
//                        originalAttributes.center.x += (message.type == .incoming ? -20 : 20)
        case .typingIndicator:
            originalAttributes.transform = .init(scaleX: 0.1, y: 0.1)
            originalAttributes.center.x -= originalAttributes.bounds.width / 5
        default:
            break
        }
    }
    
//    public func interItemSpacing(_ chatLayout: CollectionViewChatLayout, of kind: ItemKind, after indexPath: IndexPath) -> CGFloat? {
//        let item = sections[indexPath.section].cells[indexPath.item]
//        switch item {
//        case .messageGroup:
//            return 3
//        default:
//            return nil
//        }
//    }
//
//    public func interSectionSpacing(_ chatLayout: CollectionViewChatLayout, after sectionIndex: Int) -> CGFloat? {
//        100
//    }

}
