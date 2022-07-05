
import Kingfisher
import RxDataSources
import RxSwift
import UIKit

class NewFriendListViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "新的好友".innerLocalized()
        initView()
        bindData()
        _viewModel.getNewFriendApplications()
    }

    private lazy var tableView: UITableView = {
        let v = UITableView()
        v.register(NewFriendTableViewCell.self, forCellReuseIdentifier: NewFriendTableViewCell.className)
        v.delegate = self
        v.separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: StandardUI.margin_22)
        v.separatorColor = StandardUI.color_F1F1F1
        v.rowHeight = UITableView.automaticDimension
        v.tableFooterView = UIView()
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()

    private func initView() {
        let resultC = SearchResultViewController(searchType: .user)
        let searchC: UISearchController = {
            let v = UISearchController(searchResultsController: resultC)
            v.searchResultsUpdater = resultC
            v.searchBar.placeholder = "通过用户ID号搜索添加".innerLocalized()
            v.obscuresBackgroundDuringPresentation = false
            return v
        }()
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchC

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bindData() {
        _viewModel.applications.asDriver(onErrorJustReturn: []).drive(tableView.rx.items) { tableView, _, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: NewFriendTableViewCell.className) as! NewFriendTableViewCell
            cell.titleLabel.text = item.fromNickname
            cell.subtitleLabel.text = item.reqMsg
            if let state = NewFriendTableViewCell.ApplyState(rawValue: item.handleResult.rawValue) {
                cell.setApplyState(state)
            }

            cell.avatarImageView.setImage(with: item.fromFaceURL, placeHolder: "contact_my_friend_icon")

            cell.helloBtn.rx.tap.subscribe { _ in
                IMController.shared.getConversation(sessionType: ConversationType.c2c, sourceId: item.fromUserID) { [weak self] (conversation: ConversationInfo?) in
                    guard let conversation = conversation else { return }
                    let viewModel = MessageListViewModel(userId: item.fromUserID, conversation: conversation)
                    viewModel.sendText(text: "Hello", quoteMessage: nil)
                    let chatVC = MessageListViewController(viewModel: viewModel)
                    self?.navigationController?.pushViewController(chatVC, animated: true)
                }
            }.disposed(by: cell.disposeBag)

            cell.acceptBtn.rx.tap.subscribe { [weak self] _ in
                self?._viewModel.acceptFriendWith(uid: item.fromUserID)
            }.disposed(by: cell.disposeBag)

            return cell
        }.disposed(by: _disposeBag)

        tableView.rx.modelSelected(FriendApplication.self).subscribe(onNext: { (application: FriendApplication) in
            if let state = NewFriendTableViewCell.ApplyState(rawValue: application.handleResult.rawValue), state == .agreed {
                IMController.shared.getConversation(sessionType: ConversationType.c2c, sourceId: application.fromUserID, onSuccess: { [weak self] (conversation: ConversationInfo?) in
                    guard let conversation = conversation else { return }
                    let viewModel = MessageListViewModel(userId: application.fromUserID, conversation: conversation)
                    let chatVC = MessageListViewController(viewModel: viewModel)
                    self?.navigationController?.pushViewController(chatVC, animated: true)
                })
            }
        }).disposed(by: _disposeBag)
    }

    private let _viewModel = NewFriendListViewModel()
    private let _disposeBag = DisposeBag()
}

extension NewFriendListViewController: UITableViewDelegate {
    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let header = ViewUtil.createSectionHeaderWith(text: "新的好友请求".innerLocalized())
            return header
        }
        return nil
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 33
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
