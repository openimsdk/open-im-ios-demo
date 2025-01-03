
import ChatLayout
import DifferenceKit
import Foundation
import InputBarAccessoryView
import UIKit
import OUICore
import OUICoreView
import ProgressHUD
import MJRefresh
import ISEmojiView

#if ENABLE_CALL
import OUICalling
#endif

#if ENABLE_LIVE_ROOM
import OUILive
#endif


final class ChatViewController: UIViewController {
    
    private var toolItems: [ToolItem] = ToolItem.allCases
    
    private enum ToolItem: CaseIterable {
        case copy
        case delete
        case forward
        case reply
        case revoke
        case translate
        case addFace
        
        var image: UIImage? {
            switch self {
            case .copy:
                return UIImage(nameInBundle: "chat_tool_copy_btn_icon")
            case .delete:
                return UIImage(nameInBundle: "chat_tool_delete_btn_icon")
            case .forward:
                return UIImage(nameInBundle: "chat_tool_forward_btn_icon")
            case .reply:
                return UIImage(nameInBundle: "chat_tool_reply_btn_icon")
            case .revoke:
                return UIImage(nameInBundle: "chat_tool_revoke_btn_icon")
            case .translate:
                return UIImage(nameInBundle: "chat_tool_translate_btn_icon")
            case .addFace:
                return UIImage(nameInBundle: "chat_tool_add_btn_icon")
            }
        }
        
        var title: String {
            switch self {
            case .copy:
                return "复制".innerLocalized()
            case .delete:
                return "删除".innerLocalized()
            case .forward:
                return "转发".innerLocalized()
            case .reply:
                return "回复".innerLocalized()
            case .revoke:
                return "撤回".innerLocalized()
            case .translate:
                return "翻译".innerLocalized()
            case .addFace:
                return "add".innerLocalized()
            }
        }
    }
    
    private enum ReactionTypes {
        case delayedUpdate
    }
    
    private var ignoreInterfaceActions = true
    
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
        case loadingMoreMessages
        case updatingCollection
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
    private var lastContentOffset: CGFloat = 0
    
    private var hiddenInputBar: Bool = false
    private var scrollToTop: Bool = false
    
    private var titleView = ChatTitleView()
    private var bottomTipsView: EditingBottomTipsView?
    private var inputBarViewBottomAnchor: NSLayoutConstraint!
    private var contentStackViewBottomAnchor: NSLayoutConstraint?
    private var contentStackView: UIStackView!
    
    private var documentInteractionController: UIDocumentInteractionController!
    
    private var otherIsInBlacklist = false
    
    private var keepContentOffsetAtBottom = true {
        didSet {
            chatLayout.keepContentOffsetAtBottomOnBatchUpdates = keepContentOffsetAtBottom
        }
    }
    
    private var popover: PopoverCollectionViewController?
    
