
import RxSwift
import OUICore

class SearchFriendViewController: UIViewController {
    
    var didSelectedItem: ((_ userID: String) -> Void)?
    
    var searchC: UISearchController!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let resultC = SearchResultViewController(searchType: .user)
        searchC = {
            let v = UISearchController(searchResultsController: resultC)
            v.searchResultsUpdater = resultC
            v.searchBar.placeholder = "通过用户ID号/手机号/邮箱/昵称搜索添加".innerLocalized()
            return v
        }()
        definesPresentationContext = true
        navigationItem.searchController = searchC
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchC.isActive = true
    }
}
