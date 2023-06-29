
import OUICore
import ProgressHUD
import RxSwift

enum UserDetailFor {
    case groupMemberInfo
    case card
}

class SpacerCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = UIColor.cF8F9FA
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UserDetailTableViewController: UIViewController {
    private let avatarView = AvatarView()
    
    private let nameLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f17
        v.textColor = UIColor.c0C1C33
        
        return v
    }()
    
    private lazy var IDLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f14
        v.textColor = UIColor.c8E9AB0
        v.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer()
        v.addGestureRecognizer(tap)
        
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            UIPasteboard.general.string = self?._viewModel.userId
            ProgressHUD.showSuccess("ID已复制".innerLocalized())
        }).disposed(by: _disposeBag)
        
        return v
    }()
    
    private lazy var sendMessageBtn: UIButton = {
        let v = UIButton(type: .system)
        v.setImage(UIImage(nameInBundle: "profile_message_button_icon"), for: .normal)
        v.setTitle("发消息".innerLocalized(), for: .normal)
        v.tintColor = .white
        v.titleLabel?.font = UIFont.f17
        v.backgroundColor = UIColor.c0089FF
        v.layer.cornerRadius = 6
        v.titleEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        v.contentHorizontalAlignment = .center
        
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            self?._viewModel.createSingleChat(onComplete: { [weak self] info in
                let vc = ChatViewControllerBuilder().build(info)
                vc.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(vc, animated: true)
                if let root = self?.navigationController?.viewControllers.first {
                    self?.navigationController?.viewControllers.removeAll(where: { controller in
                        controller != root && controller != vc
                    })
                }
            })
        }).disposed(by: _disposeBag)
        return v
    }()

    private lazy var addFriendBtn: UIButton = {
        let v = UIButton(type: .system)
        v.setImage(UIImage(nameInBundle: "chat_menu_add_friend_icon"), for: .normal)
        v.setTitle(" 加好友".innerLocalized(), for: .normal)
        v.tintColor = .white
        v.backgroundColor = UIColor.c0089FF
        v.titleLabel?.font = UIFont.f14
        v.layer.cornerRadius = 6
        
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            ProgressHUD.show()
            self?._viewModel.addFriend(onSuccess: { res in
                ProgressHUD.showSuccess("添加好友请求已发送".innerLocalized())
            }, onFailure: { (errCode, errMsg) in
                if errCode == SDKError.refuseToAddFriends.rawValue {
                    ProgressHUD.showError("该用户已设置不可添加！".innerLocalized())
                }
            })
        }).disposed(by: _disposeBag)
        return v
    }()

    private let _disposeBag = DisposeBag()
    private let _viewModel: UserDetailViewModel
    
    private lazy var _tableView: UITableView = {
        let v = UITableView()
        v.backgroundColor = .clear
        v.separatorStyle = .none
        let headerView: UIView = {
            let v = UIView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 96))
            v.backgroundColor = .tertiarySystemBackground
            
            let vStack: UIStackView = {
                let v = UIStackView(arrangedSubviews: [nameLabel, IDLabel])
                v.axis = .vertical
                v.distribution = .equalCentering
                v.spacing = 4
                
                return v
            }()
            
            let hStack: UIStackView = UIStackView(arrangedSubviews: [avatarView, vStack, UIView(), addFriendBtn])
            hStack.alignment = .center
            hStack.spacing = 8
            
            v.addSubview(hStack)
            hStack.snp.makeConstraints { make in
                make.leading.top.trailing.bottom.equalToSuperview().inset(8)
            }
            
            return v
        }()
        
        v.tableHeaderView = headerView
        v.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        v.register(MultipleTextLineCell.self, forCellReuseIdentifier: MultipleTextLineCell.className)
        v.register(SpacerCell.self, forCellReuseIdentifier: SpacerCell.className)
        v.delegate = self
        v.dataSource = self
        v.tableFooterView = UIView()
        return v
    }()
    
    private var rowItems: [RowType] = [.spacer]
    
    init(userId: String, groupId: String?, groupInfo: GroupInfo? = nil, userDetailFor: UserDetailFor = .groupMemberInfo) {
        _viewModel = UserDetailViewModel(userId: userId, groupId: groupId, groupInfo: groupInfo, userDetailFor: userDetailFor)
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBackgroundColor

        initView()
        bindData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        _viewModel.getUserOrMemberInfo()
    }
    private func initView() {
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        if _viewModel.userId == IMController.shared.uid {
            // 搜索的是自己，需要把几个功能按钮屏蔽掉
            return
        }
        
        let hStack: UIStackView = {
            
            var v: UIStackView = UIStackView(arrangedSubviews: [sendMessageBtn])
            
            if let groupInfo = _viewModel.groupInfo, groupInfo.applyMemberFriend != 0 {
                v = UIStackView(arrangedSubviews: [sendMessageBtn])
            }
            v.spacing = 16
            v.distribution = .fillEqually
            v.alignment = .center
            
            return v
        }()
        
        sendMessageBtn.snp.makeConstraints { make in
            make.height.equalTo(46)
        }

        if let configHandler = OIMApi.queryConfigHandler {
            configHandler { [weak self] result in
                if let `self` = self,  result != nil, let allowSendMsgNotFriend = result["allowSendMsgNotFriend"] as? Int, allowSendMsgNotFriend != 1 {
                    hStack.removeArrangedSubview(self.sendMessageBtn)
                    self.sendMessageBtn.removeFromSuperview()
                }
            }
        }
        
        view.addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-40)
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
    @objc private func rightButtonAction() {
        let vc = UserProfileTableViewController(userId: self._viewModel.userId)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func bindData() {
        _viewModel.userInfoRelay.subscribe(onNext: { [weak self] (userInfo: FullUserInfo?) in
            guard let userInfo, let sself = self else { return }
            
            sself.avatarView.setAvatar(url: userInfo.faceURL, text: userInfo.showName) { [weak self] in
                guard let self else { return }
                let vc = UserProfileTableViewController.init(userId: self._viewModel.userId, groupId: self._viewModel.groupId)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            var name: String? = userInfo.showName
            if let remark = userInfo.friendInfo?.remark, !remark.isEmpty {
                name = name?.append(string: "(\(remark))")
            }
            sself.nameLabel.text = name
            sself.addFriendBtn.isHidden = userInfo.friendInfo != nil
            sself.IDLabel.text = userInfo.userID

            if userInfo.userID == IMController.shared.uid {
                sself.addFriendBtn.isHidden = true
                sself.sendMessageBtn.isHidden = true
            } else if userInfo.friendInfo != nil, !sself.rowItems.contains(.profile) {
                //是好友可以查看详细
                sself.rowItems.append(.spacer)
                sself.rowItems.append(.profile)
                sself.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(sself.rightButtonAction))
            }
            sself._tableView.reloadData()
        }).disposed(by: _disposeBag)
        
        _viewModel.memberInfoRelay.subscribe(onNext: { [weak self] (memberInfo: GroupMemberInfo?) in
            guard let memberInfo, let sself = self else { return }
            sself.avatarView.setAvatar(url: memberInfo.faceURL, text: memberInfo.nickname, onTap: nil)
            sself.nameLabel.text = memberInfo.nickname
            sself.IDLabel.text = memberInfo.userID
            sself.addFriendBtn.isHidden = true
            
            guard sself._viewModel.groupId != nil else { return }
            // 群聊才有以下信息
            sself.rowItems = sself.rowItems.count > 1 ? sself.rowItems : [.nickName, .joinTime]
            
            if sself._viewModel.showJoinSource == true, !sself.rowItems.contains(.joinSource) {
                sself.rowItems.append(.joinSource)
            }
            
            if sself._viewModel.showSetAdmin == true {
                sself.rowItems.append(.spacer)
            }
            
        }).disposed(by: _disposeBag)
    }
}

