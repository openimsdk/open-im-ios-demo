
import RxCocoa
import RxSwift
import SVProgressHUD
import UIKit

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
        v.imageView.image = UIImage(nameInBundle: "common_send_msg_btn_icon")
        v.titleLabel.text = "发消息".innerLocalized()
        v.titleLabel.textColor = StandardUI.color_1B72EC
        v.titleLabel.font = UIFont.systemFont(ofSize: 12)
        v.tap.rx.event.subscribe(onNext: { [weak self] _ in
            self?._viewModel.createSingleChat(onComplete: { (viewModel: MessageListViewModel) in
                let vc = MessageListViewController(viewModel: viewModel)
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

    private lazy var addFriendBtn: UpImageButton = {
        let v = UpImageButton()
        v.imageView.image = UIImage(nameInBundle: "common_add_friend_btn_icon")
        v.titleLabel.text = "加好友".innerLocalized()
        v.titleLabel.textColor = StandardUI.color_1B72EC
        v.titleLabel.font = UIFont.systemFont(ofSize: 12)
        v.tap.rx.event.subscribe(onNext: { [weak self] _ in
            print("跳转添加好友页面")
            self?._viewModel.addFriend(onSuccess: { _ in
                SVProgressHUD.showSuccess(withStatus: "加好友请求已发送".innerLocalized())
            })
        }).disposed(by: _disposeBag)
        return v
    }()

    private let _disposeBag = DisposeBag()
    private let _viewModel: UserDetailViewModel

    private lazy var _tableView: UITableView = {
        let v = UITableView()
        v.backgroundColor = StandardUI.color_F1F1F1
        v.rowHeight = 55
        v.separatorStyle = .none
        let headerView: UIView = {
            let v = UIView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 96 + 12))
            v.backgroundColor = .white
            v.addSubview(avatarImageView)
            avatarImageView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(StandardUI.margin_22)
                make.size.equalTo(48)
                make.centerY.equalToSuperview()
            }

            let vStack: UIStackView = {
                let v = UIStackView(arrangedSubviews: [nameLabel, nicknameLabel, joinTimeLabel])
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
                l.frame = CGRect(x: 0, y: v.frame.size.height - 12, width: v.frame.size.width, height: 12)
                return l
            }()
            v.layer.addSublayer(grayLayer)
            return v
        }()

        v.tableHeaderView = headerView
        v.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        v.delegate = self
        v.dataSource = self
        v.tableFooterView = UIView()
        return v
    }()

    private var rowItems: [RowType] = [.identifier]

    init(userId: String, groupId: String?) {
        _viewModel = UserDetailViewModel(userId: userId, groupId: groupId)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        initView()
        bindData()
        _viewModel.getUserOrMemberInfo()
    }

    private func initView() {
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let hStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [sendMessageBtn, addFriendBtn])
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
        _viewModel.userInfoRelay.subscribe(onNext: { [weak self] (userInfo: FullUserInfo?) in
            self?.avatarImageView.setImage(with: userInfo?.faceURL, placeHolder: "contact_my_friend_icon")
            self?.nameLabel.text = userInfo?.showName
            self?.addFriendBtn.isHidden = userInfo?.friendInfo != nil
        }).disposed(by: _disposeBag)

        _viewModel.memberInfoRelay.subscribe(onNext: { [weak self] (memberInfo: GroupMemberInfo?) in
            guard let memberInfo = memberInfo else { return }
            self?.avatarImageView.setImage(with: memberInfo.faceURL, placeHolder: "contact_my_friend_icon")
            self?.nameLabel.text = memberInfo.nickname
            self?.nicknameLabel.isHidden = true
            self?.joinTimeLabel.text = FormatUtil.getFormatDate(formatString: "yyyy年MM月dd日", of: memberInfo.joinTime / 1000) + "加入该群聊".innerLocalized()
            self?.addFriendBtn.isHidden = true
            self?.rowItems = [.identifier]
            self?._tableView.reloadData()
        }).disposed(by: _disposeBag)
    }
}

extension UserDetailTableViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
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

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
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
