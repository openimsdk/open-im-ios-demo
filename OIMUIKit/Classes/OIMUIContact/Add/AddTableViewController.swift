//


//




import UIKit

open class AddTableViewController: UITableViewController {

    open override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        self.navigationItem.title = "添加"
    }
    
    private func configureTableView() {
        tableView.rowHeight = 74
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.separatorColor = StandardUI.color_F1F1F1
        tableView.separatorInset = UIEdgeInsets.init(top: 0, left: 71, bottom: 0, right: 22)
        tableView.register(AddEntranceTableViewCell.self, forCellReuseIdentifier: AddEntranceTableViewCell.className)
    }
    
    private let sectionItems: [SectionModel] = [
        SectionModel.init(name: "创建和加入群聊", items: [EntranceType.createGroup, EntranceType.joinGroup]),
        SectionModel.init(name: "添加好友", items: [EntranceType.searchUser, EntranceType.scanQrcode])
    ]
    open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let item = sectionItems[section]
        let header = ViewUtil.createSectionHeaderWith(text: item.name)
        return header
    }
    
    open override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionItems.count
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionModel = sectionItems[section]
        return sectionModel.items.count
    }
    
    open override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 37
    }
    
    open override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AddEntranceTableViewCell.className) as! AddEntranceTableViewCell
        let item = sectionItems[indexPath.section].items[indexPath.row]
        cell.avatarImageView.image = item.iconImage
        cell.titleLabel.text = item.title
        cell.subtitleLabel.text = item.subtitle
        return cell
    }
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item: EntranceType = sectionItems[indexPath.section].items[indexPath.row]
        switch item {
        case .createGroup:
            let vc = SelectContactsViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        case .joinGroup:
            let vc = SearchGroupViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        case .searchUser:
            let vc = SearchFriendViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        case .scanQrcode:
            let vc = ScanViewController()
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }
    }
    
    struct SectionModel {
        let name: String
        let items: [EntranceType]
    }
    
    enum EntranceType {
        case createGroup
        case joinGroup
        case searchUser
        case scanQrcode
        
        var iconImage: UIImage? {
            switch self {
            case .createGroup:
                return UIImage.init(nameInBundle: "add_create_group_icon")
            case .joinGroup:
                return UIImage.init(nameInBundle: "add_join_group_icon")
            case .searchUser:
                return UIImage.init(nameInBundle: "add_search_friend_icon")
            case .scanQrcode:
                return UIImage.init(nameInBundle: "add_scan_icon")
            }
        }
        
        var title: String {
            switch self {
            case .createGroup:
                return "创建群聊"
            case .joinGroup:
                return "加入群聊"
            case .searchUser:
                return "搜索"
            case .scanQrcode:
                return "扫一扫"
            }
        }
        
        var subtitle: String {
            switch self {
            case .createGroup:
                return "创建群聊，全面使用OpenIM"
            case .joinGroup:
                return "与成员一起沟通协作"
            case .searchUser:
                return "通过用户ID号搜索添加"
            case .scanQrcode:
                return "扫描二维码名片"
            }
        }
    }
}
