//


//




import UIKit
import RxDataSources
import RxSwift
import Kingfisher

class NewFriendListViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "新的好友"
        initView()
        bindData()
        _viewModel.getNewFriendApplications()
    }
    
    private lazy var tableView: UITableView = {
        let v = UITableView()
        v.register(NewFriendTableViewCell.self, forCellReuseIdentifier: NewFriendTableViewCell.className)
        v.delegate = self
        v.separatorInset = UIEdgeInsets.init(top: 0, left: 82, bottom: 0, right: StandardUI.margin_22)
        v.separatorColor = StandardUI.color_F1F1F1
        v.rowHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()
    
    private func initView() {
        let resultC = SearchResultViewController.init(searchType: .user)
        let searchC: UISearchController = {
            let v = UISearchController.init(searchResultsController: resultC)
            v.searchResultsUpdater = resultC
            v.searchBar.placeholder = "通过用户ID号搜索添加"
            v.obscuresBackgroundDuringPresentation = false
            return v
        }()
        self.navigationItem.searchController = searchC
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func bindData() {
        _viewModel.applications.asDriver(onErrorJustReturn: []).drive(tableView.rx.items) { (tableView, row, item) in
            let cell = tableView.dequeueReusableCell(withIdentifier: NewFriendTableViewCell.className) as! NewFriendTableViewCell
            cell.titleLabel.text = item.fromNickname
            cell.subtitleLabel.text = item.reqMsg
            if let state = NewFriendTableViewCell.ApplyState.init(rawValue: item.handleResult.rawValue) {
                cell.setApplyState(state)
            }
            
            cell.avatarImageView.setImage(with: item.fromFaceURL, placeHolder: "contact_my_friend_icon")
            
            cell.helloBtn.rx.tap.subscribe { _ in
                print("给 \(String(describing: item.fromNickname)) 打了招呼")
            }.disposed(by: cell.disposeBag)
            
            cell.acceptBtn.rx.tap.subscribe { [weak self] _ in
                self?._viewModel.acceptFriendWith(uid: item.fromUserID)
            }.disposed(by: cell.disposeBag)

            return cell
        }.disposed(by: _disposeBag)
    }
    
    private let _viewModel = NewFriendListViewModel()
    private let _disposeBag = DisposeBag()

}

extension NewFriendListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let header = ViewUtil.createSectionHeaderWith(text: "新的好友请求")
            return header
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 33
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
