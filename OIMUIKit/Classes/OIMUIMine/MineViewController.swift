





import UIKit
import RxSwift

public class MineViewController: UIViewController {
    
    private lazy var headerView: HeaderView = {
        let v = HeaderView.init(frame: CGRect.init(x: 0, y: 0, width: kScreenWidth, height: 222.0 / 375.0 * kScreenWidth + 15))
        v.backgroundImageView.image = UIImage.init(nameInBundle: "mine_background_image")
        v.tap.rx.event.subscribe(onNext: { [weak self] _ in
            guard let user = self?._viewModel.currentUserRelay.value else { return }
            let vc = QRCodeViewController.init(idString: user.userID)
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
    
    private let items: [RowType] = RowType.allCases
    
    private let _viewModel = MineViewModel()
    private let _disposeBag = DisposeBag()
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
        bindData()
    }
    
    public override func viewSafeAreaInsetsDidChange() {
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
                return UIImage.init(nameInBundle: "mine_info_icon")
            case .notification:
                return UIImage.init(nameInBundle: "mine_notif_icon")
            case .setting:
                return UIImage.init(nameInBundle: "mine_setting_icon")
            case .aboutUs:
                return UIImage.init(nameInBundle: "mine_about_icon")
            case .logout:
                return UIImage.init(nameInBundle: "mine_logout_icon")
            }
        }
    }
}

extension MineViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MineOptionTableViewCell.className) as! MineOptionTableViewCell
        let item = items[indexPath.row]
        cell.titleLabel.text = item.title
        cell.avatarImageView.image = item.icon
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row: RowType = items[indexPath.row]
        switch row {
        case .myInfo:
            let vc = ProfileTableViewController()
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        case .setting:
            let vc = SettingTableViewController()
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        case .logout:
            AlertView.show(onWindowOf: self.view, alertTitle: "您确定要退出登录吗？".innerLocalized(), confirmTitle: "确定".innerLocalized()) { [weak self] in
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
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.addSubview(backgroundImageView)
            backgroundImageView.snp.makeConstraints { make in
                make.left.top.right.equalToSuperview()
                make.height.equalTo(backgroundImageView.snp.width).multipliedBy(222.0 / 375.0)
            }
            
            self.addSubview(avatarImageView)
            avatarImageView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(kStatusBarHeight + 25)
                make.centerX.equalToSuperview()
                make.size.equalTo(73)
            }
            
            self.addSubview(nameLabel)
            nameLabel.snp.makeConstraints { make in
                make.top.equalTo(avatarImageView.snp.bottom).offset(15)
                make.centerX.equalToSuperview()
            }

            let hStack: UIStackView = {
                let qrcodeIcon = UIImageView.init(image: UIImage.init(nameInBundle: "common_qrcode_icon_white"))
                let arrowIcon = UIImageView.init(image: UIImage.init(nameInBundle: "common_arrow_right_white"))
                let v = UIStackView.init(arrangedSubviews: [idLabel, qrcodeIcon, arrowIcon])
                v.axis = .horizontal
                v.distribution = .equalSpacing
                v.spacing = 8
                v.isUserInteractionEnabled = true
                return v
            }()
            
            hStack.addGestureRecognizer(tap)
            
            self.addSubview(hStack)
            hStack.snp.makeConstraints { make in
                make.top.equalTo(nameLabel.snp.bottom).offset(6)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().offset(-20).priority(.low)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
