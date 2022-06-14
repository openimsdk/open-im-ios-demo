
import UIKit
import RxSwift

class SelectContactsViewController: UIViewController {
    
    var selectedContactsBlock: (([UserInfo]) -> Void)?
    var blockedUsers: [String] = []
    
    private let maxCount = 1000
    
    private lazy var _tableView: UITableView = {
        let v = UITableView()
        let config = SCIndexViewConfiguration.init(indexViewStyle: SCIndexViewStyle.default)!
        config.indexItemRightMargin = 8
        config.indexItemTextColor = UIColor.init(hexString: "#555555")
        config.indexItemSelectedBackgroundColor = UIColor.init(hexString: "#57be6a")
        config.indexItemsSpace = 4
        v.sc_indexViewConfiguration = config
        v.sc_translucentForTableViewInNavigationBar = true
        v.register(SelectUserTableViewCell.self, forCellReuseIdentifier: SelectUserTableViewCell.className)
        v.dataSource = self
        v.delegate = self
        v.rowHeight = UITableView.automaticDimension
        v.separatorInset = UIEdgeInsets.init(top: 0, left: 82, bottom: 0, right: StandardUI.margin_22)
        v.separatorColor = StandardUI.color_F1F1F1
        v.allowsMultipleSelection = true
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()
    
    private let _viewModel = FriendListViewModel()
    private let _disposeBag = DisposeBag()
    
    private let bottomBar = BottomBar()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        initView()
        bindData()
        _viewModel.getMyFriendList()
    }
    
    private func initView() {
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }
    }
    
    private func bindData() {
        _viewModel.lettersRelay.distinctUntilChanged().subscribe(onNext: { [weak self] (values: [String]) in
            guard let sself = self else { return }
            self?._tableView.sc_indexViewDataSource = values
            self?._tableView.sc_startSection = 0
            self?._tableView.reloadData()
        }).disposed(by: _disposeBag)
        
        bottomBar.completeBtn.rx.tap
            .throttle(.seconds(2), latest: false, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let sself = self, let selectedIndexs = sself._tableView.indexPathsForSelectedRows else { return }
                let users = sself._viewModel.getUsersAt(indexPaths: selectedIndexs)
                self?.selectedContactsBlock?(users)
            }).disposed(by: _disposeBag)
    }
    
    private func setSelectedCount() {
        let selectedIndexes = _tableView.indexPathsForSelectedRows ?? []
        bottomBar.selectCountBtn.setTitle("已选择：\(selectedIndexes.count)", for: .normal)
        let total = maxCount - selectedIndexes.count
        bottomBar.completeBtn.setTitle("确定(\(selectedIndexes.count)/\(total))", for: .normal)
    }
    
    class BottomBar: UIView {
        let completeBtn: UIButton = {
            let v = UIButton()
            v.layer.cornerRadius = 4
            v.backgroundColor = StandardUI.color_1B72EC
            v.setTitleColor(UIColor.white, for: .normal)
            v.setTitle("确定(0/1000)", for: .normal)
            v.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            v.contentEdgeInsets = UIEdgeInsets.init(top: 3, left: 6, bottom: 3, right: 6)
            return v
        }()
        
        let selectCountBtn: LayoutButton = {
            let v = LayoutButton.init(imagePosition: .right, atSpace: 7)
            v.setImage(UIImage.init(nameInBundle: "common_blue_arrow_up_icon"), for: .normal)
            v.setTitle("已选择：0人", for: .normal)
            v.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            v.setTitleColor(StandardUI.color_1B72EC, for: .normal)
            return v
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = .white
            self.addSubview(selectCountBtn)
            selectCountBtn.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(10)
                make.left.equalToSuperview().offset(StandardUI.margin_22)
            }
            
            self.addSubview(completeBtn)
            completeBtn.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-StandardUI.margin_22)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension SelectContactsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return _viewModel.lettersRelay.value.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _viewModel.contactSections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectUserTableViewCell.className) as! SelectUserTableViewCell
        let user: UserInfo = _viewModel.contactSections[indexPath.section][indexPath.row]
        cell.titleLabel.text = user.nickname
        cell.avatarImageView.setImage(with: user.faceURL, placeHolder: "contact_my_friend_icon")
        if blockedUsers.contains(user.userID) {
            cell.canBeSelected = false
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let user: UserInfo = _viewModel.contactSections[indexPath.section][indexPath.row]
        if blockedUsers.contains(user.userID) {
            return nil
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        setSelectedCount()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        setSelectedCount()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let name = _viewModel.lettersRelay.value[section]
        let header = ViewUtil.createSectionHeaderWith(text: name)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 33
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
