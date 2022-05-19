//






import UIKit

class GroupChatSettingTableViewController: UITableViewController {
    private let groupId: String
    init(groupId: String, style: UITableView.Style) {
        self.groupId = groupId
        super.init(style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "群聊设置"
        configureTableView()
        initView()
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
            return cell
        case .members:
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupChatMemberTableViewCell.className) as! GroupChatMemberTableViewCell
            cell.titleLabel.text = rowType.title
            return cell
        case .groupName:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            return cell
        case .groupAnnounce, .myNameInGroup, .identifier, .chatRecord, .clearRecord, .complaint:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            return cell
        case .setTopOn:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.className) as! SwitchTableViewCell
            cell.titleLabel.text = rowType.title
            return cell
        case .setDisturbOn:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.className) as! SwitchTableViewCell
            cell.titleLabel.text = rowType.title
            return cell
        case .qrCodeOfGroup:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionImageTableViewCell.className) as! OptionImageTableViewCell
            cell.titleLabel.text = rowType.title
            cell.iconImageView.image = UIImage.init(nameInBundle: "common_qrcode_icon")
            return cell
        case .quitGroup:
            let cell = tableView.dequeueReusableCell(withIdentifier: QuitTableViewCell.className) as! QuitTableViewCell
            cell.titleLabel.text = rowType.title
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .qrCodeOfGroup:
            let vc = QRCodeViewController.init(faceUrl: nil, nickName: "托云信息技术", idString: "23fdesafd32fewqfd")
            self.navigationController?.pushViewController(vc, animated: true)
        case .members:
            let vc = MemberListViewController.init(viewModel: MemberListViewModel.init(groupId: self.groupId))
            self.navigationController?.pushViewController(vc, animated: true)
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
                return "群成员"
            case .groupName:
                return "群聊名称"
            case .myNameInGroup:
                return "我在群里的昵称"
            case .groupAnnounce:
                return "群公告"
            case .qrCodeOfGroup:
                return "群二维码"
            case .identifier:
                return "群聊ID号"
            case .chatRecord:
                return "查看聊天记录"
            case .setTopOn:
                return "聊天置顶"
            case .setDisturbOn:
                return "消息免打扰"
            case .clearRecord:
                return "清空聊天记录"
            case .complaint:
                return "投诉"
            case .quitGroup:
                return "退出群聊"
            }
        }
    }
}
