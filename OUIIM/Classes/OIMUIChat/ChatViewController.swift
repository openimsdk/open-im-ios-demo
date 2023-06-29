
import ChatLayout
import DifferenceKit
import Foundation
import InputBarAccessoryView
import UIKit
import OUICore
import OUICoreView
import ProgressHUD

final class ChatViewController: UIViewController {
    
    private enum ReactionTypes {
        case delayedUpdate
    }
    
    private enum InterfaceActions {
        case changingKeyboardFrame
        case changingContentInsets
        case changingFrameSize
        case sendingMessage
        case scrollingToTop
        case scrollingToBottom
        case showingPreview
        case showingAccessory
        case updatingCollectionInIsolation
    }
    
    private enum ControllerActions {
        case loadingInitialMessages
        case loadingPreviousMessages
        case updatingCollection
    }
    
    override var inputAccessoryView: UIView? {
        inputBarView
    }
    
    override var canBecomeFirstResponder: Bool {
        true
    }
    
    private var currentInterfaceActions: SetActor<Set<InterfaceActions>, ReactionTypes> = SetActor()
    private var currentControllerActions: SetActor<Set<ControllerActions>, ReactionTypes> = SetActor()
    private let editNotifier: EditNotifier
    private let swipeNotifier: SwipeNotifier
    private var collectionView: UICollectionView!
    private var chatLayout = CollectionViewChatLayout()
    private let inputBarView = CoustomInputBarAccessoryView()
    
    private var oldLeftBarButtonItem: UIBarButtonItem?
    
    private let chatController: ChatController
    private let dataSource: ChatCollectionDataSource
    private var animator: ManualAnimator?
    
    private var translationX: CGFloat = 0
    private var currentOffset: CGFloat = 0
    
