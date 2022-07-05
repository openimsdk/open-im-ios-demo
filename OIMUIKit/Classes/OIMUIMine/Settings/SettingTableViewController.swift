
import UIKit

class SettingTableViewController: UITableViewController {
    private let rowItems: [RowType] = RowType.allCases

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "账号设置".innerLocalized()
        configureTableView()
        initView()
    }

    private func configureTableView() {
        tableView.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        tableView.rowHeight = 60
    }

    private func initView() {}

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return rowItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType: RowType = rowItems[indexPath.row]
        switch rowType {
        case .language:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            return cell
        }
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
                return "语言".innerLocalized()
            }
        }
    }
}
