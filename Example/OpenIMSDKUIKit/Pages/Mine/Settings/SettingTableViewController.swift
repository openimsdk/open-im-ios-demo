
import OUICore
import RxSwift
import ProgressHUD

class SettingTableViewController: UITableViewController {
    let _disposeBag = DisposeBag()
    
    private let _viewModel = SettingViewModel()
    private let rowItems: [[RowType]] = [
        [.blocked],
        [.clearHistory]
    ]
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "账号设置".innerLocalized()
        configureTableView()
        bindData()
        initView()
        _viewModel.getSettingInfo()
    }

    private func configureTableView() {
        
        tableView.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.className)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.className)
        tableView.tableFooterView = UIView()
    }

    private func initView() {
        view.backgroundColor = .viewBackgroundColor
    }
    
    private func bindData() {
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return rowItems.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowItems[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType: RowType = rowItems[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
        
        switch rowType {
        case .blocked:
            cell.titleLabel.text = rowType.title
        case .clearHistory:
            cell.titleLabel.text = rowType.title
            cell.titleLabel.textColor = .cFF381F
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        16
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        UIView()
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType: RowType = rowItems[indexPath.section][indexPath.row]
        switch rowType {
        case .blocked:
            let vc = BlockedListViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .clearHistory:
            presentAlert(title: "您确定要清空聊天记录吗？".innerLocalized()) {
                ProgressHUD.animate("请等待...".innerLocalized())
                self._viewModel.clearHistory { res in
                    ProgressHUD.success("清空完成".innerLocalized())
                }
            }
        }
    }

    enum RowType: CaseIterable {
        case blocked
        case clearHistory
        
        var title: String {
            switch self {
            case .blocked:
                return "通讯录黑名单".innerLocalized()
            case .clearHistory:
                return "清空聊天记录"
            }
        
        }
    }
}
