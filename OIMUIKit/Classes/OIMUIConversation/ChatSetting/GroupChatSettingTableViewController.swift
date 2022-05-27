





import UIKit
import RxSwift
import SVProgressHUD

class GroupChatSettingTableViewController: UITableViewController {
    private let _viewModel: GroupChatSettingViewModel
    private let _disposeBag = DisposeBag()
    init(conversation: ConversationInfo, style: UITableView.Style) {
        _viewModel = GroupChatSettingViewModel.init(conversation: conversation)
        super.init(style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "群聊设置".innerLocalized()
        self.navigationController?.navigationBar.isOpaque = false
        configureTableView()
        initView()
        _viewModel.getConversationInfo()
    }
    
    private let sectionItems: [[RowType]] = [
        [.header],
        [.members],
        [.groupName, .groupAnnounce, .myNameInGroup],
        [.qrCodeOfGroup],
        [.identifier],
        [.chatRecord, .setTopOn, .setDisturbOn, .clearRecord],
        [.complaint],
        [.quitGroup]
    ]
    
    private func configureTableView() {
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.backgroundColor = StandardUI.color_F1F1F1
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(GroupChatNameTableViewCell.self, forCellReuseIdentifier: GroupChatNameTableViewCell.className)
        tableView.register(GroupChatMemberTableViewCell.self, forCellReuseIdentifier: GroupChatMemberTableViewCell.className)
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.className)
        tableView.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        tableView.register(OptionImageTableViewCell.self, forCellReuseIdentifier: OptionImageTableViewCell.className)
        tableView.register(QuitTableViewCell.self, forCellReuseIdentifier: QuitTableViewCell.className)
    }
    
