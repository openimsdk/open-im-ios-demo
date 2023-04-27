
import Photos
import RxKeyboard
import RxSwift
import SnapKit
import SVProgressHUD
import UIKit

class MessageListViewController: UIViewController {
    private lazy var chatBar: ChatToolBar = {
        let v = ChatToolBar(moveTo: self.view, conversation: _viewModel.conversation)
        v.padView.delegate = self
        v.delegate = self
        return v
    }()

    private lazy var _tableView: UITableView = {
        let v = UITableView()
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        v.separatorStyle = .none
        for cellType in MessageCell.allCells {
            v.register(cellType.self, forCellReuseIdentifier: cellType.className)
        }
        let refresh: UIRefreshControl = {
            let v = UIRefreshControl(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
            v.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self, weak v] in
                self?._viewModel.loadMoreMessages(completion: nil)
                v?.endRefreshing()
            }).disposed(by: _disposeBag)
            return v
        }()
        v.refreshControl = refresh
        return v
    }()

    private lazy var _photoHelper: PhotoHelper = {
        let v = PhotoHelper()
        v.didPhotoSelected = { [weak self] (images: [UIImage], assets: [PHAsset], _: Bool) in
            guard let sself = self else { return }
            var items: [PhotoHelper.MediaTuple] = []
            for (index, asset) in assets.enumerated() {
                let item = PhotoHelper.MediaTuple(thumbnail: images[index], asset: asset)
                items.append(item)
            }
            self?._photoHelper.sendMediaTuple(assets: items, with: sself._viewModel)
        }

        v.didCameraFinished = { [weak self] (photo: UIImage?, videoPath: URL?) in
            guard let sself = self else { return }
            if let photo = photo {
                self?._viewModel.sendImage(image: photo)
            }

            if let videoPath = videoPath {
                self?._photoHelper.sendVideoAt(url: videoPath, messageSender: sself._viewModel)
            }
        }
        return v
    }()

    private lazy var _audioPlayer: AVPlayer = {
        let v = AVPlayer(playerItem: nil)
        return v
    }()

    private let _disposeBag = DisposeBag()

    private let _viewModel: MessageListViewModel
    private var _bottomConstraint: Constraint?
    init(viewModel: MessageListViewModel) {
        _viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private weak var currentPlayingMessage: MessageInfo?

    private let titleLabel: UILabel = {
        let v = UILabel()
        return v
    }()

    private let subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 13)
        v.text = "输入中...".innerLocalized()
        return v
    }()

    lazy var rightBar: UIBarButtonItem = {
        let v = UIBarButtonItem()
        v.image = UIImage(nameInBundle: "common_more_btn_icon")
        v.rx.tap.subscribe(onNext: { [weak self] in
            guard let sself = self else { return }
            let conversationType = sself._viewModel.conversation.conversationType
            switch conversationType {
            case .undefine, .notification, .superGroup:
                break
            case .c2c:
                let viewModel = SingleChatSettingViewModel(conversation: sself._viewModel.conversation)
                let vc = SingleChatSettingTableViewController(viewModel: viewModel, style: .grouped)
                self?.navigationController?.pushViewController(vc, animated: true)
            case .group:
                let vc = GroupChatSettingTableViewController(conversation: sself._viewModel.conversation, style: .grouped)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        }).disposed(by: self._disposeBag)
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        if let last = _viewModel.conversation.latestMsg {
            if last.contentType == .memberQuit, last.sendID == IMController.shared.uid {
                navigationItem.rightBarButtonItem = nil
            } else if last.contentType == .dismissGroup {
                navigationItem.rightBarButtonItem = nil
            } else {
                navigationItem.rightBarButtonItem = rightBar
            }
        } else {
            navigationItem.rightBarButtonItem = rightBar
        }

        initView()
        bindData()
        _viewModel.loadMoreMessages(completion: { [weak self] in
            self?.scrollsToBottom(animated: false)
        })
        _viewModel.markAllMessageReaded()

        NotificationCenter.default.rx.notification(NSNotification.Name.AVPlayerItemDidPlayToEndTime).subscribe(onNext: { [weak self] _ in
            guard let sself = self else { return }
            if let currentItem = sself.currentPlayingMessage {
                sself._viewModel.markAudio(messageId: currentItem.clientMsgID ?? "", isPlaying: false)
            }
        }).disposed(by: _disposeBag)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _viewModel.markAllMessageReaded()
    }

    private var didSetupViewConstraints: Bool = false
    
    private var isAtBottom: Bool = false

    override func updateViewConstraints() {
        super.updateViewConstraints()
        guard !didSetupViewConstraints else { return }
        didSetupViewConstraints = true
    }

    deinit {
        #if DEBUG
            print("dealloc \(type(of: self))")
        #endif
    }

    private func initView() {
        let titleView: UIStackView = {
            let v = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
            v.axis = .vertical
            v.alignment = .center
            v.spacing = 5
            return v
        }()
        navigationItem.titleView = titleView

        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            _bottomConstraint = make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-ChatToolBar.defaultHeight).constraint
        }
        // ChatBar在初始化时已经添加到父视图，注意CharBar的视图层级
        defer {
            chatBar.backgroundColor = StandardUI.color_E8F2FF
        }
    }

    private func bindData() {
        titleLabel.text = _viewModel.conversation.showName

        _viewModel.messagesRelay.asDriver(onErrorJustReturn: []).drive(_tableView.rx.items) { [weak self] (tableView, _, item: MessageInfo) in
            guard let sself = self else { return UITableViewCell() }
            let messageType = item.contentType
            let isRight = item.isSelf
            let cellType = MessageCell.getCellType(by: messageType, isRight: isRight)
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.className) as! MessageCellAble
            cell.setMessage(model: item, extraInfo: ExtraInfo(isC2C: sself._viewModel.conversation.conversationType == .c2c))
            cell.delegate = self
            return cell
        }.disposed(by: _disposeBag)

        let tapToResignFirstResponder = UITapGestureRecognizer()
        tapToResignFirstResponder.rx.event.subscribe(onNext: { [weak self] _ in
            self?.chatBar.textInputView.resignFirstResponder()
        }).disposed(by: _disposeBag)
        view.addGestureRecognizer(tapToResignFirstResponder)
        
        _viewModel.onlyInputTextRelay.subscribe(onNext: { [weak self] r in
            guard let sself = self else { return }
            sself.chatBar.onlyInputText(r)
            if r {
                sself.navigationItem.rightBarButtonItem = nil
            } else {
                sself.navigationItem.rightBarButtonItem = sself.rightBar
            }
        }).disposed(by: _disposeBag)

        _tableView.rx.willBeginDragging.subscribe(onNext: { [weak self] in
            self?.chatBar.textInputView.resignFirstResponder()
        }).disposed(by: _disposeBag)
        
        _tableView.rx.didScroll.subscribe(onNext: { [weak self] in
            guard let sself = self else { return }
            let height = sself._tableView.bounds.height
            let contentOffsetY = sself._tableView.contentOffset.y
            let bottomOffset = sself._tableView.contentSize.height - contentOffsetY
            self?.isAtBottom = bottomOffset <= height
        }).disposed(by: _disposeBag)

        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let sself = self, sself.didSetupViewConstraints else { return }
                if keyboardVisibleHeight <= sself.view.safeAreaInsets.bottom {
                    sself.chatBar.bottomConstraint?.update(offset: -keyboardVisibleHeight)
                } else {
                    sself.chatBar.bottomConstraint?.update(offset: -keyboardVisibleHeight + sself.view.safeAreaInsets.bottom)
                }
                sself.view.setNeedsLayout()
                UIView.animate(withDuration: 0) {
                    if keyboardVisibleHeight <= sself.view.safeAreaInsets.bottom {
                        sself._tableView.contentInset.bottom = keyboardVisibleHeight
                    } else {
                        sself._tableView.contentInset.bottom = keyboardVisibleHeight - sself.view.safeAreaInsets.bottom
                    }
                    sself._tableView.scrollIndicatorInsets.bottom = sself._tableView.contentInset.bottom
                    sself.view.layoutIfNeeded()
                    sself.scrollsToBottom(animated: false)
                }
            }).disposed(by: _disposeBag)

        _viewModel.scrollsToBottom.subscribe(onNext: { [weak self] in
            guard let sself = self else { return }
            if sself.isAtBottom {
                self?.scrollsToBottom()
            }
        }).disposed(by: _disposeBag)

        _viewModel.shouldHideSettingBtnSubject.subscribe(onNext: { [weak self] (shouldHide: Bool) in
            if shouldHide {
                self?.navigationItem.rightBarButtonItem = nil
            }
        }).disposed(by: _disposeBag)

        _viewModel.typingRelay.distinctUntilChanged().map { !$0 }.bind(to: subtitleLabel.rx.isHidden).disposed(by: _disposeBag)
    }

    private func scrollsToBottom(animated: Bool = true) {
        let messageCount = _viewModel.messagesRelay.value.count
        if messageCount > 0 {
            let indexPath = IndexPath(row: messageCount - 1, section: 0)
            _tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
}

// MARK: - ChatPluginPadDelegate

extension MessageListViewController: ChatPluginPadDelegate {
    func didSelect(plugin: PluginType) {
        switch plugin {
        case .album:
            _photoHelper.presentPhotoLibrary(byController: self)
        case .camera:
            _photoHelper.presentCamera(byController: self)
        case .businessCard:
            let vc = FriendListViewController()
            vc.selectCallBack = { [weak self, weak vc] (user: UserInfo) in
                self?._viewModel.sendCard(user: user)
                vc?.navigationController?.popViewController(animated: true)
            }
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - ChatToolBarDelegate

extension MessageListViewController: ChatToolBarDelegate {
    func tb_didTouchSend(text: String) {
        _viewModel.sendText(text: text, quoteMessage: chatBar.quoteMessage)
        chatBar.quoteMessage = nil
    }

    func tb_didAudioRecordEnd(url: String, duration: Int) {
        _viewModel.sendAudio(path: url, duration: duration)
    }
}

extension MessageListViewController: MessageDelegate {
    func didDoubleTapMessageCell(cell _: UITableViewCell, with _: MessageInfo) {}

    func didTapAvatar(with message: MessageInfo) {
        print("点击了\(message.senderNickname)的头像")
        if let uid = message.sendID, uid != IMController.shared.uid {
            //点击自己的头像不做跳转
            let vc = UserDetailTableViewController(userId: uid, groupId: message.groupID)
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func didTapResendBtn(with message: MessageInfo) {
        _viewModel.resend(message: message)
    }

    func didTapQuoteView(cell _: UITableViewCell, with _: MessageInfo) {
        print("点击了引用消息")
    }

    func didTapMessageCell(cell _: UITableViewCell, with message: MessageInfo) {
        switch message.contentType {
        case .audio:
            // 如果当前音频消息正在播放，停止
            if message.isPlaying {
                _audioPlayer.pause()
                _viewModel.markAudio(messageId: message.clientMsgID ?? "", isPlaying: false)
                return
            }
            var playItem: AVPlayerItem?
            if let audioUrl = message.soundElem?.sourceUrl, let url = URL(string: audioUrl) {
                playItem = AVPlayerItem(url: url)
            } else if let audioUrl = message.soundElem?.soundPath {
                let url = URL(fileURLWithPath: audioUrl)
                if FileManager.default.fileExists(atPath: url.path) {
                    playItem = AVPlayerItem(url: url)
                }
            }

            if let playItem = playItem {
                currentPlayingMessage = message
                try? AVAudioSession.sharedInstance().setCategory(.playback)
                _audioPlayer.replaceCurrentItem(with: playItem)
                _audioPlayer.play()
                _viewModel.markAudio(messageId: message.clientMsgID ?? "", isPlaying: true)
            }
        case .image, .video:
            _photoHelper.preview(message: message, from: self)
        case .card:
            guard let content = message.content else { return }
            guard let cardModel = JsonTool.fromJson(content, toClass: BusinessCard.self) else {
                SVProgressHUD.showError(withStatus: "数据格式不正确:\(content)")
                return
            }
            let vc = UserDetailTableViewController(userId: cardModel.userID, groupId: _viewModel.conversation.groupID)
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }

    func didLongPressBubbleView(bubbleView: UIView, with message: MessageInfo) {
        print("长按气泡")
        var toolItems: [ChatToolController.ToolItem] = []
        let isMyMessage = message.sendID == IMController.shared.uid
        switch message.contentType {
        case .text, .quote:
            toolItems = [.copy, .delete, .reply]
        case .audio:
            toolItems = [.delete]
        case .video, .image:
            toolItems = [.delete, .reply]
        default:
            break
        }
        if isMyMessage {
            toolItems.append(.revoke)
        }
        if toolItems.isEmpty { return }
        let menu = ChatToolController(sourceView: bubbleView, items: toolItems)

        menu.collectionView.rx.itemSelected.subscribe(onNext: { [weak self, weak menu] (indexPath: IndexPath) in
            let menuItem = toolItems[indexPath.item]
            switch menuItem {
            case .revoke:
                self?._viewModel.revoke(message: message)
            case .reply:
                self?.chatBar.quoteMessage = message
                self?.chatBar.textInputView.becomeFirstResponder()
            case .delete:
                self?._viewModel.delete(message: message)
            case .copy:
                var content: String?
                switch message.contentType {
                case .text:
                    content = message.content
                case .quote:
                    content = message.quoteElem?.text
                default:
                    content = nil
                }
                UIPasteboard.general.string = content
                SVProgressHUD.showSuccess(withStatus: "复制成功".innerLocalized())
            default:
                break
            }
            menu?.dismiss(animated: true)
        }).disposed(by: menu.disposeBag)

        present(menu, animated: true, completion: nil)
    }
}
