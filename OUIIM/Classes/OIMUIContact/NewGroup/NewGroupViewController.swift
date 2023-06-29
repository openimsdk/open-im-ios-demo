
import OUICore
import OUICoreView
import RxSwift
import RxRelay
import ProgressHUD

class NewGroupViewController: UITableViewController {
    private let _viewModel: NewGroupViewModel
    private let _disposeBag = DisposeBag()
    
    
    init(users: [UserInfo], groupType: GroupType = .normal, style: UITableView.Style = .insetGrouped) {
        _viewModel = NewGroupViewModel(users: users, groupType: groupType)
        super.init(style: style)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private var sectionItems: [[RowType]] = [
        [.header],
        [.members],
        [.create],
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "创建群聊".innerLocalized()
        navigationController?.navigationBar.isOpaque = false
        configureTableView()
        _viewModel.getMembers()
    }
    
    private func configureTableView() {
       
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .secondarySystemBackground
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorInset = .zero
        tableView.register(GroupChatNameTableViewCell.self, forCellReuseIdentifier: GroupChatNameTableViewCell.className)
        tableView.register(GroupChatMemberTableViewCell.self, forCellReuseIdentifier: GroupChatMemberTableViewCell.className)
        tableView.register(QuitTableViewCell.self, forCellReuseIdentifier: QuitTableViewCell.className)
        tableView.tableFooterView = UIView()
    }
    
    private func toChat(conversation: ConversationInfo) {
        
        let chatVC = ChatViewControllerBuilder().build(conversation)
        chatVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(chatVC, animated: true)
        if let root = navigationController?.viewControllers.first {
            navigationController?.viewControllers.removeAll(where: { controller in
                controller != root && controller != chatVC
            })
        }
    }
    
    override func numberOfSections(in _: UITableView) -> Int {
        return sectionItems.count
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionItems[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .header:
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupChatNameTableViewCell.className) as! GroupChatNameTableViewCell
            cell.avatarImageView.setImage(with: nil, placeHolder: "contact_my_group_icon")
            cell.enableInput = true
            
            cell.nameTextFiled.rx
                .controlEvent([.editingChanged, .editingDidEnd])
                .asObservable().subscribe(onNext: {[weak self, weak cell] t in
                    self?._viewModel.groupName = cell?.nameTextFiled.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                })
                .disposed(by: _disposeBag)
            return cell
        case .members:
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupChatMemberTableViewCell.className) as! GroupChatMemberTableViewCell
            cell.memberCollectionView.dataSource = nil
            _viewModel.membersRelay.asDriver(onErrorJustReturn: []).drive(cell.memberCollectionView.rx.items) { (collectionView: UICollectionView, row, item: UserInfo) in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupChatMemberTableViewCell.ImageCollectionViewCell.className, for: IndexPath(row: row, section: 0)) as! GroupChatMemberTableViewCell.ImageCollectionViewCell
                if item.isAddButton {
                    cell.avatarView.setAvatar(url: nil, text: nil, placeHolder: "setting_add_btn_icon")
                } else if item.isRemoveButton {
                    cell.avatarView.setAvatar(url: nil, text: nil, placeHolder: "setting_remove_btn_icon")
                } else {
                    cell.avatarView.setAvatar(url: item.faceURL, text: item.nickname)
                }
                
                cell.nameLabel.text = item.nickname
                
                return cell
            }.disposed(by: _disposeBag)
            
            _viewModel.membersCountRelay.map { "\($0)人" }.bind(to: cell.countLabel.rx.text).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title

            cell.memberCollectionView.rx.modelSelected(UserInfo.self).subscribe(onNext: { [weak self] (userInfo: UserInfo) in
                guard let sself = self else { return }
                if userInfo.isAddButton || userInfo.isRemoveButton {
                    let vc = SelectContactsViewController()
                    vc.selectedContact(blocked: sself._viewModel.users.map { $0.userID }) { [weak vc] (r: [ContactInfo]) in
                        guard let sself = self else { return }
                        
                        let users = r.map{UserInfo(userID: $0.ID!, nickname: $0.name, faceURL: $0.faceURL)}
                        sself._viewModel.updateMembers(users)
                        sself.navigationController?.popViewController(animated: true)
                    }
                    sself.navigationController?.pushViewController(vc, animated: true)
                }
            }).disposed(by: cell.disposeBag)
            return cell
        case .create:
            let cell = tableView.dequeueReusableCell(withIdentifier: QuitTableViewCell.className) as! QuitTableViewCell
            cell.titleLabel.text = rowType.title

            return cell
        }
    }
    
    override func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 12
    }
    
    override func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .members:
            break
        case .create:
            
            guard let groupName = _viewModel.groupName, !groupName.isEmpty else {
                AlertView.show(onWindowOf: view, alertTitle: "输入群名", confirmTitle: "确定") {}
                return
            }
            
            ProgressHUD.show()
            _viewModel.createGroup { [weak self] conversation in
                ProgressHUD.dismiss()
                if let conversation = conversation {
                    self?.toChat(conversation: conversation)
                } else {
                    self?.presentAlert(title: "创建失败".innerLocalized())
                }
            }
            break
        default:
            break
        }
    }
    
    enum RowType {
        case header
        case members
        case create
        
        var title: String {
            switch self {
            case .header:
                return ""
            case .members:
                return "群成员".innerLocalized()
            case .create:
                return "完成创建".innerLocalized()
            }
        }
    }
    
    deinit {
#if DEBUG
        print("dealloc \(type(of: self))")
#endif
    }
}
