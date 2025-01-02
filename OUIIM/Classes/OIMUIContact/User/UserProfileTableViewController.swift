
import RxCocoa
import RxSwift
import ProgressHUD
import OUICore
import OUICoreView
import SnapKit

class UserProfileTableViewController: UIViewController {
    
    private let friendButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitleColor(UIColor.red, for: .normal)
        
        return v
    }()
    
    private let _disposeBag = DisposeBag()
    private let _viewModel: UserProfileViewModel
    
    private lazy var _tableView: UITableView = {
        let v = UITableView()
        v.backgroundColor = .clear
        v.separatorStyle = .none
        v.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        v.register(SpacerCell.self, forCellReuseIdentifier: SpacerCell.className)
        v.delegate = self
        v.dataSource = self
        v.isScrollEnabled = false
        
        return v
    }()
    
    private var rowItems: [RowType] = [.remark, .recommend, .spacer, .blocked, .spacer]
    private var inBlackList = false
    private var allowAddFriend = false
    
    init(userId: String, groupId: String? = nil, isFriend: Bool?, allowAddFriend: Bool) {
        self.allowAddFriend = allowAddFriend
        _viewModel = UserProfileViewModel(userId: userId, groupId: groupId, isFriend: isFriend)
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("\(type(of: self))")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground

        initView()
        bindData()
        _viewModel.getUserOrMemberInfo()
    }
    
    private func initView() {
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func bindData() {
        _viewModel.memberInfoRelay.subscribe(onNext: { [weak self] (memberInfo: GroupMemberInfo?) in
            guard let memberInfo = memberInfo else { return }
            self?.rowItems = [.remark, .recommend, .spacer, .blocked, .spacer]
            self?._tableView.reloadData()
        }).disposed(by: _disposeBag)
        
        _viewModel.userInfoRelay.subscribe(onNext: { [weak self] _ in
            self?._tableView.reloadData()
        }).disposed(by: _disposeBag)
        
        _viewModel.isInBlackListRelay.subscribe(onNext: {[weak self] isIn in
            self?.inBlackList = isIn
            self?._tableView.reloadData()
        }).disposed(by: _disposeBag)
        
        _viewModel.isFriendRelay.subscribe(onNext: { [weak self] isFriend in
            guard let self, let isFriend else { return }
            friendButton.setTitle(isFriend ? "unfriend".innerLocalized() : "addFriend".innerLocalized(), for: .normal)
        }).disposed(by: _disposeBag)
    }
}

