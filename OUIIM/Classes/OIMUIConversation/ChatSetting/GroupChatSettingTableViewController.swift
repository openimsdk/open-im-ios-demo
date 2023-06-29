
import RxSwift
import ProgressHUD
import OUICore
import OUICoreView

class GroupChatSettingTableViewController: UITableViewController {
    private let _viewModel: GroupChatSettingViewModel
    private let _disposeBag = DisposeBag()
    init(conversation: ConversationInfo, style: UITableView.Style) {
        _viewModel = GroupChatSettingViewModel(conversation: conversation)
        super.init(style: .insetGrouped)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private var sectionItems: [[RowType]]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "群聊设置".innerLocalized()

        configureTableView()
        initView()
        bindData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _viewModel.getConversationInfo()
    }
    
    private func defaultSectionItems() -> [[RowType]] {
        return [
            [.header],
            [.members],
            [.quitGroup],
        ]
    }
    
    private func configureTableView() {
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorInset = .zero
        tableView.register(GroupBasicInfoCell.self, forCellReuseIdentifier: GroupBasicInfoCell.className)
        tableView.register(GroupChatMemberTableViewCell.self, forCellReuseIdentifier: GroupChatMemberTableViewCell.className)
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.className)
        tableView.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        tableView.register(OptionImageTableViewCell.self, forCellReuseIdentifier: OptionImageTableViewCell.className)
        tableView.register(QuitTableViewCell.self, forCellReuseIdentifier: QuitTableViewCell.className)
        tableView.register(SingleChatRecordTableViewCell.self, forCellReuseIdentifier: SingleChatRecordTableViewCell.className)
    }
    
    private func initView() {}
    
    private func bindData() {
        sectionItems = defaultSectionItems()
        
        _viewModel.groupInfoRelay.subscribe(onNext: { [weak self] (groupInfo: GroupInfo?) in

            self?.tableView.reloadData()
        }).disposed(by: _disposeBag)
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        
        if rowType == .members || rowType == .header {
            return UITableView.automaticDimension
        }
        
        return 60
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
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupBasicInfoCell.className) as! GroupBasicInfoCell
            let groupInfo = _viewModel.groupInfoRelay.value
            cell.avatarView.setAvatar(url: groupInfo?.faceURL, text: groupInfo?.groupName)
            let count = groupInfo?.memberCount ?? 0
            cell.textFiled.text = groupInfo?.groupName?.append(string: "(\(count))")
            cell.subLabel.text = groupInfo?.groupID
            cell.textFiled.rightViewMode = groupInfo?.isMine == true ? .always : .never
            cell.inputHandler = { [weak self] in
                
                let vc = ModifyNicknameViewController()
                vc.titleLabel.text = "修改群聊名称".innerLocalized()
                vc.subtitleLabel.text = "修改群聊名称后，将在群内通知其他成员。".innerLocalized()
                vc.avatarView.setAvatar(url: self?._viewModel.groupInfoRelay.value?.faceURL, text: self?._viewModel.groupInfoRelay.value?.groupName)
                vc.nameTextField.text = self?._viewModel.groupInfoRelay.value?.groupName
                vc.completeBtn.rx.tap.subscribe(onNext: { [weak self, weak vc] in
                    guard let text = vc?.nameTextField.text, !text.isEmpty else { return }
                    ProgressHUD.show()
                    self?._viewModel.updateGroupName(text, onSuccess: { _ in
                        ProgressHUD.showSuccess()
                        vc?.navigationController?.popViewController(animated: true)
                    })
                }).disposed(by: vc.disposeBag)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
            
            cell.QRCodeTapHandler = { [weak self] in
                guard let self else { return }
                let vc = QRCodeViewController(idString: IMController.joinGroupPrefix.append(string: self._viewModel.conversation.groupID))
                vc.avatarView.setAvatar(url: self._viewModel.conversation.faceURL, text: self._viewModel.conversation.showName)
                vc.nameLabel.text = self._viewModel.conversation.showName
                vc.tipLabel.text = "扫一扫群二维码，立刻加入该群。".innerLocalized()
                self.navigationController?.pushViewController(vc, animated: true)
            }
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
                } else {
                    if self?._viewModel.groupInfoRelay.value?.lookMemberInfo == 0 {
                        let vc = UserDetailTableViewController(userId: userInfo.userID!, groupId: sself._viewModel.conversation.groupID, groupInfo: sself._viewModel.groupInfoRelay.value!)
                        self?.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }).disposed(by: cell.disposeBag)
            return cell
        case .quitGroup:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.titleLabel.textColor = .cFF381F
            _viewModel.myInfoInGroup.map { (info: GroupMemberInfo?) -> String in
                let title = info?.roleLevel == .owner ? "解散群聊".innerLocalized() : "退出群聊".innerLocalized()
                return title
            }.bind(to: cell.titleLabel.rx.text).disposed(by: cell.disposeBag)
            return cell
        }
    }
    
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .members:
            let vc = MemberListViewController(viewModel: MemberListViewModel(groupInfo: _viewModel.groupInfoRelay.value!))
            navigationController?.pushViewController(vc, animated: true)
        case .quitGroup:
            if let role = _viewModel.myInfoInGroup.value?.roleLevel, role == .owner {
                presentAlert(title: "解散群聊后，将失去和群成员的联系。".innerLocalized()) {
                    self._viewModel.dismissGroup(onSuccess: {
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                }
            } else {
                presentAlert(title: "退出群聊后，将不再接收此群聊信息。".innerLocalized()) {
                    self._viewModel.quitGroup(onSuccess: {
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                }
            }
        default:
            break
        }
    }
    
    enum RowType {
        case header
        case members
        case quitGroup
        
        var title: String {
            switch self {
            case .header:
                return ""
            case .members:
                return "查看全部群成员".innerLocalized()
            case .quitGroup:
                return "退出群聊".innerLocalized()
            }
        }
    }
    
    deinit {
#if DEBUG
        print("dealloc \(type(of: self))")
#endif
    }
}
