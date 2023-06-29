

import OUICore

public class FriendListResultViewController: UIViewController, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate {
    
    private let userPrefix = ":user_"
    
    public var dataList: [UserInfo] = [] {
        didSet {
            for user in dataList {
                if let ret: [WPFPerson] = WPFPinYinDataManager.getInitializedDataSource() as? [WPFPerson] {
                    if !ret.contains(where: { (item: WPFPerson) in
                        item.personId == user.userID
                    }) {
                        WPFPinYinDataManager.addInitializeString(user.nickname, identifer: userPrefix + user.userID)
                    }
                } else {
                    WPFPinYinDataManager.addInitializeString(user.nickname, identifer: userPrefix + user.userID)
                }
            }
        }
    }
        
    public var selectUserCallBack: ((String) -> Void)?
    public var didScrollCallback: (()->Void)?

    private var searchArr: [WPFPerson] = []

    private lazy var tableView: UITableView = {
        let v = UITableView()
        v.register(FriendListUserTableViewCell.self, forCellReuseIdentifier: FriendListUserTableViewCell.className)
        v.dataSource = self
        v.delegate = self
        v.separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: StandardUI.margin_22)
        v.separatorColor = StandardUI.color_F1F1F1
        v.rowHeight = UITableView.automaticDimension
        v.tableFooterView = UIView()
        
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
        for person in arr {
            
            if !person.personId.hasPrefix(userPrefix) {
                continue
            }
            
            if let result = WPFPinYinTools.searchEffectiveResult(withSearch: keyword, person: person) {
                if result.highlightedRange.length > 0 {
                    person.highlightLoaction = result.highlightedRange.location
                    person.textRange = result.highlightedRange
                    person.matchType = Int(result.matchType.rawValue)
                    searchArr.append(person)
                }
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
        let highLightColor = UIColor.blue
        attString.addAttribute(NSAttributedString.Key.foregroundColor, value: highLightColor, range: person.textRange)
        cell.titleLabel.attributedText = attString
        if let user = dataList.first { person.personId.contains($0.userID) } {
            cell.avatarImageView.setAvatar(url: user.faceURL, text: user.nickname, onTap: nil)
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userInfo: WPFPerson = searchArr[indexPath.row]
        selectUserCallBack?(String(userInfo.personId.split(separator: "_").last!))
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScrollCallback?()
    }

    deinit {
        print("dealloc \(type(of: self))")
    }
}
