





import UIKit
import RxSwift

class SearchGroupViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let resultC = SearchResultViewController.init(searchType: .group)
        let searchC: UISearchController = {
            let v = UISearchController.init(searchResultsController: resultC)
            v.searchResultsUpdater = resultC
            v.searchBar.placeholder = "通过群ID号搜索添加"
            v.obscuresBackgroundDuringPresentation = false
            return v
        }()
        self.navigationItem.searchController = searchC
    }
}
