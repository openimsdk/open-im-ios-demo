
import OUICore
import RxSwift
import SnapKit

public typealias SelectedContactsHandler = (([ContactInfo]) -> Void)

fileprivate let maxCount = 1000

public class SelectContactsViewController: UIViewController {
    // 选择后的回调
    private var selectedHandler: SelectedContactsHandler?
    private var contacTypes: [ContactType] = []
    private var sourceID: String? // 可能是群ID，可能是部门ID
    private var multipleSelected: Bool = false // 可多选
    private var hasSelectedItems: [ContactInfo] = [] // 上一次已经选择过的ID
    private var blockedIDs: [String] = [] // 不能选择的ID
    
    public init(types: [ContactType] = [.friends], multiple: Bool = true, sourceID: String? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.contacTypes = types
        self.sourceID = sourceID
        self.multipleSelected = multiple
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 设置其它选项
    public func selectedContact(hasSelected: [String]? = nil, blocked: [String]? = nil, handler: SelectedContactsHandler?) {
        if let hasSelected = hasSelected {
            self.hasSelectedItems = hasSelected.map{ContactInfo(ID: $0)}
        }
        self.blockedIDs = blocked ?? []
        self.selectedHandler = handler
    }
    
    private lazy var _tableView: UITableView = {
        let v = UITableView()
        let config = SCIndexViewConfiguration(indexViewStyle: SCIndexViewStyle.default)!
        config.indexItemRightMargin = 8
        config.indexItemTextColor = UIColor(hexString: "#555555")
        config.indexItemSelectedBackgroundColor = UIColor(hexString: "#57be6a")
        config.indexItemsSpace = 4
        v.sc_indexViewConfiguration = config
        v.sc_translucentForTableViewInNavigationBar = true
        v.register(SelectUserTableViewCell.self, forCellReuseIdentifier: SelectUserTableViewCell.className)
        v.dataSource = self
        v.delegate = self
        v.rowHeight = UITableView.automaticDimension
        v.allowsMultipleSelection = true
        v.backgroundColor = .clear
        
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()
    
    // contacTypes 存在多个元素，才会出现按钮
    private let friendsButton: UnderlineButton = {
        let v = UnderlineButton(frame: .zero)
        v.setTitle("我的好友".innerLocalized(), for: .normal)
        v.setTitleColor(StandardUI.color_333333, for: .normal)
        v.titleLabel?.font = .systemFont(ofSize: 14)
        v.isSelected = true
        v.underLineWidth = 30
        return v
    }()
    
    private let groupsButton: UnderlineButton = {
        let v = UnderlineButton(frame: .zero)
        v.setTitle("我的群组".innerLocalized(), for: .normal)
        v.setTitleColor(StandardUI.color_333333, for: .normal)
        v.titleLabel?.font = .systemFont(ofSize: 14)
        v.underLineWidth = 30
        return v
    }()
    
    private let _viewModel = SelectContactsViewModel()
    private var resultVC: SelectContactsResultViewController!
    private let _disposeBag: DisposeBag = DisposeBag()
    
    private let bottomBar = BottomBar()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBackgroundColor
        
        initView()
        bindData()
        loadData()
    }
    
    private func initView() {
        var searchC: UISearchController!
        resultVC = SelectContactsResultViewController(selectedCallback: { [weak self] items in
            guard let `self` = self, let item = items.first else { return }
            
            if let indexPath = self._viewModel.getContactIndexPath(by: item.ID!) {
                self._tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                self.appendSelectedItems(item)
                searchC.isActive = false
            }
        }, removeCallback: { [weak self] items in
            guard let `self` = self, !items.isEmpty else { return }
            // 将需要移除的item都执行下选中函数
            items.forEach { user in
                if let indexPath = self._viewModel.getContactIndexPath(by: user.ID!) {
                    self._tableView.deselectRow(at: indexPath, animated: true)
                    self.removeSelectedItems(user)
                } else {
                }
                searchC.isActive = false
            }
        })
        
        searchC = {
            let v = UISearchController(searchResultsController: resultVC)
            v.searchResultsUpdater = self
            v.searchBar.placeholder = "搜索".innerLocalized()
            v.obscuresBackgroundDuringPresentation = true
            
            return v
        }()
        
        navigationItem.searchController = searchC
        
        searchC.searchBar.rx.textDidBeginEditing.subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            self.resultVC.selectedUsers = self.hasSelectedItems
        }).disposed(by: _disposeBag)
        
