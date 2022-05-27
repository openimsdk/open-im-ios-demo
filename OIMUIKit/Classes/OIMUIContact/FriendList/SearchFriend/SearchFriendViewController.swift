





import UIKit
import RxSwift

class SearchFriendViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let resultC = SearchResultViewController.init(searchType: .user)
        let searchC: UISearchController = {
            let v = UISearchController.init(searchResultsController: resultC)
            v.searchResultsUpdater = resultC
            v.searchBar.placeholder = "通过用户ID号搜索添加"
            v.obscuresBackgroundDuringPresentation = false
            return v
        }()
        self.navigationItem.searchController = searchC
    }
}
