





import UIKit
import Localize_Swift

class LanguageTableViewController: UITableViewController {
    
    private let rowItems: [RowType] = RowType.allCases
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "语言设置".innerLocalized()
        configureTableView()
        tableView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let lan = Localize.currentLanguage()
            for (index, item) in self.rowItems.enumerated() {
                if item.rawValue == lan {
                    self.tableView.selectRow(at: IndexPath.init(row: index, section: 0), animated: true, scrollPosition: .none)
                }
            }
            if self.tableView.indexPathForSelectedRow == nil {
                self.tableView.selectRow(at: IndexPath.init(row: 0, section: 0), animated: true, scrollPosition: .none)
            }
        }
    }
    
    private func configureTableView() {
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = false
        tableView.register(CheckBoxTextTableViewCell.self, forCellReuseIdentifier: CheckBoxTextTableViewCell.className)
        tableView.rowHeight = 60
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType: RowType = rowItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: CheckBoxTextTableViewCell.className) as! CheckBoxTextTableViewCell
        cell.titleLabel.text = rowType.title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType: RowType = rowItems[indexPath.row]
        switch rowType {
        case .system:
            Localize.resetCurrentLanguageToDefault()
        case .chineseSimplified:
            Localize.setCurrentLanguage(rowType.rawValue)
        case .english:
            Localize.setCurrentLanguage(rowType.rawValue)
        }
    }
    
    enum RowType: String, CaseIterable {
        case system
        case chineseSimplified = "zh-Hans"
        case english = "en"
        
        var title: String {
            switch self {
            case .system:
                return "跟随系统".innerLocalized()
            case .chineseSimplified:
                return "简体中文".innerLocalized()
            case .english:
                return "英文".innerLocalized()
            }
        }
    }
}
