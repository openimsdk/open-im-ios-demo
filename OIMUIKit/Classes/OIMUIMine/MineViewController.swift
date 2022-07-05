
import RxSwift
import UIKit

public class MineViewController: UIViewController {
    private lazy var headerView: HeaderView = {
        let v = HeaderView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 222.0 / 375.0 * kScreenWidth + 15))
        v.backgroundImageView.image = UIImage(nameInBundle: "mine_background_image")
        v.tap.rx.event.subscribe(onNext: { [weak self] _ in
            guard let user = self?._viewModel.currentUserRelay.value else { return }
            let vc = QRCodeViewController(idString: IMController.addFriendPrefix.append(string: user.userID))
            vc.avatarImageView.setImage(with: user.faceURL, placeHolder: "contact_my_friend_icon")
            vc.nameLabel.text = user.nickname
            vc.tipLabel.text = "扫一扫下面的二维码，添加我为好友"
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: _disposeBag)
        return v
    }()

    private lazy var _tableView: UITableView = {
        let v = UITableView()
        v.register(MineOptionTableViewCell.self, forCellReuseIdentifier: MineOptionTableViewCell.className)
        v.dataSource = self
        v.delegate = self
        v.tableHeaderView = headerView
        v.rowHeight = 50
        v.separatorStyle = .none
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()

    private let items: [RowType] = [.myInfo, .setting, .logout]

    private let _viewModel = MineViewModel()
    private let _disposeBag = DisposeBag()

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        initView()
        bindData()
    }

    override public func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        _tableView.snp.updateConstraints { make in
            make.top.equalTo(-view.safeAreaInsets.top)
        }
    }

    private func initView() {
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.left.bottom.right.equalToSuperview()
        }
    }

    private func bindData() {
        _viewModel.currentUserRelay.subscribe(onNext: { [weak self] (user: UserInfo?) in
            self?.headerView.avatarImageView.setImage(with: user?.faceURL, placeHolder: "contact_my_friend_icon")
            self?.headerView.nameLabel.text = user?.nickname
            self?.headerView.idLabel.text = "ID:".append(string: user?.userID)
        }).disposed(by: _disposeBag)
    }

    enum RowType: CaseIterable {
        case myInfo
        case notification
        case setting
        case aboutUs
        case logout

        var title: String {
            switch self {
            case .myInfo:
                return "我的信息".innerLocalized()
            case .notification:
                return "新消息通知".innerLocalized()
            case .setting:
                return "账号设置".innerLocalized()
            case .aboutUs:
                return "关于我们".innerLocalized()
            case .logout:
                return "退出登录".innerLocalized()
            }
        }

        var icon: UIImage? {
            switch self {
            case .myInfo:
                return UIImage(nameInBundle: "mine_info_icon")
            case .notification:
                return UIImage(nameInBundle: "mine_notif_icon")
            case .setting:
                return UIImage(nameInBundle: "mine_setting_icon")
            case .aboutUs:
                return UIImage(nameInBundle: "mine_about_icon")
            case .logout:
                return UIImage(nameInBundle: "mine_logout_icon")
            }
        }
    }
}

extension MineViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MineOptionTableViewCell.className) as! MineOptionTableViewCell
        let item = items[indexPath.row]
        cell.titleLabel.text = item.title
        cell.avatarImageView.image = item.icon
        return cell
    }

    public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row: RowType = items[indexPath.row]
        switch row {
        case .myInfo:
            let vc = ProfileTableViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case .setting:
            let vc = SettingTableViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case .logout:
            AlertView.show(onWindowOf: view, alertTitle: "您确定要退出登录吗？".innerLocalized(), confirmTitle: "确定".innerLocalized()) { [weak self] in
                self?._viewModel.logout()
            }
        default:
            print("跳转\(row.title)")
        }
    }
}

extension MineViewController {
    class HeaderView: UIView {
        let backgroundImageView: UIImageView = {
            let v = UIImageView()
            v.contentMode = .scaleAspectFill
            v.clipsToBounds = true
            return v
        }()

        let avatarImageView: UIImageView = {
            let v = UIImageView()
            v.layer.cornerRadius = 10
            v.clipsToBounds = true
            v.contentMode = .scaleAspectFill
            return v
        }()

        let nameLabel: UILabel = {
            let v = UILabel()
            v.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            v.textColor = .white
            return v
        }()

        let idLabel: UILabel = {
            let v = UILabel()
            v.font = UIFont.systemFont(ofSize: 14)
            v.textColor = .white
            return v
        }()

        let tap: UITapGestureRecognizer = .init()

        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(backgroundImageView)
            backgroundImageView.snp.makeConstraints { make in
                make.left.top.right.equalToSuperview()
                make.height.equalTo(backgroundImageView.snp.width).multipliedBy(222.0 / 375.0)
            }

            addSubview(avatarImageView)
            avatarImageView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(kStatusBarHeight + 25)
                make.centerX.equalToSuperview()
                make.size.equalTo(73)
            }

            addSubview(nameLabel)
            nameLabel.snp.makeConstraints { make in
                make.top.equalTo(avatarImageView.snp.bottom).offset(15)
                make.centerX.equalToSuperview()
            }

            let hStack: UIStackView = {
                let qrcodeIcon = UIImageView(image: UIImage(nameInBundle: "common_qrcode_icon_white"))
                let arrowIcon = UIImageView(image: UIImage(nameInBundle: "common_arrow_right_white"))
                let v = UIStackView(arrangedSubviews: [idLabel, qrcodeIcon, arrowIcon])
                v.axis = .horizontal
                v.distribution = .equalSpacing
                v.spacing = 8
                v.isUserInteractionEnabled = true
                return v
            }()

            hStack.addGestureRecognizer(tap)

            addSubview(hStack)
            hStack.snp.makeConstraints { make in
                make.top.equalTo(nameLabel.snp.bottom).offset(6)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().offset(-20).priority(.low)
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
