
import RxSwift
import UIKit

class GroupApplicationTableViewController: UITableViewController {
    private let _viewModel = GroupApplicationViewModel()
    private let _disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "入群申请".innerLocalized()
        tableView.register(GroupApplicationTableViewCell.self, forCellReuseIdentifier: GroupApplicationTableViewCell.className)
        tableView.separatorColor = StandardUI.color_F1F1F1
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 18)
        tableView.dataSource = nil
        bindData()
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

                cell.avatarImageView.setImage(with: item.groupFaceURL, placeHolder: "contact_my_friend_icon")
                cell.agreeBtn.rx.tap.subscribe { [weak self] _ in
                    if let uid = item.userID {
                        self?._viewModel.acceptApplicationWith(groupId: item.groupID, fromUserId: uid)
                    }
                }.disposed(by: cell.disposeBag)
                return cell
            }.disposed(by: _disposeBag)
    }
}
