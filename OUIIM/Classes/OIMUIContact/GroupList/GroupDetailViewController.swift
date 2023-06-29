
import OUICore
import OUICoreView
import RxSwift
import RxCocoa
import ProgressHUD

class GroupDetailViewController: UIViewController {
    private let _viewModel: GroupDetailViewModel
    private let _disposeBag = DisposeBag()
    init(groupId: String) {
        _viewModel = GroupDetailViewModel(groupId: groupId)
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var tableView: UITableView = {
        let v = UITableView(frame: .zero, style: .insetGrouped)
        v.tableFooterView = UIView()
        v.dataSource = self
        v.delegate = self
        v.separatorStyle = .none
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        v.backgroundColor = .clear
        v.rowHeight = UITableView.automaticDimension
        v.register(GroupBasicInfoCell.self, forCellReuseIdentifier: GroupBasicInfoCell.className)
        v.register(GroupChatMemberTableViewCell.self, forCellReuseIdentifier: GroupChatMemberTableViewCell.className)
        v.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        
        return v
    }()
    
    lazy var enterButton: UIButton = {
        let v = UIButton(type: .system)
        v.tintColor = .white
        v.backgroundColor = .c0089FF
        v.layer.cornerRadius = 5
        
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBackgroundColor
        
        initView()
        bindData()
        tableView.reloadData()
        _viewModel.getGroupInfo()
    }
    
    private var sectionItems: [[RowType]] = [
        [.header],
        [.identifier],
    ]
    
    private func initView() {
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let bottomView = UIView()
        bottomView.backgroundColor = .systemBackground
        
        view.addSubview(bottomView)
        bottomView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(100)
        }
        
        bottomView.addSubview(enterButton)
        enterButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.top.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
    }
    
    private func bindData() {
        _viewModel.isInGroupSubject.subscribe(onNext: { [weak self] (isInGroup: Bool) in
            guard let self else { return }
            if !isInGroup {
                self.sectionItems = [
                    [.header],
                    [.identifier],
                    //                    [.joinGroup],
                ]
                self.enterButton.setTitle("申请加入群聊".innerLocalized(), for: .normal)
                self.enterButton.rx.tap.subscribe(onNext: { [weak self] _ in
                    self?.applyJoinGroup()
                }).disposed(by: self._disposeBag)
            } else {
                self.sectionItems = [
                    [.header],
                    [.identifier],
                    //                    [.enterGroupChat],
                ]
                self.enterButton.setTitle("进入群聊".innerLocalized(), for: .normal)
                self.enterButton.rx.tap.subscribe(onNext: { [weak self] _ in
                    self?.enterChat()
                }).disposed(by: self._disposeBag)
            }
            self.tableView.reloadData()
        }).disposed(by: _disposeBag)
    }
    
