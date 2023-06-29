import UIKit
import OUICore
import OUICoreView

public typealias SelectedContactsHandler = (([ContactInfo]) -> Void)

class MyContactsViewController: UIViewController {
    
    var selectedHandler: SelectedContactsHandler?
    
    private lazy var tableView: UITableView = {
        let v = UITableView(frame: .zero, style: .grouped)
        v.dataSource = self
        v.delegate = self
        v.rowHeight = 60
        v.translatesAutoresizingMaskIntoConstraints = false
        
        v.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        v.register(FriendListUserTableViewCell.self, forCellReuseIdentifier: FriendListUserTableViewCell.className)
        
        return v
    }()
    
    private let rows: [Section: [Row]] = [
        .normal: [.friends, .group],
        .frequent: []
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    fileprivate enum Section: Int, CaseIterable {
        case normal = 0
        case frequent = 1
        
        var title: String {
            switch self {
            case .normal:
                return ""
            case .frequent:
                return "最近会话".innerLocalized()
            }
        }
    }
    
    fileprivate enum Row: Int, CaseIterable {
        case friends
        case group
        
        var title: String {
            switch self {
            case .friends:
                return "我的好友".innerLocalized()
            case .group:
                return "我的群聊".innerLocalized()
                
            }
        }
    }
}

extension MyContactsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        rows.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows[Section(rawValue: section)!]!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[Section(rawValue: indexPath.section)!]![indexPath.row]
        
        if indexPath.section == Section.normal.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className, for: indexPath) as! OptionTableViewCell
            
            cell.titleLabel.text = row.title
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: FriendListUserTableViewCell.className, for: indexPath) as! FrequentUserTableViewCell
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        30
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = Section(rawValue: section)
        
        let label = UILabel()
        label.text = "  " + section!.title
        label.textColor = .c8E9AB0
        label.font = .f12
        
        return label
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = rows[Section(rawValue: indexPath.section)!]![indexPath.row]
        
        if indexPath.section == Section.normal.rawValue {
            switch row {
            case .friends:
                let vc = SelectContactsViewController(types: [.friends])
                vc.selectedContact { [weak self] infos in
                    self?.selectedHandler?(infos)
                    self?.navigationController?.popViewController(animated: true)
                }

                navigationController?.pushViewController(vc, animated: true)
            case .group:
                let vc = SelectContactsViewController(types: [.groups])
                vc.selectedContact { [weak self] infos in
                    self?.selectedHandler?(infos)
                    self?.navigationController?.popViewController(animated: true)
                }
                
                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            
        }
    }
}