    private var isDismissed: Bool = false
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleRevealPan(_:)))
        gesture.delegate = self
        
        return gesture
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gesture.delegate = self
        
        return gesture
    }()
    
    lazy var settingButton: UIBarButtonItem = {
        let v = UIBarButtonItem(image: UIImage(nameInBundle: "common_more_btn_icon"), style: .done, target: self, action: #selector(settingButtonAction))
        v.tintColor = .black
        v.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        v.isEnabled = false
        
        return v
    }()
    
    @objc
    private func settingButtonAction() {
        popover?.dismiss()

        let conversation = self.chatController.getConversation()
        let conversationType = conversation.conversationType
        switch conversationType {
        case .undefine, .notification:
            break
        case .c2c:
            chatController.getOtherInfo { [weak self] others in
                guard let self else { return }
                
                let viewModel = SingleChatSettingViewModel(conversation: conversation, userInfo: others.toUserInfo())
                let vc = SingleChatSettingTableViewController(viewModel: viewModel, style: .grouped)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case .superGroup:
            chatController.getGroupInfo(force: false) { [weak self] info in
                guard let self else { return }

                chatController.getGroupMembers(userIDs: nil, memory: true) { [self] ms in
                    
                    let vc = GroupChatSettingTableViewController(conversation: conversation, groupInfo: info, groupMembers: ms, style: .grouped)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    lazy var mediaButton: UIBarButtonItem = {
        let v = UIBarButtonItem(image: UIImage(nameInBundle: "chat_call_btn_icon"), style: .done, target: self, action: #selector(mediaButtonAction))
        v.tintColor = .black
        v.imageInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 0)

        return v
    }()
    
    @objc
    private func mediaButtonAction() {
        popover?.dismiss()
        
        showMediaLinkSheet()
    }
    
    private let loadMoreView = UIActivityIndicatorView()
    
    private let watermarkView: WatermarkBackgroundView = {
        let v = WatermarkBackgroundView()
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    private var typingDebounceTimer: Timer?
    
    init(chatController: ChatController,
         dataSource: ChatCollectionDataSource,
         editNotifier: EditNotifier,
         swipeNotifier: SwipeNotifier,
         hiddenInputBar: Bool = false,
         scrollToTop: Bool = false) {
        self.chatController = chatController
        self.dataSource = dataSource
        self.editNotifier = editNotifier
        self.swipeNotifier = swipeNotifier
        self.hiddenInputBar = hiddenInputBar
        self.scrollToTop = scrollToTop
        super.init(nibName: nil, bundle: nil)
        
        loadInitialMessages()
    }
    
    @available(*, unavailable, message: "Use init(messageController:) instead")
    override convenience init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError()
    }
    
    @available(*, unavailable, message: "Use init(messageController:) instead")
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        iLogger.print("\(type(of: self)) - \(#function)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        setupNavigationBar()
        setupWatermarkView()
        setupInputBar()
        updateUnreadCount(count: 0)
        
        chatLayout.settings.interItemSpacing = 10
        chatLayout.settings.interSectionSpacing = 4
        chatLayout.settings.additionalInsets = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        chatLayout.keepContentOffsetAtBottomOnBatchUpdates = true
        
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: chatLayout)
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = dataSource
        chatLayout.delegate = dataSource
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .interactive


        collectionView.isPrefetchingEnabled = false
        
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.automaticallyAdjustsScrollIndicatorInsets = true
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        dataSource.prepare(with: collectionView)
        
        setupRefreshControl()
        
        inputBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputBarView)
        
        contentStackView = UIStackView(arrangedSubviews: [collectionView])
        contentStackView.axis = .vertical
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            
            inputBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        configInputView(hidden: hiddenInputBar)
        
        inputBarViewBottomAnchor = inputBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        inputBarViewBottomAnchor.isActive = true
        
        KeyboardListener.shared.add(delegate: self)

        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isDismissed = false

        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AudioPlayController.shared.stop()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isDismissed = true
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


            self.collectionView.performBatchUpdates(nil)
        }, completion: { _ in
            if let positionSnapshot,
               !self.isUserInitiatedScrolling {



                self.chatLayout.restoreContentOffset(with: positionSnapshot)
            }
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.currentInterfaceActions.options.remove(.changingFrameSize)
        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        swipeNotifier.setAccessoryOffset(UIEdgeInsets(top: view.safeAreaInsets.top,
                                                      left: view.safeAreaInsets.left + chatLayout.settings.additionalInsets.left,
                                                      bottom: view.safeAreaInsets.bottom,
                                                      right: view.safeAreaInsets.right + chatLayout.settings.additionalInsets.right))
    }


    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if inputBarView.superview == nil,
           topMostViewController() is ChatViewController {
            DispatchQueue.main.async { [weak self] in
                self?.reloadInputViews()
            }
        }
    }
    
    private func configInputView(hidden: Bool) {
        contentStackViewBottomAnchor?.isActive = false
        contentStackViewBottomAnchor = contentStackView.bottomAnchor.constraint(equalTo: hidden ? view.bottomAnchor : inputBarView.topAnchor, constant: 0)
        contentStackViewBottomAnchor!.isActive = true
    }
    
    @objc
    private func loadInitialMessages() {
        guard !currentControllerActions.options.contains(.loadingInitialMessages) else { return }
        
        currentControllerActions.options.insert(.loadingInitialMessages)
        chatController.loadInitialMessages { [weak self] sections in
            self?.processUpdates(with: sections, animated: false, requiresIsolatedProcess: true) {
                self?.currentControllerActions.options.remove(.loadingInitialMessages)
                self?.ignoreInterfaceActions = false
            }
        }
    }
    
    private func setRightButtons(show: Bool) {
        if show {
#if ENABLE_CALL
            navigationItem.rightBarButtonItems = [settingButton, mediaButton]
#else
            navigationItem.rightBarButtonItems = [settingButton]
#endif
        } else {
            navigationItem.rightBarButtonItems = nil
        }
    }
    
    private func setupNavigationBar() {
        chatController.getTitle()
        navigationItem.titleView = titleView
        
        if let navigationBar = navigationController?.navigationBar {
            let underline = UIView()
            underline.backgroundColor = .cE8EAEF
            underline.translatesAutoresizingMaskIntoConstraints = false
            
            navigationBar.addSubview(underline)
            NSLayoutConstraint.activate([
                underline.heightAnchor.constraint(equalToConstant: 1),
                underline.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
                underline.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
                underline.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor)
            ])
        }
    }
    
    private func setupWatermarkView() {
        view.insertSubview(watermarkView, at: 0)
        
        NSLayoutConstraint.activate([
            watermarkView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            watermarkView.topAnchor.constraint(equalTo: view.topAnchor),
            watermarkView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            watermarkView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc func appDidEnterBackground() {
        print("App did enter background")
        AudioPlayController.shared.stop()
    }

    private func setupInputBar() {
        inputBarView.delegate = self
        inputBarView.shouldAnimateTextDidChangeLayout = true
        inputBarView.maxTextViewHeight = 120.h
        
        if let userID = chatController.getSelfInfo()?.userID {
            inputBarView.identity = userID
        }
        inputBarView.isHidden = hiddenInputBar
    }
    
    private func setupRefreshControl() {
        let header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(handleRefresh))
        header.stateLabel?.isHidden = true
        header.lastUpdatedTimeLabel?.isHidden = true
        header.isCollectionViewAnimationBug = true

    }
    
    @objc private func handleRefresh() {
        if !currentControllerActions.options.contains(.loadingPreviousMessages) {
            currentControllerActions.options.insert(.loadingPreviousMessages)
        }

        chatController.loadPreviousMessages { [weak self] sections in
            guard let self else {
                return
            }

            let animated = !self.isUserInitiatedScrolling
            self.processUpdates(with: sections, animated: false, requiresIsolatedProcess: true) {
                self.collectionView.mj_header?.endRefreshing()

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
                    self.currentControllerActions.options.remove(.loadingPreviousMessages)
                }
            }
        }
    }
    
    private func revokeMessage(with id: String, completion: @escaping (Bool) -> Void) {
        self.chatController.revokeMessage(with: id, completion: completion)
    }

    private func showMediaLinkSheet() {

        resetOffset(newBottomInset: 0)
        inputBarView.inputResignFirstResponder()

    #if ENABLE_CALL
        if CallingManager.isBusy {
            presentAlert(title: "callingBusy".innerLocalized())
            
            return
        }
    #endif
        presentMediaActionSheet { [weak self] in
            guard let self else { return }
            
            if otherIsInBlacklist {
                presentAlert(title: "otherIsInblacklistHit".innerLocalizedFormat(arguments: "voice".innerLocalized()), cancelTitle: "iSee".innerLocalized())
            } else {
                startMedia(isVideo: false)
            }
        } videoHandler: { [weak self] in
            guard let self else { return }
            
            if otherIsInBlacklist {
                presentAlert(title: "otherIsInblacklistHit".innerLocalizedFormat(arguments: "video".innerLocalized()), cancelTitle: "iSee".innerLocalized())
            } else {
                startMedia(isVideo: true)
            }
        }
    }

    private func startMedia(isVideo: Bool) {
        guard mediaButton.isEnabled else { return }

        resetOffset(newBottomInset: 0)
#if ENABLE_CALL
        let conversation = chatController.getConversation()
        
            let user = CallingUserInfo(userID: conversation.userID!, nickname: conversation.showName, faceURL: conversation.faceURL)
            let me = chatController.getSelfInfo()
            let inviter = CallingUserInfo(userID: me?.userID, nickname: me?.nickname, faceURL: me?.faceURL)
            
            CallingManager.manager.startLiveChat(inviter: inviter,
                                                 others: [user],
                                                 isVideo: isVideo)
#endif
    }

    func inputTextViewResignFirstResponder() {
        inputBarView.inputTextView.resignFirstResponder()
        resetOffset(newBottomInset: 0)
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
        popover?.dismiss()
        
        if collectionView.isTracking {
            let bottomInset = scrollView.contentInset.bottom
            
            if scrollView.contentOffset.y < lastContentOffset && scrollView.contentOffset.y > -bottomInset {

                let scrollViewHeight = scrollView.frame.height
                let contentHeight = scrollView.contentSize.height
                
                if scrollView.contentOffset.y + scrollViewHeight < contentHeight {


                    if inputBarView.inputTextView.isFirstResponder {
                        inputBarView.inputTextView.resignFirstResponder()
                        resetOffset(newBottomInset: 0)
                    }
                }
            }
        }
        
        lastContentOffset = scrollView.contentOffset.y

        if currentControllerActions.options.contains(.updatingCollection), collectionView.isDragging {


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
              !currentControllerActions.options.contains(.loadingMoreMessages),
              !currentInterfaceActions.options.contains(.scrollingToTop),
              !currentInterfaceActions.options.contains(.scrollingToBottom) else {
            return
        }
        
        if scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + scrollView.bounds.height {
            loadPreviousMessages()
        } else {
            if !currentControllerActions.options.contains(.loadingPreviousMessages), !keepContentOffsetAtBottom {
                chatLayout.keepContentOffsetAtBottomOnBatchUpdates = collctionViewIsAtBottom
            }
            
            let contentOffsetY = scrollView.contentOffset.y

            let contentSizeH = scrollView.contentSize.height
            let scrollViewBoundsH = scrollView.bounds.size.height
            let footerViewY = max(contentSizeH, scrollViewBoundsH) + scrollView.contentInset.bottom
            
            let footerViewFullApperance = contentOffsetY + scrollViewBoundsH
            let isCanRefreshing = footerViewFullApperance - footerViewY - 50 > 0
            
            if scrollView.isDragging, isCanRefreshing {
                loadMoreMessages()
            }
        }
    }
    
    private func loadPreviousMessages() {


        if !currentControllerActions.options.contains(.loadingPreviousMessages) {
            currentControllerActions.options.insert(.loadingPreviousMessages)
        }
        
        chatController.loadPreviousMessages { [weak self] sections in
            guard let self else {
                return
            }

            let animated = !self.isUserInitiatedScrolling
            self.processUpdates(with: sections, animated: animated, requiresIsolatedProcess: false) {
                self.currentControllerActions.options.remove(.loadingPreviousMessages)
            }
        }
    }
    
    private func loadMoreMessages() {


        currentControllerActions.options.insert(.loadingMoreMessages)
        chatLayout.keepContentOffsetAtBottomOnBatchUpdates = false
        chatController.loadMoreMessages { [weak self] sections in
            guard let self else {
                return
            }

            let animated = !self.isUserInitiatedScrolling
            self.processUpdates(with: sections, animated: false, requiresIsolatedProcess: true) {
                self.chatLayout.keepContentOffsetAtBottomOnBatchUpdates = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
                    self.currentControllerActions.options.remove(.loadingMoreMessages)
                }
            }
        }
    }
    
    fileprivate var isUserInitiatedScrolling: Bool {
        collectionView.isDragging || collectionView.isDecelerating
    }
    
    private var collctionViewIsAtBottom: Bool {
        let contentOffsetAtBottom = CGPoint(x: collectionView.contentOffset.x,
                                            y: chatLayout.collectionViewContentSize.height - collectionView.frame.height + collectionView.adjustedContentInset.bottom)
        
        return contentOffsetAtBottom.y <= collectionView.contentOffset.y
    }
    
    func scrollToBottom(animated: Bool = true, completion: (() -> Void)? = nil) {

        let contentOffsetAtBottom = CGPoint(x: collectionView.contentOffset.x,
                                            y: chatLayout.collectionViewContentSize.height - collectionView.frame.height + collectionView.adjustedContentInset.bottom)
        
        guard contentOffsetAtBottom.y > collectionView.contentOffset.y else {
            completion?()
            return
        }
        
        let initialOffset = collectionView.contentOffset.y
        let delta = contentOffsetAtBottom.y - initialOffset
        if abs(delta) > chatLayout.visibleBounds.height {

            animator = ManualAnimator()
            animator?.animate(duration: TimeInterval(animated ? 0.25 : 0.1), curve: .easeInOut) { [weak self] percentage in
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

extension ChatViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("=====\(#function)")
        popover?.dismiss()
        dataSource.didSelectItemAt(collectionView, indexPath: indexPath)
    }
}


extension ChatViewController: ChatControllerDelegate {
    
    func configMeiaResource(msg: Message.Data) -> MediaResource? {
                
        if case .image(let source, _) = msg {
            return MediaResource(thumbUrl: source.thumb?.url,
                                 url: source.source.url,
                                 type: .image)
        }
        if case .video(let source, _) = msg {
            return MediaResource(thumbUrl: source.thumb?.url,
                                 url: source.source.url,
                                 type: .video,
                                 fileSize: source.fileSize ?? 0)
        }
        if case .face(let source, _) = msg {
            return MediaResource(thumbUrl: source.url,
                                 url: source.url)
        }
        
        return nil
    }
    
    func previewMedias(id: String, data: Message.Data) {
        guard let item = configMeiaResource(msg: data) else { return }
        
        var vc = MediaPreviewViewController(resources: [item])
                        
        vc.showIn(controller: self) { [self] idx in

            if let ID = item.ID, let tag = self.dataSource.mediaImageViews[ID] {
                return self.collectionView.viewWithTag(tag)
            }
            
            return nil
        }
        
        vc.onButtonAction = { [self] type in
            self.chatController.defaultSelecteMessage(with: id, onlySelect: false)
            
            if type == PreviewModalView.ActionType.forward {
                self.forwardMessage(merge: false)
            }
        }
    }
    
    func didTapContent(with id: String, data: Message.Data) {
        popover?.dismiss()
        
        switch data {
        case .url(let uRL, let isLocallyStored):
            if uRL.absoluteString.hasPrefix(linkSchme) {
                let userID = uRL.absoluteString.replacingOccurrences(of: linkSchme, with: "")
                
                if !userID.isEmpty {
                    viewUserDetail(user: User(id: userID, name: ""))
                }
            } else if uRL.absoluteString.hasPrefix(sendFriendReqSchme) {
                ProgressHUD.animate()
                chatController.addFriend { r in
                    ProgressHUD.success("sendSuccessfully".innerLocalized())
                } onFailure: { errCode, errMsg in
                    ProgressHUD.error("canNotAddFriends".innerLocalized())
                }
            } else {
                UIApplication.shared.open(uRL)
            }
        case .image(let source, let isLocallyStored):
            if source.ex?.isFace == true {
                var media = MediaResource(thumbUrl: source.thumb?.url,
                                          url: source.source.url,
                                          ID: id)
     
                let vc = MediaPreviewViewController(resources: [media])
                
                vc.showIn(controller: self) { [weak self] _ in
                    if let tag = self?.dataSource.mediaImageViews[id] {
                        return self?.collectionView.viewWithTag(tag)
                    }
                    
                    return nil
                }
            } else {
                previewMedias(id: id, data: data)
            }
        case .video(let source, let isLocallyStored):
            previewMedias(id: id, data: data)
            
        case .file(let source, let isLocallyStored):
            showFile(url: source.url)
        case .card(let source):
            let vc = UserDetailTableViewController(userId: source.user.id, groupId: chatController.getConversation().groupID, userDetailFor: .card)
            navigationController?.pushViewController(vc, animated: true)
            
        case .location(let source):
            let vc = LocationViewController(LocationPoint(title: source.name, desc: source.address!, longitude: source.longitude, latitude: source.latitude))
            navigationController?.pushViewController(vc, animated: true)
            
        case .notice(let source):
            if source.type == .oa {
                if let derictURL = source.derictURL, let url = URL(string: derictURL) {
                    UIApplication.shared.open(url)
                } else {
                    guard let snapshotUrl = source.snapshotUrl, !snapshotUrl.isEmpty else { return }
                    let vc = MediaPreviewViewController(resources: [MediaResource(thumbUrl: URL(string: snapshotUrl),
                                                                                  url: URL(string: snapshotUrl)!)])
                    vc.showIn(controller: self) { idx in
                        nil
                    }
                }
            }
        default:
            break
        }
        print("\(#function)")
    }
    
    private func showFile(url: URL) {
        inputBarView.inputTextView.resignFirstResponder()
        
        documentInteractionController = UIDocumentInteractionController(url: url)
        documentInteractionController.delegate = self
        
        DispatchQueue.main.async { [self] in

            let r = documentInteractionController.presentPreview(animated: true)
            if !r {
                documentInteractionController.presentOptionsMenu(from: view.bounds, in: view, animated: true)
            }
        }
    }
    
    func friendInfoChanged(info: FriendInfo) {
        titleView.mainLabel.text = info.showName
        titleView.mainTailLabel.isHidden = true
        
        guard !hiddenInputBar else { return }
        
        let type = chatController.getConversation().conversationType
        
        setRightButtons(show: type == .c2c)
        settingButton.isEnabled = true
    }
    
    func groupInfoChanged(info: GroupInfo) {
        titleView.mainLabel.text = "\(info.groupName!)"
        titleView.mainTailLabel.text = "(\(info.memberCount))"
        
        guard !hiddenInputBar else { return }
        
        setRightButtons(show: info.status == .ok || info.status == .muted)
        settingButton.isEnabled = info.memberCount > 0
    }
    
    func onlineStatus(status: UserStatusInfo) {
        titleView.showSubArea(status.statusDesc != nil)
        titleView.subLabel.text = status.statusDesc
        titleView.setDotHighlight(highlight: status.status == 1)
    }
    
    func typingStateChanged(to state: TypingState) {
        titleView.showTyping(state == .typing)
    }
    
    func updateUnreadCount(count: Int) {
        if !editNotifier.isEditing {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: count > 0 ? (count > 99 ? "99+" : "\(count)") : nil, image: UIImage(nameInBundle: "common_back_icon")) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func isInGroup(with isIn: Bool) {
        guard !hiddenInputBar else { return }
        
        inputBarView.isHidden = !isIn
        
        if isIn {
            bottomTipsView?.removeFromSuperview()
            bottomTipsView = nil
            setRightButtons(show: true)
        } else {
            if bottomTipsView == nil {
                bottomTipsView = EditingBottomTipsView()
                view.addSubview(bottomTipsView!)

                NSLayoutConstraint.activate([
                    bottomTipsView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    bottomTipsView!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    bottomTipsView!.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
            }
            setRightButtons(show: false)
        }
    }
    
    func update(with sections: [Section], requiresIsolatedProcess: Bool) {
        processUpdates(with: sections, animated: true, requiresIsolatedProcess: requiresIsolatedProcess)
    }
    
    private func processUpdates(with sections: [Section], animated: Bool = true, requiresIsolatedProcess: Bool, completion: (() -> Void)? = nil) {
        guard isViewLoaded else {
            dataSource.sections = sections
            return
        }
        
        guard currentInterfaceActions.options.isEmpty ||
                editNotifier.isEditing || // In edit mode, when a cell is selected, sliding the cell will cause the selected state to disappear.
                ignoreInterfaceActions else {
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
            
            if ignoreInterfaceActions { // only first load
                var changeSet = StagedChangeset(source: dataSource.sections, target: sections).flattenIfPossible()
                guard !changeSet.isEmpty else {
                    completion?()
                    return
                }
                guard let data = changeSet.last?.data else { 
                    completion?()
                    return
                }
                
                dataSource.sections = data
                
                if requiresIsolatedProcess {
                    chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = true
                    currentInterfaceActions.options.insert(.updatingCollectionInIsolation)
                }
                
                let positionSnapshot: ChatLayoutPositionSnapshot!
                if self.scrollToTop {
                    positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: 0), kind: .header, edge: .top)
                } else {
                    positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: sections.count - 1), kind: .footer, edge: .bottom)
                }
                
                self.collectionView.reloadData()

                self.chatLayout.restoreContentOffset(with: positionSnapshot)
                
                self.chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = false
                if requiresIsolatedProcess {
                    self.currentInterfaceActions.options.remove(.updatingCollectionInIsolation)
                }
                completion?()
                self.currentControllerActions.options.remove(.updatingCollection)
                
                return
            }


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
                let positionSnapshot: ChatLayoutPositionSnapshot!
                if self.scrollToTop {
                    positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: 0), kind: .header, edge: .top)
                } else {
                    positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: sections.count - 1), kind: .footer, edge: .bottom)
                }
                self.collectionView.reloadData()

                self.chatLayout.restoreContentOffset(with: positionSnapshot)
            },
                                  completion: { _ in
                DispatchQueue.main.async { [self] in
                 
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


extension ChatViewController: UIGestureRecognizerDelegate {
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        inputBarView.inputResignFirstResponder()
        resetOffset(newBottomInset: 0)
        popover?.dismiss()
    }
    
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


extension ChatViewController: CoustomInputBarAccessoryViewDelegate {
    
    private func completionHandler() -> ([Section]) -> Void {
        let completion: ([Section]) -> Void = { [weak self] sections in
            self?.inputBarView.sendButton.stopAnimating()
            self?.currentInterfaceActions.options.remove(.sendingMessage)
            self?.processUpdates(with: sections, animated: true, requiresIsolatedProcess: false)
        }
        
        return completion
    }
    
    func uploadFile(image: UIImage,  completion: @escaping (URL) -> Void) {
        ProgressHUD.animate()
        chatController.uploadFile(image: image) { p in
            ProgressHUD.progress(p)
        } completion: { u in
            guard let u, let url = URL(string: u) else { return }
            completion(url)
            ProgressHUD.dismiss()
        }
    }
    
    public func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        guard !currentInterfaceActions.options.contains(.sendingMessage) else {
            return
        }
        scrollToBottom()
    }
    
    public func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let messageText = inputBar.inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        let completion = completionHandler()
        
        currentInterfaceActions.options.insert(.sendingMessage)
        
        guard !messageText.isEmpty else {
            self.currentInterfaceActions.options.remove(.sendingMessage)
            return
        }
        
        keepContentOffsetAtBottom = true
        
        self.scrollToBottom(completion: {
            inputBar.sendButton.startAnimating()
            self.chatController.sendMessage(.text(TextMessageSource(text: messageText)), completion: completion)
        })
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith attachments: [CustomAttachment]) {

        let completion = completionHandler()
        
        currentInterfaceActions.options.insert(.sendingMessage)
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        
        guard !attachments.isEmpty else {
            currentInterfaceActions.options.remove(.sendingMessage)
            return
        }
        keepContentOffsetAtBottom = true

        scrollToBottom(completion: {

            inputBar.sendButton.startAnimating()
            attachments.forEach { attachment in

                switch attachment {

                case .image(let relativePath, let path):
                    let source = MediaMessageSource(source: MediaMessageSource.Info(url: URL(string: path)!, relativePath: relativePath))
                    
                    self.chatController.sendMessage(.image(source, isLocallyStored: true),
                                                    completion: completion)

                case .audio(let relativePath, let duration):
                    let source = MediaMessageSource(source: MediaMessageSource.Info(relativePath: relativePath), duration: duration)
                    
                    self.chatController.sendMessage(.audio(source, isLocallyStored: true), completion: completion)
                    
                case .video(let thumbRelativePath, let thumbPath, let mediaRelativePath, let duration):
                    let source = MediaMessageSource(source: MediaMessageSource.Info(relativePath: mediaRelativePath),
                                                    thumb: MediaMessageSource.Info(url: URL(string: thumbPath)!, relativePath: thumbRelativePath),
                                                    duration: duration)
                    
                    self.chatController.sendMessage(.video(source, isLocallyStored: true), completion: completion)
                    
                case .file(let path):
                    let source = FileMessageSource(url: URL(string: path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!))
                    
                    self.chatController.sendMessage(.file(source, isLocallyStored: true), completion: completion)
                    
                case .face(let url, let localPath):
                    let source = FaceMessageSource(localPath: localPath, url: url, index: -1)
                    
                    self.chatController.sendMessage(.face(source, isLocallyStored: false), completion: completion)
                }
            }
        })
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressPadItemWith type: PadItemType) {

        
        switch type {
        case .media:
            showMediaLinkSheet()
        case .card:
            showSelectContacts()
        case .location:
            showLocationView()
        default:
            break
        }
    }
    
    func didPressRemoveReplyButton() {
        chatController.defaultSelecteMessage(with: nil, onlySelect: false)
    }
    
    func inputTextViewDidChange() {
        chatController.typing(doing: true)
        typingDebounceTimer?.invalidate()
        
        typingDebounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.chatController.typing(doing: false)
        }
    }
    
    private func showSelectContacts() {

        let completion = completionHandler()
#if ENABLE_ORGANIZATION
        let vc = MyContactsViewController(types: [.friends, .staff])
#else
        let vc = MyContactsViewController(types: [.friends])
#endif
        vc.allowsSelecteAll = false
        
        vc.selectedContact { [weak self, weak vc] info in
            guard let self, let vc, let user = info.first else { return }
            let alertController = UIAlertController(title: nil, message: "确定发送该名片到聊天吗".innerLocalized(), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "取消".innerLocalized(), style: .cancel))
            alertController.addAction(UIAlertAction(title: "确定".innerLocalized(), style: .default, handler: { [self] _ in
                self.dismiss(animated: true)
                
                let source = CardMessageSource(user: User(id: user.ID!, name: user.name!, faceURL: user.faceURL))
                self.chatController.sendMessage(.card(source), completion: completion)
            }))
            vc.present(alertController, animated: true)
        }
        
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    private func showLocationView() {

        let completion = completionHandler()
        
        let vc = LocationViewController()
        vc.onSendLocation { point in
            let source = LocationMessageSource(desc: point.desc, latitude: point.latitude, longitude: point.longitude)
            
            self.chatController.sendMessage(.location(source), completion: completion)
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
}


extension ChatViewController: KeyboardListenerDelegate {
    
    func keyboardWillChangeFrame(info: KeyboardInfo) {
        guard !currentInterfaceActions.options.contains(.changingFrameSize),
              !currentInterfaceActions.options.contains(.showingPreview),
              collectionView.contentInsetAdjustmentBehavior != .never,
              let keyboardFrame = collectionView.window?.convert(info.frameEnd, to: view),
              keyboardFrame.minY > 0,
              inputBarView.inputTextView.isFirstResponder else { // The keyboard on the presented view will affect this.
            return
        }
                
        currentInterfaceActions.options.insert(.changingKeyboardFrame)
        let newBottomInset = UIScreen.main.bounds.height - keyboardFrame.minY
                
        if collectionView.contentInset.bottom != newBottomInset {
            let positionSnapshot = chatLayout.getContentOffsetSnapshot(from: .bottom)

            if currentControllerActions.options.contains(.updatingCollection) {
                UIView.performWithoutAnimation {
                    self.collectionView.performBatchUpdates({})
                }
            }

            currentInterfaceActions.options.insert(.changingContentInsets)
            inputBarViewBottomAnchor.constant = -newBottomInset
            
            UIView.animate(withDuration: info.animationDuration, animations: {
                
                self.view.layoutIfNeeded()
                
                if let positionSnapshot, !self.isUserInitiatedScrolling {
                    self.chatLayout.restoreContentOffset(with: positionSnapshot)
                }
                if #available(iOS 13.0, *) {
                } else {


                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
            }, completion: { _ in
                self.currentInterfaceActions.options.remove(.changingContentInsets)
            })
        }
        
        if newBottomInset == 0,
            info.frameEnd.minY == UIScreen.main.bounds.height,
            info.frameEnd.minY > info.frameBegin.minY,
           inputBarView.inputTextView.inputView == nil { // If there is emoji/pad input, it will not be hidden.
            resetOffset(newBottomInset: newBottomInset, duration: info.animationDuration)
        }
    }
    
    func resetOffset(newBottomInset: CGFloat, duration: CGFloat = 0.25) {
        let positionSnapshot = chatLayout.getContentOffsetSnapshot(from: .bottom)
        inputBarViewBottomAnchor.constant = -newBottomInset
        
        UIView.animate(withDuration: duration, animations: {
            self.view.layoutIfNeeded()
        })

        if let positionSnapshot, !self.isUserInitiatedScrolling {
            self.chatLayout.restoreContentOffset(with: positionSnapshot)
        }
        self.currentInterfaceActions.options.remove(.changingContentInsets)
    }
    
    func keyboardDidChangeFrame(info: KeyboardInfo) {
        guard currentInterfaceActions.options.contains(.changingKeyboardFrame) else {
            return
        }
        currentInterfaceActions.options.remove(.changingKeyboardFrame)
    }
    
    func keyboardWillShow(info: KeyboardInfo) {
        scrollToBottom(animated: false)
    }
    
    func keyboardWillHide(info: KeyboardInfo) {
        if info.frameBegin.height > 200.0 {
            chatController.typing(doing: false)
        }
    }
}

extension ChatViewController {
    func deleteMessage() {
        ProgressHUD.animate()
        chatController.deleteMessage { [weak self] in
            ProgressHUD.dismiss()
        }
    }
    
    func forwardMessage(merge: Bool) {
        inputTextViewResignFirstResponder()
        
        let title = getForwardTitle(for: chatController)
        
        let vc = createContactsViewController()
        vc.selectedHandler = { [weak self, weak vc] infos in
            guard let self, let vc else { return }
            
            let forwardCard = setupForwardCard(with: title, usersInfo: infos)
            
            if let presentedVC = self.presentedViewController {
                UIApplication.shared.keyWindow()?.addSubview(forwardCard)
            } else {
                vc.navigationController?.topViewController?.view.addSubview(forwardCard)
            }
            
            forwardCard.cancelHandler = {
                forwardCard.removeFromSuperview()
            }
            
            forwardCard.confirmHandler = { [weak self] text in
                forwardCard.removeFromSuperview()
                guard let self else { return }
                
                let (usersID, groupsID) = self.extractUserAndGroupIDs(from: infos)
                self.chatController.forwardMessage(merge: merge, usersID: usersID, groupsID: groupsID, title: title, attachMessage: text)
                self.dismissViewControllerStack(vc: vc)
            }
            
            forwardCard.reloadData()
        }
        
        presentOrPushViewController(vc)
    }

    private func getForwardTitle(for chatController: ChatController) -> String {
        let selectedMessages = chatController.getSelectedMessages()
        var title: String!
        
        if selectedMessages.count == 1 {
            title = selectedMessages.first?.getSummary() ?? ""
        } else {
            if chatController.getConversation().conversationType == .c2c {
                chatController.getOtherInfo { [weak self] others in
                    let aNickname = others.nickname ?? ""
                    let bNickname = self?.chatController.getSelfInfo()?.nickname ?? ""
                    
                    title = "aWithbChatHistory".innerLocalizedFormat(arguments: aNickname, bNickname)
                }
            } else {
                title = "groupChatHistory".innerLocalized()
            }
        }
        
        return title
    }

    private func createContactsViewController() -> MyContactsViewController {
    #if ENABLE_ORGANIZATION
        return MyContactsViewController(types: [.friends, .groups, .staff, .recent], multipleSelected: true)
    #else
        return MyContactsViewController(types: [.friends, .groups, .recent], multipleSelected: true)
    #endif
    }

    private func setupForwardCard(with title: String, usersInfo: [ContactInfo]) -> ForwardCard {
        let forwardCard = ForwardCard(frame: view.bounds)
        forwardCard.contentLabel.text = title
        forwardCard.numberOfItems = { usersInfo.count }
        forwardCard.itemForIndex = { index in
            let info = usersInfo[index]
            return User(id: info.ID!, name: info.name!, faceURL: info.faceURL)
        }
        return forwardCard
    }

    private func extractUserAndGroupIDs(from infos: [ContactInfo]) -> (usersID: [String], groupsID: [String]) {
        var usersID: [String] = []
        var groupsID: [String] = []
        
        infos.forEach { info in
            if info.type == .group {
                groupsID.append(info.ID!)
            } else {
                usersID.append(info.ID!)
            }
        }
        
        return (usersID, groupsID)
    }

    private func dismissViewControllerStack(vc: MyContactsViewController) {
        if let presentedVC = self.presentedViewController {
            if let presented2 = presentedVC.presentedViewController {
                presented2.dismiss(animated: true)
            } else {
                dismiss(animated: true)
            }
        } else {
            vc.navigationController?.popToViewController(self, animated: true)
        }
    }

    private func presentOrPushViewController(_ vc: UIViewController) {
        if let presented = presentedViewController {
            let nav = UINavigationController(rootViewController: vc)
            
            let closeButtonItem = UIBarButtonItem(title: "关闭") {
                presented.dismiss(animated: true)
            }
            vc.navigationItem.leftBarButtonItem = closeButtonItem
            
            presented.present(nav, animated: true)
        } else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

}

extension ChatViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
        return view
    }
    
    func documentInteractionControllerRectForPreview(_ controller: UIDocumentInteractionController) -> CGRect {
        return view.frame
    }
    
    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        print("Dismissed!!!")
    }
}

