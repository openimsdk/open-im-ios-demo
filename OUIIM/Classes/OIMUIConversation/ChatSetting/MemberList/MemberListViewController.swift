
import RxSwift
import OUICore
import OUICoreView
import MJRefresh

class MemberListViewController: UIViewController {
    private lazy var _tableView: UITableView = {
        let v = UITableView()
        let config: SCIndexViewConfiguration = {
            let v = SCIndexViewConfiguration(indexViewStyle: SCIndexViewStyle.default)!
            v.indexItemRightMargin = 8
            v.indexItemTextColor = UIColor(hexString: "#555555")
            v.indexItemSelectedBackgroundColor = UIColor(hexString: "#57be6a")
            v.indexItemsSpace = 4
            v.indicatorCenterYOffset = 60
            return v
        }()
        v.sc_indexViewConfiguration = config
        v.sc_translucentForTableViewInNavigationBar = true
        v.register(FriendListUserTableViewCell.self, forCellReuseIdentifier: FriendListUserTableViewCell.className)
        v.dataSource = self
        v.delegate = self
        v.rowHeight = UITableView.automaticDimension
        v.separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: StandardUI.margin_22)
        v.separatorColor = StandardUI.color_F1F1F1
        v.tableFooterView = UIView()
        
        let footer = MJRefreshAutoNormalFooter.init { [weak self, weak v] in
            guard let sself = self else { return }
            self?._viewModel.targetUserId = sself._viewModel.contactSections.last?.last?.userID
            self?._viewModel.getMoreMembers(completion: { (isNoMore: Bool) in
                if isNoMore {
                    v?.mj_footer?.endRefreshingWithNoMoreData()
                } else {
                    v?.mj_footer?.endRefreshing()
                }
            })
        }
        footer.setTitle("正在加载联系人", for: .refreshing)
        footer.setTitle("联系人已全部加载", for: .noMoreData)
        v.mj_footer = footer
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        
        return v
    }()
    
    lazy var headerTableView: UITableView = {
        let v = UITableView()
        v.register(FriendListUserTableViewCell.self, forCellReuseIdentifier: FriendListUserTableViewCell.className)
        v.separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: StandardUI.margin_22)
        v.separatorColor = .cF1F1F1