extension UserProfileTableViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return rowItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType: RowType = rowItems[indexPath.row]
        
        if rowType == .spacer {
            return tableView.dequeueReusableCell(withIdentifier: SpacerCell.className, for: indexPath)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className, for: indexPath) as! OptionTableViewCell
        
        cell.titleLabel.text = rowType.title
        cell.titleLabel.textColor = cell.subtitleLabel.textColor
        
        if rowType == .remark {
            cell.subtitleLabel.text = _viewModel.userInfoRelay.value?.remark
        } else if rowType == .blocked {
            cell.accessoryType = .none
            cell.switcher.isHidden = false
            cell.switcher.isOn = inBlackList
            cell.switcher.addTarget(self, action: #selector(blockedUser), for: .valueChanged)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let shouldShowFooter = (try? _viewModel.isFriendRelay.value()) == true || allowAddFriend
        guard shouldShowFooter else {
            return nil
        }
        
        let view = UIView()
        view.backgroundColor = .white
        view.addSubview(friendButton)
        
        friendButton.addTarget(self, action: #selector(deleteFriend), for: .touchUpInside)
        friendButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(44)
        }
        
        return view
    }

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowType: RowType = rowItems[indexPath.row]
        
        if rowType == .spacer {
            return 10
        }
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType: RowType = rowItems[indexPath.row]
        switch rowType {
        case .remark:
            modifyRemark()
        case .moreInfo:
            guard let userID = _viewModel.userInfoRelay.value?.userID else { return }
            let vc  = ProfileTableViewController(userID: userID)
            navigationController?.pushViewController(vc, animated: true)
        case .recommend:
            guard let user = _viewModel.userInfoRelay.value else { return }
            
#if ENABLE_ORGANIZATION
            let vc = MyContactsViewController(types: [.friends, .groups, .staff, .recent], multipleSelected: true)
#else
            let vc = MyContactsViewController(types: [.friends, .groups, .recent], multipleSelected: true)
#endif
            vc.selectedHandler = { [weak self, weak vc] infos in
                guard let self, let vc else { return }
                
                let forwardCard = ForwardCard(frame: view.bounds)
                forwardCard.contentLabel.text = MessageContentType.card.abstruct + (user.nickname ?? "")
                vc.navigationController?.topViewController?.view.addSubview(forwardCard)
                                
                forwardCard.numberOfItems = {
                    return infos.count
                }
                
                forwardCard.itemForIndex = { index in
                    return User(id: infos[index].ID!, name: infos[index].name!, faceURL: infos[index].faceURL)
                }
                
                forwardCard.cancelHandler = {
                    forwardCard.removeFromSuperview()
                }
                
                forwardCard.confirmHandler = { [weak self] text in
                    forwardCard.removeFromSuperview()
                    
                    guard let self else { return }
                    
                    var groupsID: [String] = []
                    var usersID: [String] = []
                    
                    infos.forEach { info in
                        if info.type == .group {
                            self._viewModel.sendCard(card: CardElem(userID: user.userID, nickname: user.nickname ?? "", faceURL: user.faceURL), to: info.ID!, conversationType: .superGroup)
                        } else {
                            self._viewModel.sendCard(card: CardElem(userID: user.userID, nickname: user.nickname ?? "", faceURL: user.faceURL), to: info.ID!, conversationType: .c2c)
                        }
                    }
                    
                    self.navigationController?.popToViewController(self, animated: true)
                }
                
                forwardCard.reloadData()
            }
            
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
        
    }
    
    enum RowType {
        case remark
        case moreInfo
        case recommend
        case blocked
        case spacer
        
        var title: String {
            switch self {
            case .remark:
                return "备注".innerLocalized()
            case .moreInfo:
                return "更多资料".innerLocalized()
            case .recommend:
                return "把他推荐给朋友".innerLocalized()
            case .blocked:
                return "加入黑名单".innerLocalized()
            case .spacer:
                return ""
            }
        }
    }
    
    @objc func blockedUser() {
        _viewModel.blockUser(blocked: !inBlackList) { r in
        }
    }
    
    func modifyRemark() {
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "save".innerLocalized(), style: .default, handler: { [self] alert -> Void in
            let firstTextField = alertController.textFields![0] as UITextField
            
            if let remark = firstTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                ProgressHUD.animate()
                _viewModel.saveRemark(remark: remark) { r in
                    ProgressHUD.dismiss()
                    if r != nil {
                        let index = rowItems.index(of: .remark)
                        let cell = _tableView.cellForRow(at: .init(row: index!, section: 0)) as! OptionTableViewCell
                        cell.subtitleLabel.text = remark
                    }
                }
            }
        })
        let cancelAction = UIAlertAction(title: "cancel".innerLocalized(), style: .default, handler: {
            (action : UIAlertAction!) -> Void in })
        
        alertController.addTextField { [self] (textField : UITextField!) -> Void in
            textField.placeholder = "setupRemark".innerLocalized()
            textField.rx.text.orEmpty
                        .map { String($0.prefix(16)) }
                        .bind(to: textField.rx.text)
                        .disposed(by: _disposeBag)
        }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func deleteFriend() {
        ProgressHUD.animate()
        
        if let isFriend = try? _viewModel.isFriendRelay.value(), isFriend {
            _viewModel.deleteFriend {[weak self] r in
                ProgressHUD.dismiss()
                
                let navController = self?.tabBarController?.children.first as? UINavigationController;
                let vc: ChatListViewController? = navController?.viewControllers.first(where: { vc in
                    return vc is ChatListViewController
                }) as? ChatListViewController
                
                if vc != nil {
                    vc!.refreshConversations()
                    self?.navigationController?.popToRootViewController(animated: true)
                }
            }
        } else {
            _viewModel.addFriend { [weak self] r in
                ProgressHUD.dismiss()
                self?.navigationController?.popViewController(animated: true)
            } onFailure: { [weak self] errCode, errMsg in
                ProgressHUD.error(errMsg)
            }
        }
    }
}
