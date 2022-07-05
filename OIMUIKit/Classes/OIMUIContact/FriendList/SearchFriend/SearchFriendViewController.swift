
import RxSwift
import UIKit

class SearchFriendViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let resultC = SearchResultViewController(searchType: .user)
        let searchC: UISearchController = {
            let v = UISearchController(searchResultsController: resultC)
            v.searchResultsUpdater = resultC
            v.searchBar.placeholder = "通过用户ID号搜索添加"
            v.obscuresBackgroundDuringPresentation = false
            return v
        }()
        navigationItem.searchController = searchC
    }
}