    private func initView() {
        
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 12
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionItems.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionItems[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .header:
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupChatNameTableViewCell.className) as! GroupChatNameTableViewCell
            _viewModel.groupInfoRelay.subscribe(onNext: { [weak cell] (groupInfo: GroupInfo?) in
                cell?.avatarImageView.setImage(with: groupInfo?.faceURL, placeHolder: "contact_my_group_icon")
                let count: Int = groupInfo?.memberCount ?? 0
                cell?.titleLabel.text = groupInfo?.groupName?.append(string: "(\(count))")
            }).disposed(by: cell.disposeBag)
            return cell
        case .members:
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupChatMemberTableViewCell.className) as! GroupChatMemberTableViewCell
            cell.memberCollectionView.dataSource = nil
            cell.memberCollectionView.delegate = nil
            _viewModel.membersRelay.asDriver(onErrorJustReturn: []).drive(cell.memberCollectionView.rx.items) { (collectionView: UICollectionView, row, item: UserInfo) in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupChatMemberTableViewCell.ImageCollectionViewCell.className, for: IndexPath.init(row: row, section: 0)) as! GroupChatMemberTableViewCell.ImageCollectionViewCell
                if item.isButton {
                    cell.imageView.image = UIImage.init(nameInBundle: "setting_add_btn_icon")
                } else {
                    cell.imageView.setImage(with: item.faceURL, placeHolder: "contact_my_friend_icon")
                }
                return cell
            }.disposed(by: _disposeBag)
            _viewModel.membersCountRelay.map{"\($0)人"}.bind(to: cell.countLabel.rx.text).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title
            
            cell.memberCollectionView.rx.modelSelected(UserInfo.self).subscribe(onNext: { [weak self] (userInfo: UserInfo) in
                if userInfo.isButton {
                    let vc = SelectContactsViewController()
                    vc.selectedContactsBlock = { [weak vc, weak self] (users: [UserInfo]) in
                        guard let sself = self, let groupID = sself._viewModel.groupInfoRelay.value?.groupID else { return }
                        let uids = users.compactMap{$0.userID}
                        IMController.shared.inviteUsersToGroup(groupId: groupID, uids: uids) {
                            vc?.navigationController?.popViewController(animated: true)
                        }
                    }
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }).disposed(by: cell.disposeBag)
            return cell
        case .groupName:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            _viewModel.groupInfoRelay.subscribe(onNext: { [weak cell] (groupInfo: GroupInfo?) in
                cell?.subtitleLabel.text = groupInfo?.groupName
            }).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title
            return cell
        case .groupAnnounce, .myNameInGroup, .chatRecord, .clearRecord, .complaint:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            return cell
        case .identifier:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.subtitleLabel.text = _viewModel.conversation.groupID
            cell.titleLabel.text = rowType.title
            return cell
        case .setTopOn:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.className) as! SwitchTableViewCell
            _viewModel.setTopContactRelay.bind(to: cell.switcher.rx.isOn).disposed(by: cell.disposeBag)
            cell.switcher.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self] in
                self?._viewModel.toggleTopContacts()
            }).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title
            return cell
        case .setDisturbOn:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.className) as! SwitchTableViewCell
            _viewModel.noDisturbRelay.bind(to: cell.switcher.rx.isOn).disposed(by: cell.disposeBag)
            cell.switcher.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self] in
                self?._viewModel.toggleNoDisturb()
            }).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title
            return cell
        case .qrCodeOfGroup:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionImageTableViewCell.className) as! OptionImageTableViewCell
            cell.titleLabel.text = rowType.title
            cell.iconImageView.image = UIImage.init(nameInBundle: "common_qrcode_icon")
            return cell
        case .quitGroup:
            let cell = tableView.dequeueReusableCell(withIdentifier: QuitTableViewCell.className) as! QuitTableViewCell
            _viewModel.isSelfRelay.map{ (isSelf: Bool) -> String in
                let title = isSelf ? "解散群聊".innerLocalized() : "退出群聊".innerLocalized()
                return title
            }.bind(to: cell.titleLabel.rx.text).disposed(by: cell.disposeBag)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .qrCodeOfGroup:
            let vc = QRCodeViewController.init(idString: _viewModel.conversation.groupID ?? "")
            vc.avatarImageView.setImage(with: _viewModel.conversation.faceURL, placeHolder: "contact_my_group_icon")
            vc.nameLabel.text = _viewModel.conversation.showName
            vc.tipLabel.text = "扫一扫群二维码，立刻加入该群。".innerLocalized()
            self.navigationController?.pushViewController(vc, animated: true)
        case .members:
            let vc = MemberListViewController.init(viewModel: MemberListViewModel.init(groupId: self._viewModel.conversation.groupID ?? ""))
            self.navigationController?.pushViewController(vc, animated: true)
        case .myNameInGroup:
            let vc = ModifyNicknameViewController.init()
            vc.titleLabel.text = "我在群里的昵称".innerLocalized()
            vc.subtitleLabel.text = "昵称修改后，只会在此群内显示，群内成员都可以看见".innerLocalized()
            vc.avatarImageView.setImage(with: IMController.shared.currentUserRelay.value?.faceURL, placeHolder: nil)
            vc.nameTextField.text = _viewModel.myInfoInGroup.value?.nickname
            vc.completeBtn.rx.tap.subscribe(onNext: { [weak self, weak vc] in
                guard let text = vc?.nameTextField.text, text.isEmpty == false else { return }
                self?._viewModel.updateMyNicknameInGroup(text, onSuccess: {
                    SVProgressHUD.showSuccess(withStatus: nil)
                    vc?.navigationController?.popViewController(animated: true)
                })
            }).disposed(by: vc.disposeBag)
            self.navigationController?.pushViewController(vc, animated: true)
        case .groupAnnounce:
            guard let memberInfo = _viewModel.myInfoInGroup.value, let groupInfo = _viewModel.groupInfoRelay.value else { return }
            let vc = GroupAnnounceViewController.init(memberInfo: memberInfo, groupInfo: groupInfo)
            self.navigationController?.pushViewController(vc, animated: true)
        case .chatRecord:
            let vc = SearchContainerViewController.init(conversationId: _viewModel.conversation.conversationID)
            self.navigationController?.pushViewController(vc, animated: true)
        case .identifier:
            UIPasteboard.general.string = _viewModel.conversation.groupID
            SVProgressHUD.showSuccess(withStatus: "群聊ID已复制".innerLocalized())
        case .clearRecord:
            AlertView.show(onWindowOf: self.view, alertTitle: "确认清空所有聊天记录吗？".innerLocalized(), confirmTitle: "确认".innerLocalized()) { [weak self] in
                self?._viewModel.clearRecord(completion: { _ in
                    SVProgressHUD.showSuccess(withStatus: "清空成功".innerLocalized())
                })
            }
        case .quitGroup:
            if _viewModel.isSelfRelay.value {
                AlertView.show(onWindowOf: self.view, alertTitle: "解散群聊后，将失去和群成员的联系。".innerLocalized(), confirmTitle: "确定".innerLocalized()) { [weak self] in
                    self?._viewModel.dismissGroup()
                }
            } else {
                AlertView.show(onWindowOf: self.view, alertTitle: "退出群聊后，将不再接收此群聊信息。".innerLocalized(), confirmTitle: "确定".innerLocalized()) { [weak self] in
                    self?._viewModel.quitGroup()
                }
            }
        case .groupName:
            if _viewModel.isSelfRelay.value {
                let vc = ModifyNicknameViewController.init()
                vc.titleLabel.text = "修改群聊名称".innerLocalized()
                vc.subtitleLabel.text = "修改群聊名称后，将在群内通知其他成员。".innerLocalized()
                vc.avatarImageView.setImage(with: _viewModel.groupInfoRelay.value?.faceURL, placeHolder: "contact_my_friend_icon")
                vc.nameTextField.text = _viewModel.groupInfoRelay.value?.groupName
                vc.completeBtn.rx.tap.subscribe(onNext: { [weak self, weak vc] in
                    guard let text = vc?.nameTextField.text, text.isEmpty == false else { return }
                    self?._viewModel.updateGroupName(text, onSuccess: { _ in
                        SVProgressHUD.showSuccess(withStatus: nil)
                        vc?.navigationController?.popViewController(animated: true)
                    })
                }).disposed(by: vc.disposeBag)
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                SVProgressHUD.showInfo(withStatus: "只有群主可以修改".innerLocalized())
            }
            _viewModel.groupInfoRelay.value?.creatorUserID
        default:
            break
        }
    }
    
    enum RowType {
        case header
        case members
        case groupName
        case groupAnnounce
        case myNameInGroup
        case qrCodeOfGroup
        case identifier
        case chatRecord
        case setTopOn
        case setDisturbOn
        case clearRecord
        case complaint
        case quitGroup
        
        var title: String {
            switch self {
            case .header:
                return ""
            case .members:
                return "群成员".innerLocalized()
            case .groupName:
                return "群聊名称".innerLocalized()
            case .myNameInGroup:
                return "我在群里的昵称".innerLocalized()
            case .groupAnnounce:
                return "群公告".innerLocalized()
            case .qrCodeOfGroup:
                return "群二维码".innerLocalized()
            case .identifier:
                return "群聊ID号".innerLocalized()
            case .chatRecord:
                return "查看聊天记录".innerLocalized()
            case .setTopOn:
                return "聊天置顶".innerLocalized()
            case .setDisturbOn:
                return "消息免打扰".innerLocalized()
            case .clearRecord:
                return "清空聊天记录".innerLocalized()
            case .complaint:
                return "投诉".innerLocalized()
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
