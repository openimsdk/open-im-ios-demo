





import UIKit
import RxSwift
import SnapKit
import RxKeyboard
import Photos
import SVProgressHUD

class MessageListViewController: UIViewController {
    private lazy var chatBar: ChatToolBar = {
        let v = ChatToolBar.init(moveTo: self.view, conversation: _viewModel.conversation)
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
            let v = UIRefreshControl.init(frame: CGRect.init(x: 0, y: 0, width: 35, height: 35))
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
        v.didPhotoSelected = { [weak self] (images: [UIImage], assets: [PHAsset], isOriginPhoto: Bool) in
            guard let sself = self else { return }
            var items: [PhotoHelper.MediaTuple] = []
            for (index, asset) in assets.enumerated() {
                let item = PhotoHelper.MediaTuple.init(thumbnail: images[index], asset: asset)
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
        let v = AVPlayer.init(playerItem: nil)
        return v
    }()
    private let _disposeBag = DisposeBag()
    
    private let _viewModel: MessageListViewModel
    private var _bottomConstraint: Constraint?
    init(viewModel: MessageListViewModel) {
        _viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private weak var currentPlayingMessage: MessageInfo?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = _viewModel.conversation.showName
        view.backgroundColor = .white
        
        lazy var rightBar: UIBarButtonItem = {
            let v = UIBarButtonItem()
            v.image = UIImage.init(nameInBundle: "common_more_btn_icon")
            v.rx.tap.subscribe(onNext: { [weak self] in
                guard let sself = self else { return }
                let conversationType = sself._viewModel.conversation.conversationType
                switch conversationType {
                case .undefine:
                    break
                case .c2c:
                    let viewModel = SingleChatSettingViewModel.init(conversation: sself._viewModel.conversation)
                    let vc = SingleChatSettingTableViewController.init(viewModel: viewModel, style: .grouped)
                    self?.navigationController?.pushViewController(vc, animated: true)
                case .group:
                    let vc = GroupChatSettingTableViewController.init(conversation: sself._viewModel.conversation, style: .grouped)
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }).disposed(by: self._disposeBag)
            return v
        }()
        self.navigationItem.rightBarButtonItem = rightBar
        
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
    
    deinit {
        #if DEBUG
        print("dealloc \(type(of: self))")
        #endif
    }

    private func initView() {
        
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            _bottomConstraint = make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-ChatToolBar.defaultHeight).constraint
        }
        
        defer {
            chatBar.backgroundColor = StandardUI.color_E8F2FF
        }
    }
    
    private func bindData() {
        _viewModel.messagesRelay.asDriver(onErrorJustReturn: []).drive(_tableView.rx.items) { [weak self] (tableView, row, item: MessageInfo) in
            guard let sself = self else { return UITableViewCell() }
            let messageType = item.contentType
            let isRight = item.isSelf
            let cellType = MessageCell.getCellType(by: messageType, isRight: isRight)
            let cell = tableView.dequeueReusableCell(withIdentifier: cellType.className) as! MessageCellAble
            cell.setMessage(model: item, extraInfo: ExtraInfo.init(isC2C: sself._viewModel.conversation.conversationType == .c2c))
            cell.delegate = self
            return cell
        }.disposed(by: _disposeBag)
        
        let tapToResignFirstResponder = UITapGestureRecognizer.init()
        tapToResignFirstResponder.rx.event.subscribe(onNext: { [weak self] _ in
            self?.chatBar.textInputView.resignFirstResponder()
        }).disposed(by: _disposeBag)
        view.addGestureRecognizer(tapToResignFirstResponder)
        
        _tableView.rx.willBeginDragging.subscribe(onNext: { [weak self] in
            self?.chatBar.textInputView.resignFirstResponder()
        }).disposed(by: _disposeBag)
        
        RxKeyboard.instance.visibleHeight
          .drive(onNext: { [weak self] keyboardVisibleHeight in
              guard let sself = self else { return }
              UIView.animate(withDuration: 0) {
                  sself._tableView.contentInset.bottom = keyboardVisibleHeight
                  sself.view.layoutIfNeeded()
              }
          })
          .disposed(by: _disposeBag)

        RxKeyboard.instance.willShowVisibleHeight
          .drive(onNext: { [weak self] keyboardVisibleHeight in
            self?._tableView.contentOffset.y += keyboardVisibleHeight
          })
          .disposed(by: _disposeBag)
        
        _viewModel.scrollsToBottom.delay(.milliseconds(500), scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.scrollsToBottom()
        }).disposed(by: _disposeBag)
    }
    
    private func scrollsToBottom(animated: Bool = true) {
        let messageCount = _viewModel.messagesRelay.value.count
        if messageCount > 0 {
            let indexPath = IndexPath.init(row: messageCount - 1, section: 0)
            _tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
}

extension MessageListViewController: ChatPluginPadDelegate {
    func didSelect(plugin: PluginType) {
        switch plugin {
        case .album:
            _photoHelper.presentPhotoLibrary(byController: self)
        case .camera:
            _photoHelper.presentCamera(byController: self)
        case .businessCard:
            break
        }
    }
}

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
    func didDoubleTapMessageCell(cell: UITableViewCell, with message: MessageInfo) {
        
    }
    
    func didTapAvatar(with message: MessageInfo) {
        print("点击了\(message.senderNickname)的头像")
    }
    
    func didTapResendBtn(with message: MessageInfo) {
        _viewModel.resend(message: message)
    }
    
    func didTapQuoteView(cell: UITableViewCell, with message: MessageInfo) {
        print("点击了引用消息")
    }
    
    func didTapMessageCell(cell: UITableViewCell, with message: MessageInfo) {
        switch message.contentType {
        case .audio:
            
            if message.isPlaying {
                _audioPlayer.pause()
                _viewModel.markAudio(messageId: message.clientMsgID ?? "", isPlaying: false)
                return
            }
            var playItem: AVPlayerItem?
            if let audioUrl = message.soundElem?.sourceUrl, let url = URL.init(string: audioUrl) {
                playItem = AVPlayerItem.init(url: url)
            } else if let audioUrl = message.soundElem?.soundPath {
                let url = URL.init(fileURLWithPath: audioUrl)
                if FileManager.default.fileExists(atPath: url.path) {
                    playItem = AVPlayerItem.init(url: url)
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
        default:
            break
        }
    }
    
    func didLongPressBubbleView(bubbleView: UIView, with message: MessageInfo) {
        print("长按气泡")
        var toolItems: [ChatToolController.ToolItem] = []
        let isMyMessage = message.sendID == IMController.shared.uid
        switch message.contentType {
        case .text:
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
        let menu = ChatToolController.init(sourceView: bubbleView, items: toolItems)
        
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
                UIPasteboard.general.string = message.content
                SVProgressHUD.showSuccess(withStatus: "复制成功".innerLocalized())
            default:
                break
            }
            menu?.dismiss(animated: true)
        }).disposed(by: menu.disposeBag)
        
        self.present(menu, animated: true, completion: nil)
    }
}