        if multipleSelected {
            view.addSubview(bottomBar)
            bottomBar.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
            }
        }
        
        bottomBar.selectCountBtn.addTarget(self, action: #selector(showSelectedItem), for: .touchUpInside)
        // 切换tab
        if contacTypes.count > 1 {
            let row = UIStackView()
            row.alignment = .center
            row.distribution = .fillEqually
            
            if contacTypes.contains(.friends) {
                row.addArrangedSubview(friendsButton)
            }
            if contacTypes.contains(.groups) {
                row.addArrangedSubview(groupsButton)
            }
            
            view.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            }
            
            view.addSubview(_tableView)
            _tableView.snp.makeConstraints { make in
                make.top.equalTo(row.snp.bottom).offset(16)
                make.leading.trailing.equalToSuperview()
                !multipleSelected ? make.bottom.equalToSuperview() : make.bottom.equalTo(bottomBar.snp.top)
            }
        } else {
            view.addSubview(_tableView)
            _tableView.snp.makeConstraints { make in
                make.left.top.right.equalToSuperview()
                !multipleSelected ? make.bottom.equalToSuperview() : make.bottom.equalTo(bottomBar.snp.top)
            }
        }
    }
    
    private func bindData() {
        _viewModel.lettersRelay.distinctUntilChanged().subscribe(onNext: { [weak self] (values: [String]) in
            guard let `self` = self else { return }
            self._tableView.sc_indexViewDataSource = values
            self._tableView.sc_startSection = 0
            self._tableView.reloadData()
            // 选中
            self.defaultSelectedItems()
        }).disposed(by: _disposeBag)
        // 搜索数据
        _viewModel.searchResult.subscribe(onNext: { [weak self] r in
            self?.resultVC.dataList = r
            self?.resultVC.updateSearchResults(text: self?.navigationItem.searchController?.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines))
        }).disposed(by: _disposeBag)
        
        bottomBar.completeBtn.rx.tap
            .throttle(.seconds(2), latest: false, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                if !self.hasSelectedItems.isEmpty {
                    self.selectedHandler?(self.hasSelectedItems)
                }
            }).disposed(by: _disposeBag)
        
        friendsButton.rx.tap.subscribe(onNext: { [weak self] in
            self?._viewModel.tabSelected.accept(.friends)
        }).disposed(by: _disposeBag)
        
        groupsButton.rx.tap.subscribe(onNext: { [weak self] in
            self?._viewModel.tabSelected.accept(.groups)
        }).disposed(by: _disposeBag)
        
        // 如果只选择好友/或者群， 直接刷新界面
        if contacTypes.count == 1 {
            return _viewModel.tabSelected.accept(.undefine)
        }
        
        _viewModel.tabSelected
            .map({ type in
                return type == .friends
            })
            .bind(to: friendsButton.rx.isSelected)
            .disposed(by: _disposeBag)
        _viewModel.tabSelected
            .map({ type in
                return type == .groups
            })
            .bind(to: groupsButton.rx.isSelected)
            .disposed(by: _disposeBag)
    }
    
    private func loadData() {
        
        if contacTypes.contains(.friends) {
            _viewModel.getMyFriendList()
        }
        if contacTypes.contains(.groups) {
            _viewModel.getGroups()
        }
        if contacTypes.contains(.members) {
            blockedIDs.append(IMController.shared.getLoginUserID())
            _viewModel.getGroupMemberList(groupID: sourceID!)
        }
    }
    
    // 把默认的元素选中
    private func defaultSelectedItems() {
        for(i, item) in hasSelectedItems.enumerated() {
            if let indexPath = _viewModel.getContactIndexPath(by: item.ID!) {
                _tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                hasSelectedItems[i] = _viewModel.getContactAt(indexPaths: [indexPath]).first!
            }
        }
        
        updateSelectedResult()
    }
    
    // 增加选中的元素
    private func appendSelectedItems(_ contact: ContactInfo) {
        hasSelectedItems.append(contact)
        updateSelectedResult()
    }
    // 移除选择的元素
    private func removeSelectedItems(_ contact: ContactInfo) {
        hasSelectedItems.removeAll(where: {$0.ID == contact.ID})
        updateSelectedResult()
    }
    
    private func updateSelectedResult() {
        if multipleSelected {
            let count = self.hasSelectedItems.count
            let total = maxCount - count
            bottomBar.selectCountBtn.setTitle("已选择：(\(count))", for: .normal)
            bottomBar.completeBtn.setTitle("确定(\(count)/\(total))", for: .normal)
        } else {
            self.selectedHandler?(self.hasSelectedItems.map{ContactInfo(ID: $0.ID, name: $0.name, faceURL: $0.faceURL)})
        }
    }
    
    @objc private func showSelectedItem() {
        let vc = ShowSelectedUserViewController(users: hasSelectedItems) { [weak self] items in
            guard let `self` = self else { return }
            // 将需要移除的item都执行下选中函数
            items.forEach { user in
                if let indexPath = self._viewModel.getContactIndexPath(by: user.ID!) {
                    self._tableView.deselectRow(at: indexPath, animated: false)
                    self.removeSelectedItems(user)
                } else {
                }
            }
        }
        
        present(vc, animated: true)
    }
    
    class BottomBar: UIView {
        let completeBtn: UIButton = {
            let v = UIButton(type: .system)
            v.layer.cornerRadius = 4
            v.backgroundColor = .c0089FF
            v.setTitleColor(.white, for: .normal)
            v.setTitle("确定(0/\(maxCount)".innerLocalized(), for: .normal)
            v.titleLabel?.font = .f14
            v.contentEdgeInsets = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)
            
            return v
        }()
        
        let selectCountBtn: LayoutButton = {
            let v = LayoutButton(imagePosition: .right, atSpace: 7)
            v.setImage(UIImage(nameInBundle: "common_blue_arrow_up_icon"), for: .normal)
            v.setTitle("已选择：(0)".innerLocalized(), for: .normal)
            v.titleLabel?.font = .f14
            v.setTitleColor(.c0089FF, for: .normal)
            
            return v
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .tertiarySystemBackground
            
            addSubview(completeBtn)
            completeBtn.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.trailing.equalToSuperview().inset(16)
                make.height.equalTo(40)
            }
            
            addSubview(selectCountBtn)
            selectCountBtn.snp.makeConstraints { make in
                make.centerY.equalTo(completeBtn)
                make.leading.equalToSuperview().offset(16)
                make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
            }
        }
        
        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    deinit {
        print("de init \(type(of: self))")
    }
}

