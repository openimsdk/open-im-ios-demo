
import OUICore
import OUICoreView
import RxSwift
import ProgressHUD
import MJRefresh

class GroupListViewController: UIViewController {
    
    var selectCallBack: (([GroupInfo]) -> Void)?
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = true
    }
    
    private lazy var createChatBtn: UIBarButtonItem = {
        let v = UIBarButtonItem()
        v.title = "createGroup".innerLocalized()
        v.rx.tap.subscribe(onNext: { [weak self] in
            self?.newGroup(groupType: .working)
        }).disposed(by: _disposeBag)
        return v
    }()
    
    func newGroup(groupType: GroupType = .normal) {
        
        let vc = SelectContactsViewController()
        vc.selectedContact(hasSelected: []) { [weak self] (_, r: [ContactInfo]) in
            guard let sself = self else { return }
            
            let users = r.map{UserInfo(userID: $0.ID!, nickname: $0.name, faceURL: $0.faceURL)}
            let vc = NewGroupViewController(users: users, groupType: groupType)
            sself.navigationController?.pushViewController(vc, animated: true)
        }
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "我的群组".innerLocalized()
        view.backgroundColor = .viewBackgroundColor
        
        initView()
        bindData()
        
        let con = IMController.shared.connectionRelay.value
        
        if con.status == .syncComplete {
            tableView.mj_header?.beginRefreshing()
        } else {
            IMController.shared.connectionRelay.subscribe(onNext: { [weak self] c in
                guard let self, c.status == .syncComplete else { return }
                
                if isViewLoaded {
                    tableView.mj_header?.beginRefreshing()
                }
            }).disposed(by: _disposeBag)
        }
    }
    
    private lazy var tableView: UITableView = {
        let v = UITableView()
        v.register(FriendListUserTableViewCell.self, forCellReuseIdentifier: FriendListUserTableViewCell.className)
        v.backgroundColor = .clear
        v.rowHeight = 64.h
        v.separatorColor = .clear
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        
        let header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            guard let self else { return }
            
            self._viewModel.onRefresh { result in
                
                if result < self._viewModel.count {
                    v.mj_footer?.endRefreshingWithNoMoreData()
                }
                
                v.mj_header?.endRefreshing()
            }
        })
        
        header.lastUpdatedTimeLabel?.isHidden = true
        v.mj_header = header
        
        let footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            guard let self else { return }
            
            self._viewModel.onLoadMore { result in
                
                if result < self._viewModel.count {
                    v.mj_footer?.endRefreshingWithNoMoreData()
                } else {
                    v.mj_footer?.endRefreshing()
                }
            }
        })
        
        footer.isRefreshingTitleHidden = true
        v.mj_footer = footer
        
        return v
    }()
    
    private let iCreateBtn: UnderlineButton = {
        let v = UnderlineButton(frame: .zero)
        v.setTitle("我创建的".innerLocalized(), for: .normal)
        v.setTitleColor(.c0C1C33, for: .normal)
        v.titleLabel?.font = .f17
        v.isSelected = true
        v.underLineWidth = 20
        
        return v
    }()
    
    private let iJoinBtn: UnderlineButton = {
        let v = UnderlineButton(frame: .zero)
        v.setTitle("我加入的".innerLocalized(), for: .normal)
        v.setTitleColor(.c0C1C33, for: .normal)
        v.titleLabel?.font = .f17
        v.underLineWidth = 20
        
        return v
    }()
    
    private lazy var resultC = GroupListResultViewController()
    
    private func initView() {
        let searchC: UISearchController = {
            let v = UISearchController(searchResultsController: resultC)
            v.searchResultsUpdater = resultC
            v.searchBar.placeholder = "搜索".innerLocalized()
            v.obscuresBackgroundDuringPresentation = true
            
            return v
        }()
        navigationItem.searchController = searchC
        
        resultC.selectUserCallBack = { [weak self] gid in
            guard let `self` = self else { return }
            
            let groupInfo = self._viewModel.myGroupsRelay.value.first{ $0.groupID == gid }
            self.toConversation(groupInfo!)
        }
        
        let btnStackView: UIStackView = {
            
            let line = UIView()
            line.backgroundColor = .sepratorColor
            let hStack = UIStackView(arrangedSubviews: [iCreateBtn, iJoinBtn])
            hStack.distribution = .fillEqually
            
            let v = UIStackView(arrangedSubviews: [hStack, line])
            v.axis = .vertical
            v.spacing = 4
            v.backgroundColor = .cellBackgroundColor
            
            line.snp.makeConstraints { make in
                make.height.equalTo(1)
            }
            
            return v
        }()
        
        view.addSubview(btnStackView)
        btnStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(btnStackView.snp.bottom)
            make.leading.bottom.trailing.equalToSuperview()
        }
    }
    
    private let _viewModel = GroupListViewModel()
    private let _disposeBag = DisposeBag()
    private func bindData() {
        _viewModel.loading.asDriver().drive(onNext: { isLoading in
            if isLoading {
                ProgressHUD.animate()
            } else {
                ProgressHUD.dismiss()
            }
        }).disposed(by: _disposeBag)
        
        iCreateBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.tableView.contentOffset = .zero
            self?._viewModel.isICreateTableSelected.accept(true)
        }).disposed(by: _disposeBag)
        
        iJoinBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.tableView.contentOffset = .zero
            self?._viewModel.isICreateTableSelected.accept(false)
        }).disposed(by: _disposeBag)
        
        _viewModel.isICreateTableSelected
            .bind(to: iCreateBtn.rx.isSelected)
            .disposed(by: _disposeBag)
        
        _viewModel.isICreateTableSelected
            .map { !$0 }
            .bind(to: iJoinBtn.rx.isSelected)
            .disposed(by: _disposeBag)
        
        _viewModel.items.bind(to: tableView.rx.items(cellIdentifier: FriendListUserTableViewCell.className, cellType: FriendListUserTableViewCell.self)) { _, model, cell in
            cell.titleLabel.text = model.groupName
            cell.subtitleLabel.text = "\(model.memberCount)人"
            cell.avatarImageView.setAvatar(url: model.faceURL, text: nil, placeHolder: "contact_my_group_icon", onTap: nil)
        }.disposed(by: _disposeBag)
        
        tableView.rx.modelSelected(GroupInfo.self).subscribe(onNext: { [weak self] (groupInfo: GroupInfo) in
            if let handler = self?.selectCallBack {
                handler([groupInfo])
            } else {
                self?.toConversation(groupInfo)
            }
        }).disposed(by: _disposeBag)
        
        _viewModel.myGroupsRelay
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] groups in
                self?.resultC.dataList = groups
            }).disposed(by: _disposeBag)
    }
    
    func toConversation(_ groupInfo: GroupInfo) {
        IMController.shared.getConversation(sessionType: .superGroup, sourceId: groupInfo.groupID) { [weak self] (conversation: ConversationInfo?) in
            guard let conversation else { return }
            let vc = ChatViewControllerBuilder().build(conversation)
            self?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
