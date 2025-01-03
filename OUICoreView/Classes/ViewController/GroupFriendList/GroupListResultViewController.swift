
import OUICore

public class GroupListResultViewController: UIViewController, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate {
    private let groupPrefix = ":group_"
    
    public var dataList: [GroupInfo] = [] {
        didSet {
            for group in dataList {
                if let ret: [WPFPerson] = WPFPinYinDataManager.getInitializedDataSource() as? [WPFPerson] {
                    if !ret.contains(where: { (item: WPFPerson) in
                        item.personId == group.groupID
                    }) {
                        WPFPinYinDataManager.addInitializeString(group.groupName, identifer: groupPrefix + group.groupID)
                    }
                } else {
                    WPFPinYinDataManager.addInitializeString(group.groupName, identifer: groupPrefix + group.groupID)
                }
            }
        }
    }

    public var selectUserCallBack: ((String) -> Void)?
    private var searchArr: [WPFPerson] = []

    private lazy var tableView: UITableView = {
        let v = UITableView()
        v.register(FriendListUserTableViewCell.self, forCellReuseIdentifier: FriendListUserTableViewCell.className)
        v.dataSource = self
        v.delegate = self
        v.separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: StandardUI.margin_22)
        v.separatorColor = .sepratorColor
        v.rowHeight = UITableView.automaticDimension
        v.keyboardDismissMode = .onDrag
        
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public func updateSearchResults(for searchController: UISearchController) {
        searchArr.removeAll()
        guard let keyword = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        guard let arr = WPFPinYinDataManager.getInitializedDataSource() as? [WPFPerson] else { return }
        let userIDResult = dataList.filter({ $0.groupID.contains(keyword) })

        for person in arr {
            
            if !person.personId.hasPrefix(groupPrefix) {
                continue
            }
            
            let result = WPFPinYinTools.searchEffectiveResult(withSearch: keyword, person: person)
            
            if let result {
                if result.highlightedRange.length > 0 {
                    person.highlightLoaction = result.highlightedRange.location
                    person.textRange = result.highlightedRange
                    person.matchType = Int(result.matchType.rawValue)
                    searchArr.append(person)
                }
            }
        }
        
        userIDResult.forEach { group in
            let p = searchArr.first(where: { $0.personId == group.groupID })
    
            if p == nil, let wp = WPFPerson(id: group.groupID, name: group.groupName, hanyuPinyinOutputFormat: HanyuPinyinOutputFormat()) {
                if let range = group.groupID.range(of: keyword) {
                    let start = range.lowerBound
                    let end = range.upperBound
                    wp.textRange = NSRange(start..<end, in: group.groupID)
                }
                wp.matchType = 9
                searchArr.append(wp)
            }
        }
        
        let change = searchArr
        searchArr = change.sorted { lhs, rhs in
            lhs.matchType < rhs.matchType
        }.sorted { lhs, rhs in
            lhs.highlightLoaction < rhs.highlightLoaction
        }

        tableView.reloadData()
    }

    public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return searchArr.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FriendListUserTableViewCell.className, for: indexPath) as! FriendListUserTableViewCell
        let person = searchArr[indexPath.row]
        let attString = NSMutableAttributedString(string: person.name)
        if person.matchType == 0 {
            let highLightColor = UIColor.blue
            attString.addAttribute(NSAttributedString.Key.foregroundColor, value: highLightColor, range: person.textRange)
        }
        cell.titleLabel.attributedText = attString
        
        let subAttString = NSMutableAttributedString(string: String(person.personId.split(separator: "_").last!))
        if person.matchType == 9 {
            let highLightColor = UIColor.blue
            subAttString.addAttribute(NSAttributedString.Key.foregroundColor, value: highLightColor, range: person.textRange)
        }
        cell.subtitleLabel.attributedText = subAttString
        
        if let group = dataList.first{ person.personId.contains($0.groupID) } {
            cell.avatarImageView.setAvatar(url: group.faceURL, text: group.groupName, onTap: nil)
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let person = searchArr[indexPath.row]
        selectUserCallBack?(String(person.personId.split(separator: "_").last!))
    }

    deinit {
        print("dealloc \(type(of: self))")
    }
}