extension SelectContactsViewController: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in _: UITableView) -> Int {
        return _viewModel.lettersRelay.value.count
    }
    
    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _viewModel.contactsSections[section].count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectUserTableViewCell.className) as! SelectUserTableViewCell
        let contact = _viewModel.contactsSections[indexPath.section][indexPath.row]
        
        cell.titleLabel.text = contact.name
        cell.avatarImageView.setAvatar(url: contact.faceURL, text: contact.name)
        cell.showSelectedIcon = multipleSelected
        
        if blockedIDs.contains(contact.ID!) {
            cell.canBeSelected = false
        }
        
        return cell
    }
    
    public func tableView(_: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        var userID = _viewModel.contactsSections[indexPath.section][indexPath.row].ID!
        
        if blockedIDs.contains(userID) {
            return nil
        }
        return indexPath
    }
    
    public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = _viewModel.contactsSections[indexPath.section][indexPath.row]
        appendSelectedItems(contact)
    }
    
    public func tableView(_: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let contact = _viewModel.contactsSections[indexPath.section][indexPath.row]
        removeSelectedItems(contact)
    }
    
    public func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let name = _viewModel.lettersRelay.value[section]
        let header = ViewUtil.createSectionHeaderWith(text: name)
        
        return header
    }
    
    public func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 33
    }
    
    public func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}

extension SelectContactsViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        if let keyword = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            _viewModel.search(keyword: keyword)
        }
    }
}