extension ChatViewController: GestureDelegate {
    
    private func copyAction(value: String) -> PopoverCollectionViewController.MenuItem {
        return PopoverCollectionViewController.MenuItem(title: ToolItem.copy.title, image: ToolItem.copy.image) { [weak self] in
            let pasteboard = UIPasteboard.general
            pasteboard.string = value
        }
    }
    
    private func deleteAction(id: String) -> PopoverCollectionViewController.MenuItem {
        return PopoverCollectionViewController.MenuItem(title: ToolItem.delete.title, image: ToolItem.delete.image) { [weak self] in
            self?.chatController.defaultSelecteMessage(with: id, onlySelect: false)
            ProgressHUD.animate()
            self?.chatController.deleteMessage { [weak self] in
                ProgressHUD.dismiss()
            }
        }
    }
    
    private func forwardAction(id: String) -> PopoverCollectionViewController.MenuItem {
        return PopoverCollectionViewController.MenuItem(title: ToolItem.forward.title, image: ToolItem.forward.image) { [weak self] in
            self?.chatController.defaultSelecteMessage(with: id, onlySelect: false)
            self?.forwardMessage(merge: false)
        }
    }
    
    private func revokeAction(id: String) -> PopoverCollectionViewController.MenuItem {
        return PopoverCollectionViewController.MenuItem(title: ToolItem.revoke.title, image: ToolItem.revoke.image) { [weak self] in
            ProgressHUD.animate()
            self?.revokeMessage(with: id) { r in
                if r {
                    ProgressHUD.dismiss()
                } else {
                    ProgressHUD.error("xFailed".innerLocalizedFormat(arguments: "menuRevoke".innerLocalized()))
                }
            }
        }
    }
    
