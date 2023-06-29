
import RxSwift
import OUICore
import OUICoreView

class SearchFriendViewController: UIViewController {
    
    var didSelectedItem: ((_ ID: String) -> Void)?
    
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
        resultC.didSelectedItem = didSelectedItem
    }
}
