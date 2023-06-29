
import RxSwift
import OUICore

public class ContactsViewController: UITableViewController {
    public lazy var viewModel = ContactsViewModel()
    private let _disposeBag = DisposeBag()

    private lazy var newFriendCell: ContactsEntranceTableViewCell = {
        let v = getEntranceCell()
        let value = EntranceCellType.newFriend
        v.avatarImageView.image = value.iconImage
        v.titleLabel.text = value.title
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            let vc = NewFriendListViewController()
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: _disposeBag)
        v.addGestureRecognizer(tap)
        return v
    }()

    private lazy var groupNotiCell: ContactsEntranceTableViewCell = {
        let v = getEntranceCell()
        let value = EntranceCellType.groupNotification
        v.avatarImageView.image = value.iconImage
        v.titleLabel.text = value.title
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            let vc = GroupApplicationTableViewController()
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: _disposeBag)
        v.addGestureRecognizer(tap)
        return v
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        initView()
        bindData()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    private func initView() {
        let titleLabel: UILabel = {
            let v = UILabel()
            v.font = .f20
            v.textColor = .c0C1C33
            v.text = "通讯录".innerLocalized()
            return v
        }()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)

        let addItem: UIBarButtonItem = {
            let v = UIBarButtonItem()
            v.image = UIImage(nameInBundle: "contact_add_icon")
            v.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)
            v.rx.tap.subscribe(onNext: { [weak self] in
                let vc = AddTableViewController()
                vc.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(vc, animated: true)
            }).disposed(by: _disposeBag)
            return v
        }()
        
        navigationItem.rightBarButtonItems = [addItem]

        let vStack: UIStackView = {
            let rowHeight = 60
            let myFriendCell: ContactsEntranceTableViewCell = {
                let v = getEntranceCell()
                let value = EntranceCellType.myFriend
                v.avatarImageView.image = value.iconImage
                v.titleLabel.text = value.title
                v.badgeLabel.isHidden = true
                let tap = UITapGestureRecognizer()
                tap.rx.event.subscribe(onNext: { [weak self] _ in
                    let vc = FriendListViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                }).disposed(by: _disposeBag)
                v.addGestureRecognizer(tap)
                return v
            }()
            let myGroupCell: ContactsEntranceTableViewCell = {
                let v = getEntranceCell()
                let value = EntranceCellType.myGroup
                v.avatarImageView.image = value.iconImage
                v.titleLabel.text = value.title
                v.badgeLabel.isHidden = true
                let tap = UITapGestureRecognizer()
                tap.rx.event.subscribe(onNext: { [weak self] _ in
                    let vc = GroupListViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                }).disposed(by: _disposeBag)
                v.addGestureRecognizer(tap)
                return v
            }()
            
            let spacer = UIView()
            spacer.backgroundColor = .clear
            
            let arrangedViews: [UIView] = [newFriendCell, groupNotiCell, spacer, myFriendCell, myGroupCell]
            let v = UIStackView(arrangedSubviews: arrangedViews)
            v.axis = .vertical
            
            newFriendCell.snp.makeConstraints { make in
                make.height.equalTo(rowHeight)
            }
            groupNotiCell.snp.makeConstraints { make in
                make.height.equalTo(rowHeight)
            }
            myFriendCell.snp.makeConstraints { make in
                make.height.equalTo(rowHeight)
            }
            myGroupCell.snp.makeConstraints { make in
                make.height.equalTo(rowHeight)
            }
            spacer.snp.makeConstraints { make in
                make.height.equalTo(16)
            }
            
            v.bounds = CGRect(x: 0, y: 0, width: Int(kScreenWidth), height: rowHeight * 4 + 16)
            
            return v
        }()

        tableView.tableHeaderView = vStack
    }

    private func bindData() {
        viewModel.newFriendCountRelay.map { $0 == 0 }.bind(to: newFriendCell.badgeLabel.rx.isHidden).disposed(by: _disposeBag)
        viewModel.newGroupCountRelay.map { $0 == 0 }.bind(to: groupNotiCell.badgeLabel.rx.isHidden).disposed(by: _disposeBag)
        viewModel.newFriendCountRelay.map { "\($0)" }.bind(to: newFriendCell.badgeLabel.rx.text).disposed(by: _disposeBag)
        viewModel.newGroupCountRelay.map { "\($0)" }.bind(to: groupNotiCell.badgeLabel.rx.text).disposed(by: _disposeBag)
        viewModel.frequentContacts.asDriver().drive { [weak self] _ in
            self?.tableView.reloadData()
        }.disposed(by: _disposeBag)
        viewModel.companyDepartments.asDriver().drive { [weak self] _ in
            self?.tableView.reloadData()
        }.disposed(by: _disposeBag)
        viewModel.getFriendApplications()
        viewModel.getGroupApplications()
    }

    private func configureTableView() {
        tableView.backgroundColor = .systemGroupedBackground
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
        tableView.register(ContactsEntranceTableViewCell.self, forCellReuseIdentifier: ContactsEntranceTableViewCell.className)
        tableView.register(FrequentUserTableViewCell.self, forCellReuseIdentifier: FrequentUserTableViewCell.className)
    }

    private func getEntranceCell() -> ContactsEntranceTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactsEntranceTableViewCell.className) as! ContactsEntranceTableViewCell
        return cell
    }

    enum EntranceCellType: CaseIterable {
        case newFriend
        case groupNotification
        case myFriend
        case myGroup

        var iconImage: UIImage? {
            switch self {
            case .newFriend:
                return UIImage(nameInBundle: "contact_new_friend_icon")
            case .groupNotification:
                return UIImage(nameInBundle: "contact_new_group_icon")
            case .myFriend:
                return UIImage(nameInBundle: "contact_my_friend_icon")
            case .myGroup:
                return UIImage(nameInBundle: "contact_my_group_icon")
            }
        }

        var title: String {
            switch self {
            case .newFriend:
                return "新的好友".innerLocalized()
            case .groupNotification:
                return "群通知".innerLocalized()
            case .myFriend:
                return "我的好友".innerLocalized()
            case .myGroup:
                return "我的群组".innerLocalized()
            }
        }
    }
}