    private var documentInteractionController: UIDocumentInteractionController!
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleRevealPan(_:)))
        gesture.delegate = self
        
        return gesture
    }()
    
    lazy var settingButton: UIBarButtonItem = {
        let v = UIBarButtonItem(image: UIImage(nameInBundle: "common_more_btn_icon"), style: .done, target: self, action: #selector(settingButtonAction))
        v.tintColor = .black
        
        return v
    }()
    
    @objc
    private func settingButtonAction() {
        let conversation = self.chatController.getConversation()
        let conversationType = conversation.conversationType
        switch conversationType {
        case .undefine, .notification:
            break
        case .c2c:
            let viewModel = SingleChatSettingViewModel(conversation: conversation)
            let vc = SingleChatSettingTableViewController(viewModel: viewModel, style: .grouped)
            self.navigationController?.pushViewController(vc, animated: true)
        case .group, .superGroup:
            let vc = GroupChatSettingTableViewController(conversation: conversation, style: .grouped)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    init(chatController: ChatController,
         dataSource: ChatCollectionDataSource,
         editNotifier: EditNotifier,
         swipeNotifier: SwipeNotifier) {
        self.chatController = chatController
        self.dataSource = dataSource
        self.editNotifier = editNotifier
        self.swipeNotifier = swipeNotifier
        
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable, message: "Use init(messageController:) instead")
    override convenience init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError()
    }
    
    @available(*, unavailable, message: "Use init(messageController:) instead")
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    deinit {
        print("chat view controller - deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        setupTitle()
        setupInputBar()
        
        chatLayout.settings.interItemSpacing = 8
        chatLayout.settings.interSectionSpacing = 8
        chatLayout.settings.additionalInsets = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        chatLayout.keepContentOffsetAtBottomOnBatchUpdates = true
        chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = false
        
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: chatLayout)
        view.addSubview(collectionView)
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = dataSource
        chatLayout.delegate = dataSource
        collectionView.keyboardDismissMode = .interactive
        
        /// https://openradar.appspot.com/40926834
        collectionView.isPrefetchingEnabled = false
        
        collectionView.contentInsetAdjustmentBehavior = .always
        if #available(iOS 13.0, *) {
            collectionView.automaticallyAdjustsScrollIndicatorInsets = true
        }
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.frame = view.bounds
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
        ])
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        dataSource.prepare(with: collectionView)
        
        currentControllerActions.options.insert(.loadingInitialMessages)
        chatController.loadInitialMessages { [weak self] sections in
            self?.processUpdates(with: sections, animated: false, requiresIsolatedProcess: false)
            self?.currentControllerActions.options.remove(.loadingInitialMessages)
        }
        
        KeyboardListener.shared.add(delegate: self)
        collectionView.addGestureRecognizer(panGesture)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard isViewLoaded else {
            return
        }
        currentInterfaceActions.options.insert(.changingFrameSize)
        let positionSnapshot = chatLayout.getContentOffsetSnapshot(from: .bottom)
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.setNeedsLayout()
        coordinator.animate(alongsideTransition: { _ in
            // Gives nicer transition behaviour
            // self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.performBatchUpdates(nil)
        }, completion: { _ in
            if let positionSnapshot,
               !self.isUserInitiatedScrolling {
                // As contentInsets may change when size transition has already started. For example, `UINavigationBar` height may change
                // to compact and back. `CollectionViewChatLayout` may not properly predict the final position of the element. So we try
                // to restore it after the rotation manually.
                self.chatLayout.restoreContentOffset(with: positionSnapshot)
            }
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.currentInterfaceActions.options.remove(.changingFrameSize)
        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    private func setupTitle() {
        let type = chatController.getConversation().conversationType
        if type == .c2c {
            chatController.getOtherInfo { [weak self] info in
                guard let self else { return }
                self.setRightButtons(show: info.friendInfo != nil)
                self.navigationItem.title = info.showName
            }
        } else if type == .notification {
            navigationItem.title = "系统通知".innerLocalized()
        } else {
            chatController.getGroupInfo { [weak self] info in
                guard let self else { return }
                self.setRightButtons(show: info.status == .ok || info.status == .muted)
                self.navigationItem.title = "\(info.groupName!)(\(info.memberCount))"
            }
        }
    }
    
    private func setRightButtons(show: Bool) {
        if show {
            navigationItem.rightBarButtonItems = [settingButton]
        } else {
            navigationItem.rightBarButtonItems = nil
        }
    }
    
    private func setupInputBar() {
        inputBarView.delegate = self
        inputBarView.shouldAnimateTextDidChangeLayout = true
    }
    
    @objc private func setEditNotEdit(forceEnd: Bool = false) {
        if forceEnd {
            isEditing = false
        } else {
            isEditing = !isEditing
        }
        editNotifier.setIsEditing(isEditing, duration: .animated(duration: 0.25))
        chatLayout.invalidateLayout()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        swipeNotifier.setAccessoryOffset(UIEdgeInsets(top: view.safeAreaInsets.top,
                                                      left: view.safeAreaInsets.left + chatLayout.settings.additionalInsets.left,
                                                      bottom: view.safeAreaInsets.bottom,
                                                      right: view.safeAreaInsets.right + chatLayout.settings.additionalInsets.right))
    }
    
    // Apple doesnt return sometimes inputBarView back to the app. This is an attempt to fix that
    // See: https://github.com/ekazaev/ChatLayout/issues/24
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if inputBarView.superview == nil,
           topMostViewController() is ChatViewController {
            DispatchQueue.main.async { [weak self] in
                self?.reloadInputViews()
            }
        }
    }
}

