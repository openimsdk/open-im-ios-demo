
import Foundation
import UIKit
import OUICore
import RxSwift
import ProgressHUD

class SearchContactsViewController: UIViewController {
    
    var dataList: [ContactInfo] = [] {
        didSet {
            WPFPinYinDataManager.shareInstance().clearDataSource()
            
            for user in dataList {
                WPFPinYinDataManager.addInitializeString(user.name, sub: user.sub, identifer: user.ID)
            }
        }
    }
    
    var sourceID: String?
    
    var viewModel: SelectContactsViewModel {
        set {
            _viewModel = newValue
        }
        
        get {
            _viewModel
        }
    }
    
    private var _viewModel = SelectContactsViewModel()
    
    var selectedUsers: [ContactInfo] = []
    
    var removeUsersCallback: (([ContactInfo]) -> Void)!
    var selectedCallback: ((_ allowsMultipleSelection: Bool, _ friends: [ContactInfo]) -> Void)!
    var removeUsers: [ContactInfo] = []
    
    private var enableChangeSelectedModel = false
    var allowsMultipleSelection = true
    private var preSearchText: String?
    private var types: [ContactType] = []
    
    public init(types: [ContactType] = [.friends, .groups, .staff], 
                enableChangeSelectedModel: Bool = false,
                allowsMultipleSelection: Bool = true,
                selectedCallback: @escaping (_ allowsMultipleSelection: Bool, _ friends: [ContactInfo]) -> Void,
                removeCallback: @escaping ([ContactInfo]) -> Void) {
        super.init(nibName: nil, bundle: nil)
        self.types = types
        self.removeUsersCallback = removeCallback
        self.selectedCallback = selectedCallback
        self.enableChangeSelectedModel = enableChangeSelectedModel
        self.allowsMultipleSelection = enableChangeSelectedModel ? false : allowsMultipleSelection
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("\(type(of: self)) - \(#function)")
    }
    
    private var searchArr: [WPFPerson] = []
    
    private lazy var tableView: UITableView = {
        let v = UITableView()
        v.register(SelectUserTableViewCell.self, forCellReuseIdentifier: SelectUserTableViewCell.className)
        v.dataSource = self
        v.delegate = self
        v.separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: StandardUI.margin_22)
        v.separatorColor = .sepratorColor
        v.rowHeight = 60
        v.allowsMultipleSelection = true
        v.backgroundColor = .clear
        v.keyboardDismissMode = .onDrag
        
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        
        return v
    }()
    
    lazy var searchController: UISearchController = {
        let v = UISearchController(searchResultsController: nil)
        v.hidesNavigationBarDuringPresentation = false
        v.dimsBackgroundDuringPresentation = false
        v.searchBar.searchBarStyle = .prominent
        v.searchBar.sizeToFit()

        v.automaticallyShowsCancelButton = false
        v.hidesNavigationBarDuringPresentation = false
        v.searchBar.delegate = self
        
        return v
    }()
    
    private var resultVC: SelectContactsResultViewController!
    private let _disposeBag: DisposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBackgroundColor
        
        if enableChangeSelectedModel {
            let tipsLabel = UILabel()
            tipsLabel.text = "searchResult".innerLocalized()
            tipsLabel.font = .f14
            tipsLabel.textColor = .c8E9AB0
            
            let changeButton = UIButton(type: .custom)
            changeButton.setTitle("menuMulti".innerLocalized(), for: .normal)
            changeButton.setTitle("endMulti".innerLocalized(), for: .selected)
            changeButton.setTitleColor(.c0089FF, for: .normal)
            changeButton.titleLabel?.font = .f14
            
            changeButton.rx.tap.subscribe(onNext: { [weak self] _ in
                changeButton.isSelected = !changeButton.isSelected
                self?.allowsMultipleSelection = changeButton.isSelected
                
                if !changeButton.isSelected {
                    self?.navigationController?.popViewController(animated: true)
                } else {
                    self?.tableView.reloadData()
                }
            }).disposed(by: _disposeBag)
            
            let hStack = UIStackView(arrangedSubviews: [tipsLabel, UIView(), changeButton])
            
            let hBackground = UIView()
            hBackground.backgroundColor = .systemBackground
            
            hBackground.addSubview(hStack)
            hStack.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                make.top.bottom.equalToSuperview()
            }
            
            let vStack = UIStackView(arrangedSubviews: [hBackground, tableView])
            vStack.axis = .vertical
            
            view.addSubview(vStack)
            vStack.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            }
        } else {
            view.addSubview(tableView)
            tableView.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            }
        }
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        _viewModel.searchResult.subscribe(onNext: { [weak self] r in
            self?.dataList = r
            self?.updateSearchResults(text: self?.searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines))
            ProgressHUD.dismiss()
        }).disposed(by: _disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async { [self] in
            searchController.searchBar.becomeFirstResponder()
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
}










extension SearchContactsViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let keyword = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            ProgressHUD.animate()
            _viewModel.search(keyword: keyword, type: types, sourceID: sourceID)
        }
    }
}

extension SearchContactsViewController: UITableViewDelegate, UITableViewDataSource {
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
        
        cell.showSelectedIcon = allowsMultipleSelection
        
        if let user = dataList.first(where: { $0.ID == person.personId }) {
            cell.avatarImageView.setAvatar(url: user.faceURL, text: user.name)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let person = searchArr[indexPath.row]
        
        if selectedUsers.contains(where: { $0.ID == person.personId }) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let person = searchArr[indexPath.row]
        
        if let user = dataList.first { $0.ID == person.personId } {
            if !selectedUsers.contains(where: { $0.ID == user.ID }) {
                selectedUsers.append(user)
            }
            selectedCallback(allowsMultipleSelection, [user])
        }
    }
    
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let person = searchArr[indexPath.row]
        
        if let user = dataList.first { $0.ID == person.personId } {
            selectedUsers.removeAll(where: { $0.ID == user.ID })
            removeUsersCallback([user])
        }
    }
}
