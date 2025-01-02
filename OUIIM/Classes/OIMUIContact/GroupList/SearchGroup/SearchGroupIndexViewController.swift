
import OUICore
import RxSwift
import SnapKit
import ProgressHUD
import OUICoreView

class SearchGroupIndexViewController: UIViewController {
        
    var didSelectedItem: ((_ ID: String) -> Void)?
    
    private let disposeBag = DisposeBag()
    
    private lazy var searchBar: UISearchBar = {
        let v = UISearchBar()
        v.rx.textDidBeginEditing.subscribe(onNext: { [weak self] _ in
            v.searchTextField.resignFirstResponder()
            
            let vc = SearchGroupViewController()
            vc.didSelectedItem = self?.didSelectedItem
            
            self?.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: disposeBag)
        
        return v
    }()
    
    private lazy var scanQrcodeView: ListTileView = {
        let v = ListTileView()
        v.imageView.image = UIImage(nameInBundle: "common_scan_qrcode_icon_blue")
        v.titleLabel.text = "scanQrcode".innerLocalized()
        v.subTitleLabel.text = "scanHint".innerLocalized()
        
        v.onTap = { [weak self] in
            let vc = ScanViewController()
            vc.scanDidComplete = { [weak self] (result: String) in
                if result.contains(IMController.addFriendPrefix) {
                    self?.navigationController?.popViewController(animated: false)

                    let uid = result.replacingOccurrences(of: IMController.addFriendPrefix, with: "")
                    let vc = UserDetailTableViewController(userId: uid, groupId: nil)
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                } else if result.contains(IMController.joinGroupPrefix) {
                    self?.navigationController?.popViewController(animated: false)

                    let groupID = result.replacingOccurrences(of: IMController.joinGroupPrefix, with: "")
                    let vc = GroupDetailViewController(groupId: groupID)
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                } else {
                    ProgressHUD.error("unrecognized".innerLocalized())
                    self?.navigationController?.popViewController(animated: true)
                }
            }
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupSubviews()
    }
    
    private func setupSubviews() {
        let vStack = UIStackView(arrangedSubviews: [searchBar, scanQrcodeView])
        vStack.axis = .vertical
        vStack.spacing = 8
        
        view.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
    }
}