extension ChatViewController: UIScrollViewDelegate {
    
    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        guard scrollView.contentSize.height > 0,
              !currentInterfaceActions.options.contains(.showingAccessory),
              !currentInterfaceActions.options.contains(.showingPreview),
              !currentInterfaceActions.options.contains(.scrollingToTop),
              !currentInterfaceActions.options.contains(.scrollingToBottom) else {
            return false
        }
        // Blocking the call of loadPreviousMessages() as UIScrollView behaves the way that it will scroll to the top even if we keep adding
        // content there and keep changing the content offset until it actually reaches the top. So instead we wait until it reaches the top and initiate
        // the loading after.
        currentInterfaceActions.options.insert(.scrollingToTop)
        return true
    }
    
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        guard !currentControllerActions.options.contains(.loadingInitialMessages),
              !currentControllerActions.options.contains(.loadingPreviousMessages) else {
            return
        }
        currentInterfaceActions.options.remove(.scrollingToTop)
        loadPreviousMessages()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if currentControllerActions.options.contains(.updatingCollection), collectionView.isDragging {
            // Interrupting current update animation if user starts to scroll while batchUpdate is performed. It helps to
            // avoid presenting blank area if user scrolls out of the animation rendering area.
            UIView.performWithoutAnimation {
                self.collectionView.performBatchUpdates({}, completion: { _ in
                    let context = ChatLayoutInvalidationContext()
                    context.invalidateLayoutMetrics = false
                    self.collectionView.collectionViewLayout.invalidateLayout(with: context)
                })
            }
        }
        guard !currentControllerActions.options.contains(.loadingInitialMessages),
              !currentControllerActions.options.contains(.loadingPreviousMessages),
              !currentInterfaceActions.options.contains(.scrollingToTop),
              !currentInterfaceActions.options.contains(.scrollingToBottom) else {
            return
        }
        
        if scrollView.contentOffset.y <= -(scrollView.adjustedContentInset.top + 50) {
            loadPreviousMessages()
        }
    }
    
    private func loadPreviousMessages() {
        // Blocking the potential multiple call of that function as during the content invalidation the contentOffset of the UICollectionView can change
        // in any way so it may trigger another call of that function and lead to unexpected behaviour/animation
        currentControllerActions.options.insert(.loadingPreviousMessages)
        chatController.loadPreviousMessages { [weak self] sections in
            guard let self else {
                return
            }
            // Reloading the content without animation just because it looks better is the scrolling is in process.
            let animated = !self.isUserInitiatedScrolling
            self.processUpdates(with: sections, animated: animated, requiresIsolatedProcess: false) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
                    self.currentControllerActions.options.remove(.loadingPreviousMessages)
                }
            }
        }
    }
    
    fileprivate var isUserInitiatedScrolling: Bool {
        collectionView.isDragging || collectionView.isDecelerating
    }
    
    func scrollToBottom(completion: (() -> Void)? = nil) {
        // I ask content size from the layout because on IOs 12 collection view contains not updated one
        let contentOffsetAtBottom = CGPoint(x: collectionView.contentOffset.x,
                                            y: chatLayout.collectionViewContentSize.height - collectionView.frame.height + collectionView.adjustedContentInset.bottom)
        
        guard contentOffsetAtBottom.y > collectionView.contentOffset.y else {
            completion?()
            return
        }
        
        let initialOffset = collectionView.contentOffset.y
        let delta = contentOffsetAtBottom.y - initialOffset
        if abs(delta) > chatLayout.visibleBounds.height {
            // See: https://dasdom.dev/posts/scrolling-a-collection-view-with-custom-duration/
            animator = ManualAnimator()
            animator?.animate(duration: TimeInterval(0.25), curve: .easeInOut) { [weak self] percentage in
                guard let self else {
                    return
                }
                self.collectionView.contentOffset = CGPoint(x: self.collectionView.contentOffset.x, y: initialOffset + (delta * percentage))
                if percentage == 1.0 {
                    self.animator = nil
                    let positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: 0), kind: .footer, edge: .bottom)
                    self.chatLayout.restoreContentOffset(with: positionSnapshot)
                    self.currentInterfaceActions.options.remove(.scrollingToBottom)
                    completion?()
                }
            }
        } else {
            currentInterfaceActions.options.insert(.scrollingToBottom)
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                self?.collectionView.setContentOffset(contentOffsetAtBottom, animated: true)
            }, completion: { [weak self] _ in
                self?.currentInterfaceActions.options.remove(.scrollingToBottom)
                completion?()
            })
        }
    }
    
}