//        v.rowHeight = UITableView.automaticDimension
//        v.estimatedRowHeight = 44.0
        v.rowHeight = 72
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        v.tableFooterView = UIView()
        
        return v
    }()
    
    lazy var header: UIView = {
        let v = UIView()
        
        return v
    }()

    private let _viewModel: MemberListViewModel
    private let _disposeBag = DisposeBag()
    private lazy var resultC: FriendListResultViewController = {
        let v = FriendListResultViewController()
        v.selectUserCallBack = { [weak self] (userID: String) in
            let vc = UserDetailTableViewController.init(userId: userID, groupId: self?._viewModel.groupInfo.groupID)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        v.didScrollCallback = { [weak self] in
            guard let sself = self else { return }
            if sself.navigationItem.searchController?.searchBar.isFirstResponder == true {
                sself.navigationItem.searchController?.searchBar.resignFirstResponder()
            }
        }
        return v
    }()
    
    private lazy var _menuView: ChatMenuView = {
        let v = ChatMenuView()
        
        return v
    }()
    
    private lazy var addItem: ChatMenuView.MenuItem = {
        let v = ChatMenuView.MenuItem(title: "邀请成员".innerLocalized(), icon: UIImage(nameInBundle: "chat_menu_add_friend_icon")) { [weak self] in
            guard let sself = self else { return }
            
            let vc = SelectContactsViewController()
            vc.selectedContact(blocked: sself._viewModel.members.map { $0.userID! }) { [weak vc] (users: [ContactInfo]) in
                guard let groupID: String = self?._viewModel.groupInfo.groupID else { return }
                
                let uids = users.compactMap { $0.ID }
                IMController.shared.inviteUsersToGroup(groupId: groupID, uids: uids) {
                    self?._viewModel.resetMembersArray()
                    vc?.navigationController?.popViewController(animated: true)
                }
            }
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        
        return v
    }()
    
    private lazy var deleteItem: ChatMenuView.MenuItem = {
        let v = ChatMenuView.MenuItem(title: "移除成员".innerLocalized(), icon: UIImage(nameInBundle: "chat_menu_create_work_group_icon")) { [weak self] in
            guard let sself = self else { return }
            
            let vc = SelectContactsViewController(types: [.members], sourceID: sself._viewModel.groupInfo.groupID)
            let owner = sself._viewModel.ownerAndAdminRelay.value.first(where: { [weak self] m in
                return m.roleLevel == .owner
            })?.userID
            
            vc.selectedContact(blocked: owner != nil ? [owner!] : []) { [weak vc] (users: [ContactInfo]) in
                guard let groupID: String = self?._viewModel.groupInfo.groupID else { return }
                
                let uids = users.compactMap { $0.ID }
                IMController.shared.kickGroupMember(groupId: groupID, uids: uids) {
                    self?._viewModel.resetMembersArray()
                    vc?.navigationController?.popViewController(animated: true)
                }
            }
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        
        return v
    }()

    init(viewModel: MemberListViewModel) {
        _viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = false
        _tableView.mj_footer?.beginRefreshing()
        _viewModel.getOwnerAndAdmin()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "群成员".innerLocalized()
        initView()
        bindData()
    }

    private func initView() {
        let searchC: UISearchController = {
            let v = UISearchController(searchResultsController: resultC)
            v.searchResultsUpdater = resultC
            v.searchBar.placeholder = "搜索成员".innerLocalized()
            v.obscuresBackgroundDuringPresentation = false
            return v
        }()
        navigationItem.searchController = searchC

        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        _tableView.tableHeaderView = headerTableView
        _menuView.setItems([addItem])
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .init(nameInBundle: "common_more_btn_icon"), style: .done, target: self, action: #selector(tapMore))
    }
    
    @objc func tapMore() {
        if self._menuView.superview == nil, let window = self.view.window {
            self._menuView.frame = window.bounds
            window.addSubview(self._menuView)
        } else {
            self._menuView.removeFromSuperview()
        }
    }

    private func bindData() {
        
        _viewModel.ownerAndAdminRelay.subscribe(onNext: { [weak self] infos in
            guard let sself = self else { return }
            var headerFrame = sself.headerTableView.frame
            
            headerFrame.size.height = CGFloat(infos.count * 72)
            sself.headerTableView.frame = headerFrame
            sself._tableView.tableHeaderView = sself.headerTableView
//            这个功能还需等待
            if infos.contains(where: { member in
                return member.userID == IMController.shared.uid;
            }) {
                sself._menuView.setItems([sself.addItem, sself.deleteItem])
            } else {
                sself._menuView.setItems([sself.addItem])
            }
        })
        
        _viewModel.ownerAndAdminRelay.bind(to: headerTableView.rx.items(cellIdentifier: FriendListUserTableViewCell.className,
                                                                        cellType: FriendListUserTableViewCell.self)) {[weak self] _, model, cell in
            
            // 展示创建者 和 管理员
            if model.isOwnerOrAdmin {
                let width = 12 * model.roleLevelString.length
                let textLabel = UILabel()
                textLabel.frame = .init(x: 0, y: 0, width: width * 2, height: 16 * 2)
                textLabel.text = model.roleLevelString
                textLabel.font = .boldSystemFont(ofSize: 14)
                textLabel.textColor = model.roleLevel == .owner ? UIColor.init(hex: 0xFDDFA1) : UIColor.init(hex: 0xA2C9F8)
                textLabel.backgroundColor = model.roleLevel == .owner ? UIColor.init(hex: 0xFF8C00) : UIColor.init(hex: 0x2691ED)
                textLabel.clipsToBounds = true
                textLabel.layer.cornerRadius = 16
                textLabel.textAlignment = .center
                
                let image = self?.imageWithUIView(view: textLabel)
                //创建Image的富文本格式
                var attach = NSTextAttachment()
                attach.bounds = .init(x: 0, y: -3, width: width, height: 16)
                attach.image = image;
                
                let imageStr =  NSAttributedString.init(attachment: attach)
                var titleString = NSMutableAttributedString.init(string: "\(model.nickname!)  ")
                titleString.append(imageStr)
                
                cell.titleLabel.attributedText = titleString
            } else {
                cell.titleLabel.text = model.nickname
            }
            cell.avatarImageView.setAvatar(url: model.faceURL, text: model.nickname, onTap: nil)
        }.disposed(by: _disposeBag)
        
        headerTableView.rx.modelSelected(GroupMemberInfo.self).subscribe(onNext: { [weak self] member in
            
            guard let `self` = self, self._viewModel.groupInfo.lookMemberInfo == 1 else { return }
            
            let vc = UserDetailTableViewController(userId: member.userID ?? "", groupId: member.groupID)
            self.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: _disposeBag)

        
        _viewModel.lettersRelay.subscribe(onNext: { [weak self] (values: [String]) in
            guard let sself = self else { return }
            self?.resultC.dataList = sself._viewModel.members.compactMap {
                let item = UserInfo(userID: $0.userID!, nickname: $0.nickname, faceURL: $0.faceURL)

                return item
            }
            self?._tableView.sc_indexViewDataSource = values
            self?._tableView.sc_refreshCurrentSectionOfIndexView()
            self?._tableView.reloadData()
        }).disposed(by: _disposeBag)
        
        _viewModel.targetIndexRelay.subscribe(onNext: { [weak self] (index: IndexPath?) in
            guard let indexPath = index else { return }
            self?._tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.none, animated: false)
            self?._tableView.sc_refreshCurrentSectionOfIndexView()
        }).disposed(by: _disposeBag)
    }
    
    private func imageWithUIView(view: UIView) -> UIImage {
        UIGraphicsBeginImageContext(view.bounds.size)
        let ctx = UIGraphicsGetCurrentContext()
        view.layer.render(in: ctx!)
        let tImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return tImage!;
    }
    

    deinit {
        print("dealloc \(type(of: self))")
    }
}

extension MemberListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in _: UITableView) -> Int {
        return _viewModel.lettersRelay.value.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _viewModel.contactSections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FriendListUserTableViewCell.className) as! FriendListUserTableViewCell
        let user: GroupMemberInfo = _viewModel.contactSections[indexPath.section][indexPath.row]
        cell.titleLabel.text = user.nickname
        cell.avatarImageView.setAvatar(url: user.faceURL, text: user.nickname, onTap: nil)
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard self._viewModel.groupInfo.lookMemberInfo == 0 else { return }
        let member: GroupMemberInfo = _viewModel.contactSections[indexPath.section][indexPath.row]
        let vc = UserDetailTableViewController(userId: member.userID ?? "", groupId: member.groupID, groupInfo: self._viewModel.groupInfo)
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let name = _viewModel.lettersRelay.value[section]
        let header = ViewUtil.createSectionHeaderWith(text: name)
        return header
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 33
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
