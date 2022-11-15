
import UIKit
import RxSwift
import OIMUIKit

class SettingTableViewController: UITableViewController {
    let _disposeBag = DisposeBag()
    
    private let _viewModel = SettingViewModel()
    private let rowItems: [RowType] = RowType.allCases
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "账号设置"
        configureTableView()
        bindData()
        initView()
    }

    private func configureTableView() {
        tableView.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)

        tableView.rowHeight = 60
        tableView.tableFooterView = UIView()
    }

    private func initView() {}
    
    private func bindData() {
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return rowItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType: RowType = rowItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
        
        switch rowType {
        case .language:
            cell.titleLabel.text = rowType.title
        }
        
        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType: RowType = rowItems[indexPath.row]
        switch rowType {
        case .language:
            let vc = LanguageTableViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    enum RowType: CaseIterable {
        case language
        
        var title: String {
            switch self {
            case .language:
                return "语言".localized()
            }
        
        }
    }
}
