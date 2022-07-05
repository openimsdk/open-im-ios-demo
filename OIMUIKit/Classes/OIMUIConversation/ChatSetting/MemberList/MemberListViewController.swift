
import RxSwift
import UIKit

class MemberListViewController: UIViewController {
    private lazy var _tableView: UITableView = {
        let v = UITableView()
        let config = SCIndexViewConfiguration(indexViewStyle: SCIndexViewStyle.default)!
        config.indexItemRightMargin = 8
        config.indexItemTextColor = UIColor(hexString: "#555555")
        config.indexItemSelectedBackgroundColor = UIColor(hexString: "#57be6a")
        config.indexItemsSpace = 4
        v.sc_indexViewConfiguration = config
        v.sc_translucentForTableViewInNavigationBar = true
        v.register(FriendListUserTableViewCell.self, forCellReuseIdentifier: FriendListUserTableViewCell.className)
        v.dataSource = self
        v.delegate = self
        v.rowHeight = UITableView.automaticDimension
        v.separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: StandardUI.margin_22)
        v.separatorColor = StandardUI.color_F1F1F1
        let refresh: UIRefreshControl = {
            let v = UIRefreshControl(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
            v.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self, weak v] in
                self?._viewModel.getMoreMembers()
                v?.endRefreshing()
            }).disposed(by: _disposeBag)
            return v
        }()
        v.refreshControl = refresh
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()

    private let _viewModel: MemberListViewModel
    private let _disposeBag = DisposeBag()
    private lazy var resultC = FriendListResultViewController()

    init(viewModel: MemberListViewModel) {
        _viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "群成员".innerLocalized()
        initView()
        bindData()
        _viewModel.getMemberList()
    }

    private func initView() {
        let searchC: UISearchController = {
            let v = UISearchController(searchResultsController: resultC)
            v.searchResultsUpdater = resultC
            v.searchBar.placeholder = "搜索成员".innerLocalized()
            v.obscuresBackgroundDuringPresentation = false
            return v
        }()
        navigationItem.searchController = searchC

        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bindData() {
        _viewModel.lettersRelay.distinctUntilChanged().subscribe(onNext: { [weak self] (values: [String]) in
            guard let sself = self else { return }
            self?.resultC.dataList = sself._viewModel.members.compactMap {
                let item = UserInfo()
                item.nickname = $0.nickname
                item.faceURL = $0.faceURL
                return item
            }
            self?._tableView.sc_indexViewDataSource = values
            self?._tableView.sc_startSection = 0
            self?._tableView.reloadData()
        }).disposed(by: _disposeBag)
    }

    deinit {
        print("dealloc \(type(of: self))")
    }
}

extension MemberListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in _: UITableView) -> Int {
        return _viewModel.lettersRelay.value.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _viewModel.contactSections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FriendListUserTableViewCell.className) as! FriendListUserTableViewCell
        let user: GroupMemberInfo = _viewModel.contactSections[indexPath.section][indexPath.row]
        cell.titleLabel.text = user.nickname
        cell.avatarImageView.setImage(with: user.faceURL, placeHolder: "contact_my_friend_icon")
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let member: GroupMemberInfo = _viewModel.contactSections[indexPath.section][indexPath.row]
        let vc = UserDetailTableViewController(userId: member.userID ?? "", groupId: member.groupID)
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let name = _viewModel.lettersRelay.value[section]
        let header = ViewUtil.createSectionHeaderWith(text: name)
        return header
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 33
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
