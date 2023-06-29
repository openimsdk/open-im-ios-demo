
import RxCocoa
import RxSwift
import ProgressHUD
import OUICore
import OUICoreView
import SnapKit

class UserProfileTableViewController: UIViewController {
    
    private let deleteFriendButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("解除好友关系".innerLocalized(), for: .normal)
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

    private var rowItems: [RowType] = [.remark, .spacer, .blocked, .spacer]
    private var inBlackList = false
    
    init(userId: String, groupId: String? = nil) {
        _viewModel = UserProfileViewModel(userId: userId, groupId: groupId)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            self?.rowItems = [.remark, .spacer, .blocked, .spacer]
            self?._tableView.reloadData()
        }).disposed(by: _disposeBag)
        
        _viewModel.isInBlackListRelay.subscribe(onNext: {[weak self] isIn in
            self?.inBlackList = isIn
            self?._tableView.reloadData()
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
            cell.subtitleLabel.text = _viewModel.userId
        } else if rowType == .blocked {
            cell.accessoryType = .none
            cell.switcher.isHidden = false
            cell.switcher.isOn = inBlackList
            cell.switcher.addTarget(self, action: #selector(blockedUser), for: .valueChanged)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let view = UIView()
        view.backgroundColor = .white
        view.addSubview(deleteFriendButton)
        
        deleteFriendButton.addTarget(self, action: #selector(deleteFriend), for: .touchUpInside)
        deleteFriendButton.snp.makeConstraints { make in
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
        default:
            break
        }
    
    }

    enum RowType {
        case remark
        case blocked
        case spacer

        var title: String {
            switch self {
            case .remark:
                return "备注".innerLocalized()
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

        let saveAction = UIAlertAction(title: "保存".innerLocalized(), style: .default, handler: { [self] alert -> Void in
            let firstTextField = alertController.textFields![0] as UITextField
            
            if let remark = firstTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                
                _viewModel.saveRemark(remark: remark) { r in
                    let index = rowItems.index(of: .remark)
                    let cell = _tableView.cellForRow(at: .init(row: index!, section: 0)) as! OptionTableViewCell
                    cell.subtitleLabel.text = remark
                }
            }
        })
        let cancelAction = UIAlertAction(title: "取消".innerLocalized(), style: .default, handler: {
            (action : UIAlertAction!) -> Void in })
        
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "请输入备注".innerLocalized()
        }

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func deleteFriend() {
        ProgressHUD.show()
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
    }
}