// MARK: ChatControllerDelegate

extension ChatViewController: ChatControllerDelegate {
    
    func updateUnreadCount(count: Int) {
        if !editNotifier.isEditing {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: count > 0 ? "\(count)" : nil) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func isInGroup(with isIn: Bool) {
        if isIn {
            navigationItem.rightBarButtonItems = [settingButton]
        } else {
            navigationItem.rightBarButtonItems = nil
        }
    }
    
    func didTapAvatar(with id: String) {
        print("点击头像")
        let vc = UserDetailTableViewController(userId: id, groupId: chatController.getConversation().groupID)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func didTapContent(with id: String, data: Message.Data) {
        
        switch data {
        case .text(let string):
            break
        case .attributeText(let nSAttributedString):
            break
        case .url(let uRL, let isLocallyStored):
            break
        case .image(let source, let isLocallyStored):
            let vc = MediaPreviewViewController(resources: [MediaResource(thumbUrl: source.source.url.relativeString,
                                                                          url: source.source.url.relativeString)])
            vc.hidesBottomBarWhenPushed = true
            navigationController?.addChild(vc)
            navigationController?.view.addSubview(vc.view)
        case .video(let source, let isLocallyStored):
            let vc = MediaPreviewViewController(resources: [MediaResource(thumbUrl: source.thumb?.url.relativeString,
                                                                          url: source.source.url.relativeString,
                                                                          type: .video)])
            vc.hidesBottomBarWhenPushed = true
            navigationController?.addChild(vc)
            navigationController?.view.addSubview(vc.view)
            
        case .custom(let source):
            guard let value = source.value, let type = source.type else { return }
            switch type {
            case .call:
                break
            case .deletedByFriend:
                ProgressHUD.show()
                chatController.addFriend { r in
                    ProgressHUD.showSucceed("添加好友请求已发送".innerLocalized())
                } onFailure: { errCode, errMsg in
                    ProgressHUD.showError("该用户已设置不可添加！".innerLocalized())
                }
            default:
                break
            }
        }
        print("点击内容")
    }
    
    func update(with sections: [Section], requiresIsolatedProcess: Bool) {
        processUpdates(with: sections, animated: true, requiresIsolatedProcess: requiresIsolatedProcess)
    }
    
    private func processUpdates(with sections: [Section], animated: Bool = true, requiresIsolatedProcess: Bool, completion: (() -> Void)? = nil) {
        guard isViewLoaded else {
            dataSource.sections = sections
            return
        }
        
        guard currentInterfaceActions.options.isEmpty else {
            let reaction = SetActor<Set<InterfaceActions>, ReactionTypes>.Reaction(type: .delayedUpdate,
                                                                                   action: .onEmpty,
                                                                                   executionType: .once,
                                                                                   actionBlock: { [weak self] in
                guard let self else {
                    return
                }
                self.processUpdates(with: sections, animated: animated, requiresIsolatedProcess: requiresIsolatedProcess, completion: completion)
            })
            currentInterfaceActions.add(reaction: reaction)
            return
        }
        
        func process() {
            // If there is a big amount of changes, it is better to move that calculation out of the main thread.
            // Here is on the main thread for the simplicity.
            var changeSet = StagedChangeset(source: dataSource.sections, target: sections).flattenIfPossible()
            guard !changeSet.isEmpty else {
                completion?()
                return
            }
            
            if requiresIsolatedProcess {
                chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = true
                currentInterfaceActions.options.insert(.updatingCollectionInIsolation)
            }
            currentControllerActions.options.insert(.updatingCollection)
            collectionView.reload(using: changeSet,
                                  interrupt: { changeSet in
                guard changeSet.sectionInserted.isEmpty else {
                    return true
                }
                return false
            },
                                  onInterruptedReload: {
                let positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: sections.count - 1), kind: .footer, edge: .bottom)
                self.collectionView.reloadData()
                // We want so that user on reload appeared at the very bottom of the layout
                self.chatLayout.restoreContentOffset(with: positionSnapshot)
            },
                                  completion: { _ in
                DispatchQueue.main.async {
                    self.chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = false
                    if requiresIsolatedProcess {
                        self.currentInterfaceActions.options.remove(.updatingCollectionInIsolation)
                    }
                    completion?()
                    self.currentControllerActions.options.remove(.updatingCollection)
                }
            },
                                  setData: { data in
                self.dataSource.sections = data
            })
        }
        
        if animated {
            process()
        } else {
            UIView.performWithoutAnimation {
                process()
            }
        }
    }
    
}

