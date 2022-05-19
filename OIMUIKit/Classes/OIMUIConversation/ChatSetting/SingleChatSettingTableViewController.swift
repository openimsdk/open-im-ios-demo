//






import UIKit
import RxDataSources

class SingleChatSettingTableViewController: UITableViewController {
    
    private let _viewModel: SingleChatSettingViewModel
    
    init(viewModel: SingleChatSettingViewModel, style: UITableView.Style) {
        _viewModel = viewModel
        super.init(style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "聊天设置"
        configureTableView()
        initView()
        _viewModel.getConversationInfo()
    }
    
    private let sectionItems: [[RowType]] = [
        [.members],
        [.chatRecord],
        [.setTopOn, .setDisturbOn],
        [.complaint],
        [.clearRecord]
    ]
    
    private func configureTableView() {
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.backgroundColor = StandardUI.color_F1F1F1
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(SingleChatMemberTableViewCell.self, forCellReuseIdentifier: SingleChatMemberTableViewCell.className)
        tableView.register(SingleChatRecordTableViewCell.self, forCellReuseIdentifier: SingleChatRecordTableViewCell.className)
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.className)
        tableView.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
    }
    
    private func initView() {
        
    }
    
    enum RowType: CaseIterable {
        case members
        case chatRecord
        case setTopOn
        case setDisturbOn
        case complaint
        case clearRecord
        
        var title: String {
            switch self {
            case .members:
                return ""
            case .chatRecord:
                return "查找聊天记录"
            case .setTopOn:
                return "置顶联系人"
            case .setDisturbOn:
                return "消息免打扰"
            case .complaint:
                return "投诉"
            case .clearRecord:
                return "清空聊天记录"
            }
        }
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
        case .members:
            let cell = tableView.dequeueReusableCell(withIdentifier: SingleChatMemberTableViewCell.className) as! SingleChatMemberTableViewCell
            _viewModel.membesRelay.asDriver(onErrorJustReturn: []).drive(cell.memberCollectionView.rx.items) { (collectionView, row, item: UserInfo) in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SingleChatMemberTableViewCell.MemberCell.className, for: IndexPath.init(row: row, section: 0)) as! SingleChatMemberTableViewCell.MemberCell
                cell.avatarImageView.setImage(with: item.faceURL, placeHolder: "contact_my_friend_icon")
                cell.nameLabel.text = item.nickname
                return cell
            }.disposed(by: cell.disposeBag)
            return cell
        case .chatRecord:
            let cell = tableView.dequeueReusableCell(withIdentifier: SingleChatRecordTableViewCell.className) as! SingleChatRecordTableViewCell
            cell.titleLabel.text = rowType.title
            return cell
        case .setTopOn:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.className) as! SwitchTableViewCell
            _viewModel.setTopContactRelay.bind(to: cell.switcher.rx.isOn).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title
            return cell
        case .setDisturbOn:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.className) as! SwitchTableViewCell
            _viewModel.noDisturbRelay.bind(to: cell.switcher.rx.isOn).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title
            return cell
        case .complaint:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            return cell
        case .clearRecord:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType: RowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .complaint:
            print("跳转投诉页面")
        case .clearRecord:
            print("执行清空聊天记录")
        default:
            break
        }
    }
}