    private func applyJoinGroup() {
        if _viewModel.groupInfoRelay.value?.needVerification == .directly {
            _viewModel.joinCurrentGroup { [weak self] r in
                self?.enterChat()
            }
        } else {
            let vc = ApplyViewController(groupID: _viewModel.groupInfoRelay.value!.groupID)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func enterChat() {
        IMController.shared.getConversation(sessionType: .superGroup,
                                            sourceId: _viewModel.groupId) { [weak self] (conversation: ConversationInfo?) in
            guard let self, let conversation else { return }
            
            let vc = ChatViewControllerBuilder().build(conversation)
            navigationController?.pushViewController(vc, animated: true)
            if let root = navigationController?.viewControllers.first {
                navigationController?.viewControllers.removeAll(where: { controller in
                    controller != root && controller != vc
                })
            }
        }
    }
    
    enum RowType {
        case header
        case members
        case identifier
        
        var title: String {
            switch self {
            case .header:
                return ""
            case .members:
                return "群成员".innerLocalized()
            case .identifier:
                return "群聊ID号".innerLocalized()
            }
        }
    }
    
    deinit {
#if DEBUG
        print("dealloc \(type(of: self))")
#endif
    }
}

extension GroupDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        16
    }
    
    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        UIView()
    }
    
    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        nil
    }
    
    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }
    
    func numberOfSections(in _: UITableView) -> Int {
        return sectionItems.count
    }
    
    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionItems[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .header:
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupBasicInfoCell.className) as! GroupBasicInfoCell
            let groupInfo = _viewModel.groupInfoRelay.value
            cell.avatarView.setAvatar(url: groupInfo?.faceURL, text: groupInfo?.groupName)
            let count = groupInfo?.memberCount ?? 0
            cell.textFiled.text = groupInfo?.groupName
            cell.subLabel.text = Date.timeString(timeInterval: TimeInterval(groupInfo?.createTime ?? 0))
            cell.textFiled.rightViewMode = .never
            cell.QRCodeButton.isHidden = true
            
            return cell
        case .members:
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupChatMemberTableViewCell.className) as! GroupChatMemberTableViewCell
            cell.memberCollectionView.dataSource = nil
            _viewModel.membersRelay.asDriver(onErrorJustReturn: []).drive(cell.memberCollectionView.rx.items) { (collectionView: UICollectionView, row, item: GroupMemberInfo) in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupChatMemberTableViewCell.ImageCollectionViewCell.className, for: IndexPath(row: row, section: 0)) as! GroupChatMemberTableViewCell.ImageCollectionViewCell
                if item.isAddButton {
                    cell.avatarView.setAvatar(url: nil, text: nil, placeHolder: "setting_add_btn_icon")
                } else if item.isRemoveButton {
                    cell.avatarView.setAvatar(url: nil, text: nil, placeHolder: "setting_remove_btn_icon")
                } else {
                    cell.avatarView.setAvatar(url: item.faceURL, text: item.nickname)
                    cell.levelLabel.text = item.roleLevelString
                }
                
                cell.nameLabel.text = item.nickname
                
                return cell
            }.disposed(by: cell.disposeBag)
            
            cell.reloadData()
            
            _viewModel.membersCountRelay.map { "（\($0)）" }.bind(to: cell.countLabel.rx.text).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title
            
            cell.memberCollectionView.rx.modelSelected(GroupMemberInfo.self).subscribe(onNext: { [weak self] (userInfo: GroupMemberInfo) in
                guard let sself = self else { return }
                if userInfo.isAddButton || userInfo.isRemoveButton {
                    
                    let vc = SelectContactsViewController()
                    vc.title = userInfo.isAddButton ? "邀请群成员".innerLocalized() : "移除群成员".innerLocalized()
                    vc.selectedContact(blocked: userInfo.isAddButton ? sself._viewModel.allMembers + [IMController.shared.uid] : nil) { [weak vc] (r: [ContactInfo]) in
                        guard let sself = self, let groupID = sself._viewModel.groupInfoRelay.value?.groupID else { return }
                        
                        let uids = r.compactMap { $0.ID }
                        if userInfo.isAddButton {
                            IMController.shared.inviteUsersToGroup(groupId: groupID, uids: uids) {
                                vc?.navigationController?.popViewController(animated: true)
                            }
                        } else {
                            IMController.shared.kickGroupMember(groupId: groupID, uids: uids) {
                                vc?.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }).disposed(by: cell.disposeBag)
            return cell
            
        case .identifier:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.subtitleLabel.text = _viewModel.groupId
            cell.titleLabel.text = rowType.title
            return cell
        }
    }
    
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        let sessionType: ConversationType = _viewModel.groupInfoRelay.value?.groupType == .working ? .superGroup : .group;
        
        switch rowType {
        case .members:
            let vc = MemberListViewController(viewModel: MemberListViewModel(groupInfo: _viewModel.groupInfoRelay.value!))
            navigationController?.pushViewController(vc, animated: true)
        case .identifier:
            UIPasteboard.general.string = _viewModel.groupId
            ProgressHUD.showSuccess("群聊ID已复制".innerLocalized())
            
        default:
            break
        }
    }
}