// MARK: UIGestureRecognizerDelegate

extension ChatViewController: UIGestureRecognizerDelegate {
    
    @objc private func handleRevealPan(_ gesture: UIPanGestureRecognizer) {
        guard let collectionView = gesture.view as? UICollectionView,
              !editNotifier.isEditing else {
            currentInterfaceActions.options.remove(.showingAccessory)
            return
        }
        
        switch gesture.state {
        case .began:
            currentInterfaceActions.options.insert(.showingAccessory)
        case .changed:
            translationX = gesture.translation(in: gesture.view).x
            currentOffset += translationX
            
            gesture.setTranslation(.zero, in: gesture.view)
            updateTransforms(in: collectionView)
        default:
            UIView.animate(withDuration: 0.25, animations: { () in
                self.translationX = 0
                self.currentOffset = 0
                self.updateTransforms(in: collectionView, transform: .identity)
            }, completion: { _ in
                self.currentInterfaceActions.options.remove(.showingAccessory)
            })
        }
    }
    
    private func updateTransforms(in collectionView: UICollectionView, transform: CGAffineTransform? = nil) {
        collectionView.indexPathsForVisibleItems.forEach {
            guard let cell = collectionView.cellForItem(at: $0) else { return }
            updateTransform(transform: transform, cell: cell, indexPath: $0)
        }
    }
    
    private func updateTransform(transform: CGAffineTransform?, cell: UICollectionViewCell, indexPath: IndexPath) {
        var x = currentOffset
        
        let maxOffset: CGFloat = -100
        x = max(x, maxOffset)
        x = min(x, 0)
        
        swipeNotifier.setSwipeCompletionRate(x / maxOffset)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        [gestureRecognizer, otherGestureRecognizer].contains(panGesture)
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gesture = gestureRecognizer as? UIPanGestureRecognizer, gesture == panGesture {
            let translation = gesture.translation(in: gesture.view)
            return (abs(translation.x) > abs(translation.y)) && (gesture == panGesture)
        }
        
        return true
    }
    
}

// MARK: CoustomInputBarAccessoryViewDelegate

extension ChatViewController: CoustomInputBarAccessoryViewDelegate {
    
    private func completionHandler() -> ([Section]) -> Void {
        // 发送结束的操作
        let completion: ([Section]) -> Void = { [weak self] sections in
            self?.inputBarView.sendButton.stopAnimating()
            self?.currentInterfaceActions.options.remove(.sendingMessage)
            self?.processUpdates(with: sections, animated: true, requiresIsolatedProcess: false)
        }
        
        return completion
    }
    
