
import RxSwift
import OUICore

class GroupApplicationTableViewController: UITableViewController {
    private let _viewModel = GroupApplicationViewModel()
    private let _disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "入群申请".innerLocalized()
        tableView.register(GroupApplicationTableViewCell.self, forCellReuseIdentifier: GroupApplicationTableViewCell.className)
        tableView.dataSource = nil
        tableView.backgroundColor = .viewBackgroundColor
        
        bindData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _viewModel.getGroupApplications()
    }

    private func bindData() {
        _viewModel.applicationItems
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items) { (tableView, _, item: GroupApplicationInfo) in
                let cell = tableView.dequeueReusableCell(withIdentifier: GroupApplicationTableViewCell.className) as! GroupApplicationTableViewCell
                cell.nameLabel.text = item.nickname
                if let reason = item.reqMsg {
                    cell.setApply(reason: reason)
                }
                if let groupName = item.groupName {
                    cell.setCompanyName(groupName)
                }

                if let state = GroupApplicationTableViewCell.ApplyState(rawValue: item.handleResult.rawValue) {
                    cell.setApplyState(state)
                }
                cell.avatarView.setAvatar(url: item.groupFaceURL, text: item.groupName)
                cell.agreeBtn.rx.tap.subscribe { [weak self] _ in
                    if let uid = item.userID {
                        let vc = ApplicationViewController(groupApplication: item, friendApplication: nil)
                        self?.navigationController?.pushViewController(vc, animated: true)
                    }
                }.disposed(by: cell.disposeBag)
                return cell
            }.disposed(by: _disposeBag)
    }
}
