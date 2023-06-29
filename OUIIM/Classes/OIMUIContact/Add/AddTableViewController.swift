

import OUICore
import OUICoreView
import ProgressHUD

open class AddTableViewController: UITableViewController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        navigationItem.title = "添加".innerLocalized()
    }

    private func configureTableView() {
        tableView.rowHeight = 74
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.separatorColor = .viewBackgroundColor
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 71, bottom: 0, right: 22)
        tableView.register(AddEntranceTableViewCell.self, forCellReuseIdentifier: AddEntranceTableViewCell.className)
    }
    
    func newGroup(groupType: GroupType = .normal) {
        
        let vc = SelectContactsViewController()
        vc.selectedContact() { [weak self] r in 
            guard let sself = self else { return }
            let users = r.map{UserInfo(userID: $0.ID!, nickname: $0.name, faceURL: $0.faceURL)}
            let vc = NewGroupViewController(users: users, groupType: groupType)
            sself.navigationController?.pushViewController(vc, animated: true)
        }
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private let rowTypes: [EntranceType] = [
        .scanQrcode,
        .searchUser,
        .createGroup,
        .joinGroup
    ]

    override open func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        rowTypes.count
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AddEntranceTableViewCell.className) as! AddEntranceTableViewCell
        let item = rowTypes[indexPath.row]
        cell.avatarImageView.image = item.iconImage
        cell.titleLabel.text = item.title
        cell.subtitleLabel.text = item.subtitle
        return cell
    }

    override open func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = rowTypes[indexPath.row]
        switch item {
        case .createGroup:
            newGroup(groupType: .working)
        case .joinGroup:
            let vc = SearchGroupViewController()
            navigationController?.pushViewController(vc, animated: true)
            vc.didSelectedItem = { [weak self] id in
                let vc = GroupDetailViewController(groupId: id)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        case .searchUser:
            let vc = SearchFriendViewController()
            navigationController?.pushViewController(vc, animated: true)
            vc.didSelectedItem = { [weak self] id in
                let vc = UserDetailTableViewController(userId: id, groupId: nil)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        case .scanQrcode:
            let vc = ScanViewController()
            vc.scanDidComplete = { [weak self] (result: String) in
                if result.contains(IMController.addFriendPrefix) {
                    let uid = result.replacingOccurrences(of: IMController.addFriendPrefix, with: "")
                    let vc = UserDetailTableViewController(userId: uid, groupId: nil)
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                    self?.dismiss(animated: true)
                } else if result.contains(IMController.joinGroupPrefix) {
                    let groupID = result.replacingOccurrences(of: IMController.joinGroupPrefix, with: "")
                    let vc = GroupDetailViewController(groupId: groupID)
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                    self?.dismiss(animated: true)
                } else {
                    ProgressHUD.showError(result)
                }
            }
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
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
                return UIImage(nameInBundle: "add_create_group_icon")
            case .joinGroup:
                return UIImage(nameInBundle: "add_join_group_icon")
            case .searchUser:
                return UIImage(nameInBundle: "add_search_friend_icon")
            case .scanQrcode:
                return UIImage(nameInBundle: "add_scan_icon")
            }
        }

        var title: String {
            switch self {
            case .createGroup:
                return "创建群聊".innerLocalized()
            case .joinGroup:
                return "添加群聊".innerLocalized()
            case .searchUser:
                return "添加好友".innerLocalized()
            case .scanQrcode:
                return "扫一扫".innerLocalized()
            }
        }

        var subtitle: String {
            switch self {
            case .createGroup:
                return "创建群聊，全面使用OpenIM".innerLocalized()
            case .joinGroup:
                return "向管理员或团队成员询问ID".innerLocalized()
            case .searchUser:
                return "通过手机号/ID号/搜索添加".innerLocalized()
            case .scanQrcode:
                return "扫描二维码名片".innerLocalized()
            }
        }
    }
}