    private func addFaceAction(id: String, url: URL) -> PopoverCollectionViewController.MenuItem {
        return PopoverCollectionViewController.MenuItem(title: ToolItem.addFace.title, image: ToolItem.addFace.image) { [weak self] in
            FaceManager.shared.addImage(url) { [self] in
                FaceManager.shared.save(self?.chatController.getSelfInfo()?.userID)
                self?.inputBarView.emojiView.forceReload()
                ProgressHUD.text("addSuccessfully".innerLocalized())
            }
        }
    }
    
    func longPress(with message: Message, sourceView: UIView, point: CGPoint) {
        
        guard !editNotifier.isEditing else { return }
    
        keepContentOffsetAtBottom = false
        
        print("longPress:\(message)")
        
        if hiddenInputBar {
            if case .text(let source) = message.data {
                popover = PopoverCollectionViewController(items: [copyAction(value: source.text)])
                popover!.show(in: self, sender: sourceView, point: point, passthroughViews: collectionView.subviews)
                
                popover!.onDismiss = { [weak self] in
                    self?.keepContentOffsetAtBottom = true
                }
            }
            return
        }
        
        var actions: [PopoverCollectionViewController.MenuItem]?
        var isSent = false
        
        if case .sent(_) = message.status {
            isSent = true
        }
        
        switch message.data {
            case let .text(source):
                if source.type == .text {
                    actions = isSent ? [copyAction(value: source.text),
                                        forwardAction(id: message.id),]
                    : [copyAction(value: source.text)]
                } else {
                    actions = [copyAction(value: source.text ?? "")]
                }
            case let .image(source, isLocallyStored: _):
                actions = isSent ? [forwardAction(id: message.id),]
                : []
            case let .audio(source, isLocallyStored: _):
                actions = [/*replyAction(id: message.id, name: message.owner.name, body: "[\("语音".innerLocalized())]"),*/
                ]
            case let .video(source, isLocallyStored: _):
                actions = isSent ? [forwardAction(id: message.id),]
                : []
            case let .file(source, isLocallyStored:_):
                actions = isSent ? [forwardAction(id: message.id),]
                : []
            case let .card(source):
                actions = isSent ? [forwardAction(id: message.id),]
                : []
            case let .location(source):
                actions = isSent ? [forwardAction(id: message.id),]
                : []
            case let .face(source, isLocallyStored: _):
                actions = isSent ? [forwardAction(id: message.id),]
                : []
            default:
                return
            }
            if var actions {
                if chatController.canRevokeMessage(msg: message) {
                    actions.append(revokeAction(id: message.id))
                }
                
                if case .image(let source, isLocallyStored: _) = message.data {
                    actions.append(addFaceAction(id: message.id, url: source.thumb?.url ?? source.source.url))
                }
                
                if case .face(let source, isLocallyStored: _) = message.data {
                    actions.append(addFaceAction(id: message.id, url: source.url))
                }
                
                let d = deleteAction(id: message.id)
                actions.insert(d, at: 0)
                
                let visibleCells = collectionView.visibleCells
                var subviews = visibleCells.flatMap({ $0.contentView.subviews })
                let subviews2 = subviews.flatMap({ $0.subviews })
                let subviews3 = subviews2.filter({ $0 is UIStackView }) as [UIStackView]

                popover = PopoverCollectionViewController(items: actions)
                popover!.show(in: self, sender: sourceView, point: point, passthroughViews: subviews3)
                
                popover!.onDismiss = { [weak self] in
                    self?.keepContentOffsetAtBottom = true
                }
        }
    }
    
    func didTapAvatar(with user: User) {
        popover?.dismiss()
        
        viewUserDetail(user: user)
    }
    
    func viewUserDetail(user: User) {
        if chatController.getConversation().conversationType == .superGroup {
            chatController.getGroupInfo(force: false, completion: { [weak self] info in
                guard let self else { return }
                
                if info.lookMemberInfo != 1 || chatController.getIsAdminOrOwner() {
                    chatController.getGroupMembers(userIDs: [user.id], memory: false) { [weak self] mi in
                        guard !mi.isEmpty else { return }

                        let vc = UserDetailTableViewController(userId: user.id, groupInfo: info, groupMemberInfo: mi[0], userInfo: user.toSimplePublicUserInfo())
                        self?.navigationItem.backBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
                        self?.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            })
        } else {
            let vc = UserDetailTableViewController(userId: user.id, groupId: chatController.getConversation().groupID, userInfo: user.toSimplePublicUserInfo())
            navigationItem.backBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func didLongPressAvatar(with id: String, name: String) {
    }
    
    func onTap(with indexPath: IndexPath) {
    }
    
    func onTapEdgeAligningView() {
        popover?.dismiss()
    }
}
