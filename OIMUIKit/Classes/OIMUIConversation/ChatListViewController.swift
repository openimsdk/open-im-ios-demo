//






import UIKit
import RxSwift

open class ChatListViewController: UIViewController, UITableViewDelegate {
    
    private lazy var _headerView: ChatListHeaderView = {
        let v = ChatListHeaderView()
        return v
    }()
    
    private lazy var _tableView: UITableView = {
        let v = UITableView()
        v.register(ChatTableViewCell.self, forCellReuseIdentifier: ChatTableViewCell.className)
        v.delegate = self
        v.separatorStyle = .none
        let refresh: UIRefreshControl = {
            let v = UIRefreshControl.init(frame: CGRect.init(x: 0, y: 0, width: 35, height: 35))
            v.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self, weak v] in
                self?._viewModel.getAllConversations()
                self?._viewModel.getSelfInfo()
                v?.endRefreshing()
            }).disposed(by: _disposeBag)
            return v
        }()
        v.refreshControl = refresh
        return v
    }()
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private lazy var _menuView: ChatMenuView = {
        let v = ChatMenuView()
        let scanItem: ChatMenuView.MenuItem = ChatMenuView.MenuItem.init(title: "扫一扫", icon: UIImage.init(nameInBundle: "chat_menu_scan_icon")) { [weak self] in
            let vc = ScanViewController()
            vc.modalPresentationStyle = .fullScreen
            self?.present(vc, animated: true, completion: nil)
        }
        let addFriendItem = ChatMenuView.MenuItem.init(title: "添加好友", icon: UIImage.init(nameInBundle: "chat_menu_add_friend_icon")) {
            print("跳转添加好友界面")
        }
        
        let addGroupItem = ChatMenuView.MenuItem.init(title: "添加群聊", icon: UIImage.init(nameInBundle: "chat_menu_add_group_icon")) {
            print("跳转添加群聊页面")
        }
        let createGroupItem = ChatMenuView.MenuItem.init(title: "发起群聊", icon: UIImage.init(nameInBundle: "chat_menu_create_group_icon")) {
            print("跳转到发起群聊界面")
            let vc = SelectContactsViewController()
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
        v.setItems([scanItem, addFriendItem, addGroupItem, createGroupItem])
        return v
    }()
    
    private let _disposeBag = DisposeBag()
    private let _viewModel = ChatListViewModel()

    open override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        bindData()
    }
    
    private func initView() {
        view.addSubview(_headerView)
        _headerView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(75 + 44 + kStatusBarHeight)
        }
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.top.equalTo(_headerView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    private func bindData() {
        _headerView.addBtn.rx.tap.subscribe(onNext: { [weak self] in
            guard let sself = self else { return }
            if sself._menuView.superview == nil, let window = sself.view.window {
                sself._menuView.frame = window.bounds
                window.addSubview(sself._menuView)
            } else {
                sself._menuView.removeFromSuperview()
            }
        }).disposed(by: _disposeBag)
        
        _viewModel.conversationsRelay.asDriver(onErrorJustReturn: []).drive(_tableView.rx.items) { (tableView, row, item: ConversationInfo) in
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.className) as! ChatTableViewCell
            let placeholderName: String = item.conversationType == .c2c ? "contact_my_friend_icon" : "contact_my_group_icon"
            cell.avatarImageView.setImage(with: item.faceURL, placeHolder: placeholderName)
            cell.muteImageView.isHidden = item.recvMsgOpt == .receive
            cell.titleLabel.text = item.showName
            cell.contentView.backgroundColor = item.isPinned ? StandardUI.color_F0F0F0 : UIColor.white
            if item.recvMsgOpt != .receive, item.unreadCount > 0 {
                let unread = "[\(item.unreadCount)条]"
            }
            cell.subtitleLabel.attributedText = MessageHelper.getAbstructOf(message: item.latestMsg, isSingleChat: item.conversationType == .c2c, unreadCount: item.unreadCount, status: item.recvMsgOpt)
            var unreadShouldHide: Bool = false
            if item.recvMsgOpt != .receive {
                unreadShouldHide = true
            }
            if item.unreadCount <= 0 {
                unreadShouldHide = true
            }
            cell.unreadLabel.isHidden = unreadShouldHide
            cell.unreadLabel.text = "\(item.unreadCount)"
            cell.muteImageView.isHidden = item.recvMsgOpt == .receive
            cell.timeLabel.text = MessageHelper.convertList(timestamp_ms: item.latestMsgSendTime)
            return cell
        }.disposed(by: _disposeBag)
        
        _tableView.rx.modelSelected(ConversationInfo.self).subscribe(onNext: { [weak self] (conversation: ConversationInfo) in
            let viewModel: MessageListViewModel?
            switch conversation.conversationType {
            case .group:
                viewModel = MessageListViewModel.init(groupId: conversation.groupID ?? "", conversation: conversation)
            case .c2c:
                viewModel = MessageListViewModel.init(userId: conversation.userID ?? "", conversation: conversation)
            case .undefine:
                viewModel = nil
            }
            if let viewModel = viewModel {
                let controller = MessageListViewController.init(viewModel: viewModel)
                controller.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(controller, animated: true)
            }
        }).disposed(by: _disposeBag)
        
        _viewModel.loginUserPublish.subscribe(onNext: { [weak self] (userInfo: UserInfo?) in
            self?._headerView.avatarImageView.setImage(with: userInfo?.faceURL, placeHolder: nil)
            self?._headerView.nameLabel.text = userInfo?.nickname
            self?._headerView.statusLabel.titleLabel.text = "手机在线"
            self?._headerView.statusLabel.statusView.backgroundColor = StandardUI.color_10CC64
        }).disposed(by: _disposeBag)
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = _viewModel.conversationsRelay.value[indexPath.row]
        
        let pinActionTitle = item.isPinned ? "取消置顶" : "置顶"
        let setTopAction: UIContextualAction = UIContextualAction.init(style: .normal, title: pinActionTitle) { [weak self] action, actionView, completion in
            self?._viewModel.pinConversation(id: item.conversationID, isPinned: item.isPinned, onSuccess: { _ in
                completion(true)
            })
        }
        setTopAction.backgroundColor = StandardUI.color_1B72EC
        
        let deleteAction: UIContextualAction = UIContextualAction.init(style: .destructive, title: "移除") { [weak self] action, actionView, completion in
            self?._viewModel.deleteConversationFromLocalStorage(conversationId: item.conversationID, completion: { _ in
                completion(true)
            })
        }
        
        deleteAction.backgroundColor = StandardUI.color_FFAB41
        let configure = UISwipeActionsConfiguration.init(actions: [deleteAction, setTopAction])
        return configure
    }
}
