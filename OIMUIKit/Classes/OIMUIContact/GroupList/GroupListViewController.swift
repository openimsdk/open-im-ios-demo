





import UIKit
import RxSwift
import RxDataSources

class GroupListViewController: UIViewController {
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "我的群组".innerLocalized()
        initView()
        bindData()
        _viewModel.getMyGroups()
    }
    
    private lazy var tableView: UITableView = {
        let v = UITableView()
        v.register(FriendListUserTableViewCell.self, forCellReuseIdentifier: FriendListUserTableViewCell.className)
        v.separatorInset = UIEdgeInsets.init(top: 0, left: 82, bottom: 0, right: StandardUI.margin_22)
        v.separatorColor = StandardUI.color_F1F1F1
        v.rowHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()
    
    private let iCreateBtn: UnderlineButton = {
        let v = UnderlineButton.init(frame: .zero)
        v.setTitle("我创建的".innerLocalized(), for: .normal)
        v.setTitleColor(StandardUI.color_333333, for: .normal)
        v.titleLabel?.font = .systemFont(ofSize: 14)
        v.isSelected = true
        v.underLineWidth = 30
        return v
    }()
    
    private let iJoinBtn: UnderlineButton = {
        let v = UnderlineButton.init(frame: .zero)
        v.setTitle("我加入的".innerLocalized(), for: .normal)
        v.setTitleColor(StandardUI.color_333333, for: .normal)
        v.titleLabel?.font = .systemFont(ofSize: 14)
        v.underLineWidth = 30
        return v
    }()
    
    private lazy var resultC = GroupListResultViewController()
    
    private func initView() {
        let searchC: UISearchController = {
            let v = UISearchController.init(searchResultsController: resultC)
            v.searchResultsUpdater = resultC
            v.searchBar.placeholder = "搜索".innerLocalized() + ":" + "群组".innerLocalized()
            v.obscuresBackgroundDuringPresentation = true
            
            return v
        }()
        self.navigationItem.searchController = searchC
        let btnStackView: UIStackView = {
            let v = UIStackView.init(arrangedSubviews: [iCreateBtn, iJoinBtn])
            v.frame = CGRect.init(origin: .zero, size: CGSize.init(width: kScreenWidth, height: 44))
            v.axis = .horizontal
            v.distribution = .fillEqually
            return v
        }()
        
        tableView.tableHeaderView = btnStackView
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private let _viewModel = GroupListViewModel()
    private let _disposeBag = DisposeBag()
    private func bindData() {
        iCreateBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?._viewModel.isICreateTableSelected.accept(true)
        }).disposed(by: _disposeBag)
        
        iJoinBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?._viewModel.isICreateTableSelected.accept(false)
        }).disposed(by: _disposeBag)
        
        _viewModel.isICreateTableSelected
            .bind(to: iCreateBtn.rx.isSelected)
            .disposed(by: _disposeBag)
        
        _viewModel.isICreateTableSelected
            .map{!$0}
            .bind(to: iJoinBtn.rx.isSelected)
            .disposed(by: _disposeBag)
        
        _viewModel.items.bind(to: tableView.rx.items(cellIdentifier: FriendListUserTableViewCell.className, cellType: FriendListUserTableViewCell.self))  { (index, model, cell) in
            cell.titleLabel.text = model.groupName
            cell.subtitleLabel.text = "\(model.memberCount)人"
            cell.avatarImageView.setImage(with: model.faceURL, placeHolder: "contact_my_friend_icon")
        }.disposed(by: _disposeBag)
        
        _viewModel.myGroupsRelay
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] (groups) in
                self?.resultC.dataList = groups
        }).disposed(by: _disposeBag)
    }
}