    public func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        guard !currentInterfaceActions.options.contains(.sendingMessage) else {
            return
        }
        scrollToBottom()
    }
    
    public func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let messageText = inputBar.inputTextView.text
        // 发送结束的操作
        let completion = completionHandler()
        
        currentInterfaceActions.options.insert(.sendingMessage)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) { [weak self] in
            guard let self else {
                return
            }
            guard let messageText else {
                self.currentInterfaceActions.options.remove(.sendingMessage)
                return
            }
            
            self.scrollToBottom(completion: {
                inputBar.sendButton.startAnimating()
                self.chatController.sendMessage(.text(TextMessageSource(text: text.trimmingCharacters(in: .whitespacesAndNewlines))), completion: completion)
            })
        }
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith attachments: [CustomAttachment]) {
        // 发送结束的操作
        let completion = completionHandler()
        
        currentInterfaceActions.options.insert(.sendingMessage)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) { [weak self] in
            inputBar.inputTextView.text = String()
            inputBar.invalidatePlugins()
            
            guard let self, !attachments.isEmpty else {
                self?.currentInterfaceActions.options.remove(.sendingMessage)
                return
            }
            
            self.scrollToBottom(completion: {
                inputBar.sendButton.startAnimating()
                attachments.forEach { attachment in
                    switch attachment {
                    case .image(let relativePath, let path):
                        let source = MediaMessageSource(source: MediaMessageSource.Info(url: URL(string: path)!, relativePath: relativePath))
                        
                        self.chatController.sendMessage(.image(source, isLocallyStored: true),
                                                        completion: completion)

                    case .video(let thumbRelativePath, let thumbPath, let mediaRelativePath, let duration):
                        let source = MediaMessageSource(source: MediaMessageSource.Info(relativePath: mediaRelativePath),
                                                        thumb: MediaMessageSource.Info(url: URL(string: thumbPath)!, relativePath: thumbRelativePath),
                                                        duration: duration)
                        
                        self.chatController.sendMessage(.video(source, isLocallyStored: true), completion: completion)
                    }
                }
            })
        }
    }
}

// MARK: KeyboardListenerDelegate

extension ChatViewController: KeyboardListenerDelegate {
    
    func keyboardWillChangeFrame(info: KeyboardInfo) {
        guard !currentInterfaceActions.options.contains(.changingFrameSize),
              !currentInterfaceActions.options.contains(.showingPreview),
              collectionView.contentInsetAdjustmentBehavior != .never,
              let keyboardFrame = collectionView.window?.convert(info.frameEnd, to: view),
              keyboardFrame.minY > 0,
              collectionView.convert(collectionView.bounds, to: collectionView.window).maxY > info.frameEnd.minY else {
            return
        }
        currentInterfaceActions.options.insert(.changingKeyboardFrame)
        let newBottomInset = collectionView.frame.minY + collectionView.frame.size.height - keyboardFrame.minY - collectionView.safeAreaInsets.bottom
        if newBottomInset > 0,
           collectionView.contentInset.bottom != newBottomInset {
            let positionSnapshot = chatLayout.getContentOffsetSnapshot(from: .bottom)
            
            // Interrupting current update animation if user starts to scroll while batchUpdate is performed.
            if currentControllerActions.options.contains(.updatingCollection) {
                UIView.performWithoutAnimation {
                    self.collectionView.performBatchUpdates({})
                }
            }
            
            // Blocks possible updates when keyboard is being hidden interactively
            currentInterfaceActions.options.insert(.changingContentInsets)
            UIView.animate(withDuration: info.animationDuration, animations: {
                self.collectionView.performBatchUpdates({
                    self.collectionView.contentInset.bottom = newBottomInset
                    self.collectionView.scrollIndicatorInsets.bottom = newBottomInset
                }, completion: nil)
                
                if let positionSnapshot, !self.isUserInitiatedScrolling {
                    self.chatLayout.restoreContentOffset(with: positionSnapshot)
                }
                if #available(iOS 13.0, *) {
                } else {
                    // When contentInset is changed programmatically IOs 13 calls invalidate context automatically.
                    // this does not happen in ios 12 so we do it manually
                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
            }, completion: { _ in
                self.currentInterfaceActions.options.remove(.changingContentInsets)
            })
        }
    }
    
    func keyboardDidChangeFrame(info: KeyboardInfo) {
        guard currentInterfaceActions.options.contains(.changingKeyboardFrame) else {
            return
        }
        currentInterfaceActions.options.remove(.changingKeyboardFrame)
    }
    
    func keyboardWillShow(info: KeyboardInfo) {

    }
    
    func keyboardWillHide(info: KeyboardInfo) {

    }
}

