
import RxSwift
import SVProgressHUD
import UIKit

open class ChatListViewController: UIViewController, UITableViewDelegate {
    private lazy var _headerView: ChatListHeaderView = {
        let v = ChatListHeaderView()
        v.searchBar.rx.textDidBeginEditing.subscribe(onNext: {
            SVProgressHUD.showInfo(withStatus: "参考商业版本".innerLocalized())
        }).disposed(by: _disposeBag)
        v.callBtn.rx.tap.subscribe(onNext: {
            SVProgressHUD.showInfo(withStatus: "参考商业版本".innerLocalized())
        }).disposed(by: _disposeBag)
        return v
    }()

    private lazy var _tableView: UITableView = {
        let v = UITableView()
        v.register(ChatTableViewCell.self, forCellReuseIdentifier: ChatTableViewCell.className)
        v.delegate = self
        v.separatorStyle = .none
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
                    SVProgressHUD.showError(withStatus: result)
                }
            }
            vc.modalPresentationStyle = .fullScreen
            self?.present(vc, animated: true, completion: nil)
        }
        let addFriendItem = ChatMenuView.MenuItem(title: "添加好友".innerLocalized(), icon: UIImage(nameInBundle: "chat_menu_add_friend_icon")) { [weak self] in
            let vc = SearchFriendViewController()
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }

        let addGroupItem = ChatMenuView.MenuItem(title: "添加群聊".innerLocalized(), icon: UIImage(nameInBundle: "chat_menu_add_group_icon")) { [weak self] in
            let vc = SearchGroupViewController()
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        let createGroupItem = ChatMenuView.MenuItem(title: "发起群聊".innerLocalized(), icon: UIImage(nameInBundle: "chat_menu_create_group_icon")) { [weak self] in
            let vc = SelectContactsViewController()
            vc.selectedContactsBlock = { [weak vc, weak self] (users: [UserInfo]) in
                guard let sself = self else { return }
                IMController.shared.createGroupConversation(users: users) { (groupInfo: GroupInfo?) in
                    guard let groupInfo = groupInfo else { return }
                    IMController.shared.getConversation(sessionType: .group, sourceId: groupInfo.groupID) { (conversation: ConversationInfo?) in
                        guard let conversation = conversation else { return }

                        let viewModel = MessageListViewModel(groupId: groupInfo.groupID, conversation: conversation)
                        let chatVC = MessageListViewController(viewModel: viewModel)
                        chatVC.hidesBottomBarWhenPushed = true
                        self?.navigationController?.pushViewController(chatVC, animated: true)
                        if let root = self?.navigationController?.viewControllers.first {
                            self?.navigationController?.viewControllers.removeAll(where: { controller in
                                controller != root && controller != chatVC
                            })
                        }
                    }
                }
            }
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        v.setItems([scanItem, addFriendItem, addGroupItem, createGroupItem])
        return v
    }()

    private let _disposeBag = DisposeBag()
    private let _viewModel = ChatListViewModel()

    override open func viewDidLoad() {
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

        _viewModel.conversationsRelay.asDriver(onErrorJustReturn: []).drive(_tableView.rx.items) { (tableView, _, item: ConversationInfo) in
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
                viewModel = MessageListViewModel(groupId: conversation.groupID ?? "", conversation: conversation)
            case .c2c:
                viewModel = MessageListViewModel(userId: conversation.userID ?? "", conversation: conversation)
            case .undefine, .notification:
                viewModel = nil
            case .superGroup:
                SVProgressHUD.showInfo(withStatus: "大群参考商业版本".innerLocalized())
                viewModel = nil
            }
            if let viewModel = viewModel {
                let controller = MessageListViewController(viewModel: viewModel)
                controller.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(controller, animated: true)
            }
        }).disposed(by: _disposeBag)

        _viewModel.loginUserPublish.subscribe(onNext: { [weak self] (userInfo: UserInfo?) in
            self?._headerView.avatarImageView.setImage(with: userInfo?.faceURL, placeHolder: nil)
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
        setTopAction.backgroundColor = StandardUI.color_1B72EC

        let deleteAction = UIContextualAction(style: .destructive, title: "移除".innerLocalized()) { [weak self] _, _, completion in
            self?._viewModel.deleteConversationFromLocalStorage(conversationId: item.conversationID, completion: { _ in
                completion(true)
            })
        }

        deleteAction.backgroundColor = StandardUI.color_FFAB41
        let configure = UISwipeActionsConfiguration(actions: [deleteAction, setTopAction])
        return configure
    }
}
