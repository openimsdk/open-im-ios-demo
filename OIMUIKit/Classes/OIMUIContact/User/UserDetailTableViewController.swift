//






import UIKit
import RxSwift
import RxCocoa

class UserDetailTableViewController: UIViewController {
    private let avatarImageView = UIImageView()
    
    private let nameLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        v.textColor = StandardUI.color_333333
        return v
    }()
        
    private lazy var sendMessageBtn: UIButton = {
        let v = UIButton()
        v.setImage(UIImage.init(nameInBundle: "common_send_msg_btn_icon"), for: .normal)



        v.setTitleColor(StandardUI.color_1B72EC, for: .normal)
        v.titleLabel?.font = UIFont.systemFont(ofSize: 12)

        v.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] in
            self?._viewModel.createSingleChat(onComplete: { (viewModel: MessageListViewModel) in
                let vc = MessageListViewController.init(viewModel: viewModel)
                self?.navigationController?.pushViewController(vc, animated: true)
            })
        }).disposed(by: _disposeBag)
        return v
    }()
    
    private lazy var addFriendBtn: UIButton = {
        let v = UIButton()
        v.setImage(UIImage.init(nameInBundle: "common_add_friend_btn_icon"), for: .normal)




        v.setTitleColor(StandardUI.color_1B72EC, for: .normal)
        v.titleLabel?.font = UIFont.systemFont(ofSize: 12)
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
            v.addSubview(nameLabel)
            nameLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(avatarImageView.snp.right).offset(18)
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
        _viewModel.user = user
        avatarImageView.setImage(with: user?.faceURL, placeHolder: "contact_my_friend_icon")
        nameLabel.text = user?.showName
        addFriendBtn.isHidden = user?.friendInfo != nil
    }
}

extension UserDetailTableViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _viewModel.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
        let item = _viewModel.items[indexPath.row]
        cell.titleLabel.text = item.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item: UserDetailViewModel.RowType = _viewModel.items[indexPath.row]
        switch item {
        case .remark:
            print("跳转备注修改页面")
        case .identifier:
            print("直接复制ID并提示")
        case .profile:
            print("跳转个人资料页")
        }
    }
}
