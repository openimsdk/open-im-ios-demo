
import OUICore
import OUICoreView
import ProgressHUD
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
        v.rowHeight = 68
        let refresh: UIRefreshControl = {
            let v = UIRefreshControl(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
            v.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self, weak v] in
                self?._viewModel.getAllConversations()
                self?._viewModel.getSelfInfo()
                v?.endRefreshing()
            }).disposed(by: _disposeBag)
            return v
        }()
        v.refreshControl = refresh
        v.backgroundColor = .clear
        
        return v
    }()

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    private lazy var _menuView: ChatMenuView = {
        let v = ChatMenuView()
        let scanItem = ChatMenuView.MenuItem(title: "扫一扫".innerLocalized(), icon: UIImage(nameInBundle: "chat_menu_scan_icon")) { [weak self] in
            let vc = ScanViewController()
            vc.scanDidComplete = { [weak self] (result: String) in
                if result.contains(IMController.addFriendPrefix) {
                    let uid = result.replacingOccurrences(of: IMController.addFriendPrefix, with: "")
                    let vc = UserDetailTableViewController(userId: uid, groupId: nil)
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                    self?.dismiss(animated: false)
                } else if result.contains(IMController.joinGroupPrefix) {
                    let groupID = result.replacingOccurrences(of: IMController.joinGroupPrefix, with: "")
                    let vc = GroupDetailViewController(groupId: groupID)
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                    self?.dismiss(animated: false)
                } else {
                    ProgressHUD.showError(result)
                }
            }
            vc.modalPresentationStyle = .fullScreen
            self?.present(vc, animated: true, completion: nil)
        }
        let addFriendItem = ChatMenuView.MenuItem(title: "添加好友".innerLocalized(), icon: UIImage(nameInBundle: "chat_menu_add_friend_icon")) { [weak self] in
            let vc = SearchFriendViewController()
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
            vc.didSelectedItem = { [weak self] id in
                let vc = UserDetailTableViewController(userId: id, groupId: nil)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        }

        let addGroupItem = ChatMenuView.MenuItem(title: "添加群聊".innerLocalized(), icon: UIImage(nameInBundle: "chat_menu_add_group_icon")) { [weak self] in
            let vc = SearchGroupViewController()
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
            
            vc.didSelectedItem = { [weak self] id in
                let vc = GroupDetailViewController(groupId: id)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        let createWorkGroupItem = ChatMenuView.MenuItem(title: "创建大群".innerLocalized(), icon: UIImage(nameInBundle: "chat_menu_create_work_group_icon")) { [weak self] in

            let vc = SelectContactsViewController()
            vc.selectedContact(blocked: [IMController.shared.uid]) { [weak self] (r: [ContactInfo]) in
                guard let sself = self else { return }
                let users = r.map {UserInfo(userID: $0.ID!, nickname: $0.name, faceURL: $0.faceURL)}
                let vc = NewGroupViewController(users: users, groupType: .working)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        var items = [scanItem, addFriendItem, addGroupItem, createWorkGroupItem]

        v.setItems(items)
        
        return v
    }()

    func refreshConversations() {
        _viewModel.getAllConversations()
    }
    
    private let _disposeBag = DisposeBag()
    private let _viewModel = ChatListViewModel()

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        
        initView()
        bindData()
    }

    private func initView() {
        view.addSubview(_headerView)
        _headerView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.top.equalTo(_headerView.snp.bottom).offset(16)
            make.leading.bottom.trailing.equalToSuperview()
        }
    }

    private func bindData() {
        
        IMController.shared.connectionRelay.subscribe(onNext: { [weak self] status in
            self?._headerView.updateConnectionStatus(status: status)
        })
        
        _headerView.addBtn.rx.tap.subscribe(onNext: { [weak self] in
            guard let sself = self else { return }
            if sself._menuView.superview == nil, let window = sself.view.window {
                sself._menuView.frame = window.bounds
                window.addSubview(sself._menuView)
            } else {
                sself._menuView.removeFromSuperview()
            }
        }).disposed(by: _disposeBag)

        _viewModel.conversationsRelay.asDriver(onErrorJustReturn: []).drive(_tableView.rx.items) { (tableView, _, item: ConversationInfo) in
            let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.className) as! ChatTableViewCell
            let placeholderName: String = item.conversationType == .c2c ? "contact_my_friend_icon" : "contact_my_group_icon"
            cell.avatarImageView.setAvatar(url: item.faceURL, text: item.showName, placeHolder: placeholderName)
            cell.muteImageView.isHidden = item.recvMsgOpt == .receive
            
            cell.titleLabel.text = item.showName
            cell.contentView.backgroundColor = item.isPinned ? .cF0F0F0 : .tertiarySystemBackground
            if item.recvMsgOpt != .receive, item.unreadCount > 0 {
                let unread = "[\(item.unreadCount)条]"
            }
            cell.subtitleLabel.attributedText = MessageHelper.getAbstructOf(conversation: item)
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
            
            let vc = ChatViewControllerBuilder().build(conversation)
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: _disposeBag)

        _viewModel.loginUserPublish.subscribe(onNext: { [weak self] (userInfo: UserInfo?) in
            self?._headerView.avatarImageView.setAvatar(url: userInfo?.faceURL, text: userInfo?.nickname, onTap: nil)
            self?._headerView.nameLabel.text = userInfo?.nickname
            self?._headerView.statusLabel.titleLabel.text = "手机在线".innerLocalized()
            self?._headerView.statusLabel.statusView.backgroundColor = StandardUI.color_10CC64
        }).disposed(by: _disposeBag)
    }

    public func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = _viewModel.conversationsRelay.value[indexPath.row]

        let pinActionTitle = item.isPinned ? "取消置顶".innerLocalized() : "置顶".innerLocalized()
        let setTopAction = UIContextualAction(style: .normal, title: pinActionTitle) { [weak self] _, _, completion in
            self?._viewModel.pinConversation(id: item.conversationID, isPinned: item.isPinned, onSuccess: { _ in
                completion(true)
            })
        }
        setTopAction.backgroundColor = UIColor.c0089FF
        
        let markReadTitle = "标记已读".innerLocalized()
        let markReadAction = UIContextualAction(style: .normal, title: markReadTitle) { [weak self] _, _, completion in
            self?._viewModel.markReaded(id: item.conversationID, onSuccess: { _ in
                completion(true)
            })
        }
        markReadAction.backgroundColor = UIColor.c8E9AB0

        let deleteAction = UIContextualAction(style: .destructive, title: "移除".innerLocalized()) { [weak self] _, _, completion in
            self?._viewModel.deleteConversation(conversationID: item.conversationID, completion: { _ in
                completion(true)
            })
        }

        deleteAction.backgroundColor = UIColor.cFF381F
        let configure = UISwipeActionsConfiguration(actions: [deleteAction, markReadAction, setTopAction])
        return configure
    }
}
