
import RxDataSources
import RxSwift
import SVProgressHUD
import UIKit

class GroupDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
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
        let v = UITableView()
        v.tableFooterView = UIView()
        v.dataSource = self
        v.delegate = self
        v.separatorStyle = .none
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        v.backgroundColor = StandardUI.color_F1F1F1
        v.rowHeight = UITableView.automaticDimension
        v.register(GroupChatNameTableViewCell.self, forCellReuseIdentifier: GroupChatNameTableViewCell.className)
        v.register(GroupChatMemberTableViewCell.self, forCellReuseIdentifier: GroupChatMemberTableViewCell.className)
        v.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        v.register(QuitTableViewCell.self, forCellReuseIdentifier: QuitTableViewCell.className)
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
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
    }

    private func bindData() {
        _viewModel.isInGroupSubject.subscribe(onNext: { [weak self] (isInGroup: Bool) in
            if !isInGroup {
                self?.sectionItems = [
                    [.header],
                    [.identifier],
                    [.joinGroup],
                ]
            } else {
                self?.sectionItems = [
                    [.header],
                    [.identifier],
                    [.enterGroupChat],
                ]
            }
            self?.tableView.reloadData()
        }).disposed(by: _disposeBag)
    }

    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let rowType = sectionItems[section].first {
            if rowType == .joinGroup {
                return 100
            }
        }
        return 12
    }

    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        return UIView()
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        return UIView()
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
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
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupChatMemberTableViewCell.ImageCollectionViewCell.className, for: IndexPath(row: row, section: 0)) as! GroupChatMemberTableViewCell.ImageCollectionViewCell
                if item.isButton {
                    cell.imageView.image = UIImage(nameInBundle: "setting_add_btn_icon")
                } else {
                    cell.imageView.setImage(with: item.faceURL, placeHolder: "contact_my_friend_icon")
                }
                return cell
            }.disposed(by: _disposeBag)
            _viewModel.membersCountRelay.map { "\($0)人" }.bind(to: cell.countLabel.rx.text).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title

            cell.memberCollectionView.rx.modelSelected(UserInfo.self).subscribe(onNext: { [weak self] (userInfo: UserInfo) in
                guard let sself = self else { return }
                if userInfo.isButton {
                    let vc = SelectContactsViewController()
                    vc.blockedUsers = sself._viewModel.allMembers
                    vc.selectedContactsBlock = { [weak vc, weak self] (users: [UserInfo]) in
                        guard let sself = self, let groupID = sself._viewModel.groupInfoRelay.value?.groupID else { return }
                        let uids = users.compactMap { $0.userID }
                        IMController.shared.inviteUsersToGroup(groupId: groupID, uids: uids) {
                            vc?.navigationController?.popViewController(animated: true)
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
        case .joinGroup:
            let cell = tableView.dequeueReusableCell(withIdentifier: QuitTableViewCell.className) as! QuitTableViewCell
            cell.titleLabel.textColor = StandardUI.color_1D6BED
            cell.titleLabel.text = rowType.title
            return cell
        case .enterGroupChat:
            let cell = tableView.dequeueReusableCell(withIdentifier: QuitTableViewCell.className) as! QuitTableViewCell
            cell.titleLabel.textColor = StandardUI.color_1B72EC
            cell.titleLabel.text = rowType.title
            return cell
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .members:
            let vc = MemberListViewController(viewModel: MemberListViewModel(groupId: _viewModel.groupId ?? ""))
            navigationController?.pushViewController(vc, animated: true)
        case .identifier:
            UIPasteboard.general.string = _viewModel.groupId
            SVProgressHUD.showSuccess(withStatus: "群聊ID已复制".innerLocalized())
        case .joinGroup:
            _viewModel.joinCurrentGroup { [weak self] _ in
                SVProgressHUD.showSuccess(withStatus: "加群申请已发送".innerLocalized())
            }
        case .enterGroupChat:
            IMController.shared.getConversation(sessionType: .group, sourceId: _viewModel.groupId) { [weak self] (conversation: ConversationInfo?) in
                guard let sself = self else { return }
                guard let conversation = conversation else {
                    return
                }

                let model = MessageListViewModel(groupId: sself._viewModel.groupId, conversation: conversation)
                let vc = MessageListViewController(viewModel: model)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        default:
            break
        }
    }

    enum RowType {
        case header
        case members
        case identifier
        case joinGroup
        case enterGroupChat

        var title: String {
            switch self {
            case .header:
                return ""
            case .members:
                return "群成员".innerLocalized()
            case .identifier:
                return "群聊ID号".innerLocalized()
            case .joinGroup:
                return "申请加入群聊".innerLocalized()
            case .enterGroupChat:
                return "进入群聊".innerLocalized()
            }
        }
    }

    deinit {
        #if DEBUG
            print("dealloc \(type(of: self))")
        #endif
    }
}