extension UserDetailTableViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return rowItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let rowType: RowType = rowItems[indexPath.row]
        
        if rowType == .spacer {
            return tableView.dequeueReusableCell(withIdentifier: SpacerCell.className, for: indexPath)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className, for: indexPath) as! OptionTableViewCell
        
        cell.accessoryType = .none
        cell.subtitleLabel.textAlignment = .left

        if rowType == .profile {
            cell.titleLabel.isHidden = true
            cell.subtitleLabel.text = rowType.title
            cell.accessoryType = .disclosureIndicator
        }
        
        guard let info = _viewModel.memberInfoRelay.value else { return cell }
        cell.titleLabel.text = rowType.title
        
        if rowType == .nickName {
            cell.subtitleLabel.text = info.nickname
        } else if rowType == .joinTime {
            cell.subtitleLabel.text = FormatUtil.getFormatDate(formatString: "yyyy年MM月dd日", of: info.joinTime)
        } else if rowType == .joinSource {
            cell.subtitleLabel.text = info.joinWay
        }
                
        return cell
    }
    
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType: RowType = rowItems[indexPath.row]
        switch rowType {
        case .profile:
            print("跳转个人资料页")
            let vc = ProfileTableViewController(userID: _viewModel.userId)
            navigationController?.pushViewController(vc, animated: true)
        case .nickName, .joinTime, .joinSource: break
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowType: RowType = rowItems[indexPath.row]
        
        if rowType == .spacer {
            return 10
        }
        return UITableView.automaticDimension
    }
    
    enum RowType {
        case nickName
        case joinTime
        case joinSource
        case profile
        case spacer
        
        var title: String {
            switch self {
            case .nickName:
                return "群昵称".innerLocalized()
            case .joinTime:
                return "入群时间".innerLocalized()
            case .joinSource:
                return "入群方式".innerLocalized()
            case .profile:
                return "个人资料".innerLocalized()
            case .spacer:
                return ""
            }
        }
    }
}
