
import OUICore

public class SelectContactsResultViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
     var dataList: [ContactInfo] = [] {
        didSet {
            for user in dataList {
                if let ret: [WPFPerson] = WPFPinYinDataManager.getInitializedDataSource() as? [WPFPerson] {
                    if !ret.contains(where: { (item: WPFPerson) in
                        item.personId == user.ID
                    }) {
                        WPFPinYinDataManager.addInitializeString(user.name, sub: user.sub, identifer: user.ID)
                    }
                } else {
                    WPFPinYinDataManager.addInitializeString(user.name, sub: user.sub, identifer: user.ID)
                }
            }
        }
    }
    
    var selectedUsers: [ContactInfo] = []
    
    var removeUsersCallback: (([ContactInfo]) -> Void)!
    var selectedCallback: (([ContactInfo]) -> Void)!
    var removeUsers: [ContactInfo] = []
    
    public init(selectedCallback: @escaping ([ContactInfo]) -> Void, removeCallback: @escaping ([ContactInfo]) -> Void) {
        super.init(nibName: nil, bundle: nil)
        self.removeUsersCallback = removeCallback
        self.selectedCallback = selectedCallback
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var searchArr: [WPFPerson] = []

    private lazy var tableView: UITableView = {
        let v = UITableView()
        v.register(SelectUserTableViewCell.self, forCellReuseIdentifier: SelectUserTableViewCell.className)
        v.dataSource = self
        v.delegate = self
        v.separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: StandardUI.margin_22)
        v.separatorColor = StandardUI.color_F1F1F1
        v.rowHeight = UITableView.automaticDimension
        v.allowsMultipleSelection = true
        v.backgroundColor = .clear
        
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }

        return v
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public func updateSearchResults(text: String?) {
        searchArr.removeAll()
        guard let keyword = text else { return }
        guard let arr = WPFPinYinDataManager.getInitializedDataSource() as? [WPFPerson] else { return }
        for person in arr {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectUserTableViewCell.className, for: indexPath) as! SelectUserTableViewCell
        let person = searchArr[indexPath.row]
        let attString = NSMutableAttributedString(string: person.name)
        let highLightColor = UIColor.blue
        attString.addAttribute(NSAttributedString.Key.foregroundColor, value: highLightColor, range: person.textRange)
        cell.titleLabel.attributedText = attString
        cell.subtitleLabel.text = person.sub
        
        if let user = dataList.first(where: { $0.ID == person.personId }) {
            cell.avatarImageView.setAvatar(url: user.faceURL, text: user.name)
        }
        
        if selectedUsers.contains(where: { $0.ID == person.personId }) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("select")
        let person = searchArr[indexPath.row]
        let user = dataList.first { $0.ID == person.personId }
        if user != nil {
            selectedCallback([user!])
        }
    }
    
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let person = searchArr[indexPath.row]
        let user = dataList.first { $0.ID == person.personId }
        if user != nil {
            removeUsersCallback([user!])
        }
    }

    deinit {
        print("dealloc \(type(of: self))")
    }
}
