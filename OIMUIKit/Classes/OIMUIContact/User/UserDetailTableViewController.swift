





import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD

class UserDetailTableViewController: UIViewController {
    private let avatarImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        return v
    }()
    
    private let nameLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        v.textColor = StandardUI.color_333333
        return v
    }()
    
    private let nicknameLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 12)
        v.textColor = StandardUI.color_666666
        return v
    }()
    
    private let joinTimeLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 12)
        v.textColor = StandardUI.color_666666
        return v
    }()
        
    private lazy var sendMessageBtn: UpImageButton = {
        let v = UpImageButton()
        v.imageView.image = UIImage.init(nameInBundle: "common_send_msg_btn_icon")
        v.titleLabel.text = "发消息".innerLocalized()
        v.titleLabel.textColor = StandardUI.color_1B72EC
        v.titleLabel.font = UIFont.systemFont(ofSize: 12)
        v.tap.rx.event.subscribe(onNext: { [weak self] _ in
            self?._viewModel.createSingleChat(onComplete: { (viewModel: MessageListViewModel) in
                let vc = MessageListViewController.init(viewModel: viewModel)
                self?.navigationController?.pushViewController(vc, animated: true)
            })
        }).disposed(by: _disposeBag)
        return v
    }()
    
    private lazy var addFriendBtn: UpImageButton = {
        let v = UpImageButton()
        v.imageView.image = UIImage.init(nameInBundle: "common_add_friend_btn_icon")
        v.titleLabel.text = "加好友".innerLocalized()
        v.titleLabel.textColor = StandardUI.color_1B72EC
        v.titleLabel.font = UIFont.systemFont(ofSize: 12)
        v.tap.rx.event.subscribe(onNext: { [weak self] _ in
            print("跳转添加好友页面")
        }).disposed(by: _disposeBag)
        return v
    }()
    
    private let _disposeBag = DisposeBag()
    private let _viewModel = UserDetailViewModel()
    
    private lazy var _tableView: UITableView = {
        let v = UITableView()
        v.backgroundColor = StandardUI.color_F1F1F1
        v.rowHeight = 55
        let headerView: UIView = {
            let v = UIView.init(frame: CGRect.init(x: 0, y: 0, width: kScreenWidth, height: 96 + 12))
            v.backgroundColor = .white
            v.addSubview(avatarImageView)
            avatarImageView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(StandardUI.margin_22)
                make.size.equalTo(48)
                make.centerY.equalToSuperview()
            }
            
            let vStack: UIStackView = {
                let v = UIStackView.init(arrangedSubviews: [nameLabel, nicknameLabel, joinTimeLabel])
                v.axis = .vertical
                v.distribution = .equalSpacing
                v.spacing = 4
                return v
            }()
            
            v.addSubview(vStack)
            vStack.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(avatarImageView.snp.right).offset(18)
                make.right.lessThanOrEqualToSuperview().offset(-20)
            }
            let grayLayer: CALayer = {
                let l = CALayer()
                l.backgroundColor = StandardUI.color_F1F1F1.cgColor
                l.frame = CGRect.init(x: 0, y: v.frame.size.height - 12, width: v.frame.size.width, height: 12)
                return l
            }()
            v.layer.addSublayer(grayLayer)
            return v
        }()
        
        v.tableHeaderView = headerView
        v.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        v.delegate = self
        v.dataSource = self
        return v
    }()
    
    private var rowItems: [RowType] = [.identifier]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        initView()
        bindData()
    }
    
    private func initView() {
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let hStack: UIStackView = {
            let v = UIStackView.init(arrangedSubviews: [sendMessageBtn, addFriendBtn])
            v.axis = .horizontal
            v.spacing = 60
            v.distribution = .fillEqually
            return v
        }()
        
        view.addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-40)
            make.centerX.equalToSuperview()
        }
    }
    
    private func bindData() {
        
    }

    private var user: FullUserInfo?
    func setUser(_ user: FullUserInfo?) {
        _viewModel.userId = user?.userID
        avatarImageView.setImage(with: user?.faceURL, placeHolder: "contact_my_friend_icon")
        nameLabel.text = user?.showName
        addFriendBtn.isHidden = user?.friendInfo != nil
    }
    
    func setMemberInfo(member: GroupMemberInfo) {
        _viewModel.userId = member.userID
        avatarImageView.setImage(with: member.faceURL, placeHolder: "contact_my_friend_icon")
        nameLabel.text = member.nickname
        nicknameLabel.isHidden = true
        joinTimeLabel.text = FormatUtil.getFormatDate(formatString: "yyyy年MM月dd日", of: member.joinTime / 1000) + "加入该群聊".innerLocalized()
        addFriendBtn.isHidden = true
        rowItems = [.identifier]
        _tableView.reloadData()
    }
}

extension UserDetailTableViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
        let rowType: RowType = rowItems[indexPath.row]
        cell.titleLabel.text = rowType.title
        if rowType == .identifier {
            cell.subtitleLabel.text = _viewModel.userId
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType: RowType = rowItems[indexPath.row]
        switch rowType {
        case .remark:
            print("跳转修改备注页")
        case .identifier:
            UIPasteboard.general.string = _viewModel.userId
            SVProgressHUD.showSuccess(withStatus: "ID已复制".innerLocalized())
        case .profile:
            print("跳转个人资料页")
        }
    }
    
    enum RowType {
        case remark
        case identifier
        case profile
        
        var title: String {
            switch self {
            case .remark:
                return "备注".innerLocalized()
            case .identifier:
                return "ID"
            case .profile:
                return "个人资料".innerLocalized()
            }
        }
    }
}
