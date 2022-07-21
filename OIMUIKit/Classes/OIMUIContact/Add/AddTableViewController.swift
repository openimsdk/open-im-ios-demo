

import SVProgressHUD
import UIKit

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
        tableView.separatorColor = StandardUI.color_F1F1F1
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 71, bottom: 0, right: 22)
        tableView.register(AddEntranceTableViewCell.self, forCellReuseIdentifier: AddEntranceTableViewCell.className)
    }

    private let sectionItems: [SectionModel] = [
        SectionModel(name: "创建和加入群聊".innerLocalized(), items: [EntranceType.createGroup, EntranceType.joinGroup]),
        SectionModel(name: "添加好友".innerLocalized(), items: [EntranceType.searchUser, EntranceType.scanQrcode]),
    ]
    override open func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let item = sectionItems[section]
        let header = ViewUtil.createSectionHeaderWith(text: item.name)
        return header
    }

    override open func numberOfSections(in _: UITableView) -> Int {
        return sectionItems.count
    }

    override open func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionModel = sectionItems[section]
        return sectionModel.items.count
    }

    override open func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 37
    }

    override open func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AddEntranceTableViewCell.className) as! AddEntranceTableViewCell
        let item = sectionItems[indexPath.section].items[indexPath.row]
        cell.avatarImageView.image = item.iconImage
        cell.titleLabel.text = item.title
        cell.subtitleLabel.text = item.subtitle
        return cell
    }

    override open func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item: EntranceType = sectionItems[indexPath.section].items[indexPath.row]
        switch item {
        case .createGroup:
            let vc = SelectContactsViewController()
            vc.selectedContactsBlock = { [weak vc, weak self] (users: [UserInfo]) in
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
            navigationController?.pushViewController(vc, animated: true)
        case .joinGroup:
            let vc = SearchGroupViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .searchUser:
            let vc = SearchFriendViewController()
            navigationController?.pushViewController(vc, animated: true)
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
                    SVProgressHUD.showError(withStatus: result)
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
                return "加入群聊".innerLocalized()
            case .searchUser:
                return "搜索".innerLocalized()
            case .scanQrcode:
                return "扫一扫".innerLocalized()
            }
        }

        var subtitle: String {
            switch self {
            case .createGroup:
                return "创建群聊，全面使用OpenIM".innerLocalized()
            case .joinGroup:
                return "与成员一起沟通协作".innerLocalized()
            case .searchUser:
                return "通过用户ID号搜索添加".innerLocalized()
            case .scanQrcode:
                return "扫描二维码名片".innerLocalized()
            }
        }
    }
}
