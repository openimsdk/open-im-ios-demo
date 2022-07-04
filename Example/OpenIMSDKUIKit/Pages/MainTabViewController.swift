
import UIKit
import OIMUIKit
import RxSwift
import RxCocoa
import SVProgressHUD
import Localize_Swift
import OpenIMSDK

class MainTabViewController: UITabBarController {
    private let _disposeBag = DisposeBag()
    private let imUidKey = "DemoIMUidKey"
    private let imTokenKey = "DemoIMTokenKey"
    private lazy var _viewModel = LoginViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()
        var controllers: [UIViewController] = []
        
        let chatNav = UINavigationController.init(rootViewController: ChatListViewController())
        chatNav.tabBarItem.title = "OpenIM"
        chatNav.tabBarItem.image = UIImage.init(named: "tab_home_icon_normal")?.withRenderingMode(.alwaysOriginal)
        chatNav.tabBarItem.selectedImage = UIImage.init(named: "tab_home_icon_selected")?.withRenderingMode(.alwaysOriginal)
        controllers.append(chatNav)
        IMController.shared.totalUnreadSubject.map({ (unread: Int) -> String? in
            var badge: String?
            if unread == 0 {
                badge = nil
            } else if unread > 99 {
                badge = "..."
            } else {
                badge = String(unread)
            }
            return badge
        }).bind(to: chatNav.tabBarItem.rx.badgeValue).disposed(by: _disposeBag)
        
        let contactVC = ContactsViewController()
        contactVC.viewModel.dataSource = self
        let contactNav = UINavigationController.init(rootViewController: contactVC)
        contactNav.tabBarItem.title = "通讯录".localized()
        contactNav.tabBarItem.image = UIImage.init(named: "tab_contact_icon_normal")?.withRenderingMode(.alwaysOriginal)
        contactNav.tabBarItem.selectedImage = UIImage.init(named: "tab_contact_icon_selected")?.withRenderingMode(.alwaysOriginal)
        controllers.append(contactNav)
        IMController.shared.contactUnreadSubject.map({ (unread: Int) -> String? in
            var badge: String?
            if unread == 0 {
                badge = nil
            } else {
                badge = String(unread)
            }
            return badge
        }).bind(to: contactNav.tabBarItem.rx.badgeValue).disposed(by: _disposeBag)
        
        let mineNav = UINavigationController.init(rootViewController: MineViewController())
        mineNav.tabBarItem.title = "我的".localized()
        mineNav.tabBarItem.image = UIImage.init(named: "tab_me_icon_normal")?.withRenderingMode(.alwaysOriginal)
        mineNav.tabBarItem.selectedImage = UIImage.init(named: "tab_me_icon_selected")?.withRenderingMode(.alwaysOriginal)
        controllers.append(mineNav)
        
        self.viewControllers = controllers
        self.tabBar.isTranslucent = false
        self.tabBar.backgroundColor = .white;
        
        self.tabBar.layer.shadowColor = UIColor.black.cgColor;
        self.tabBar.layer.shadowOpacity = 0.08;
        self.tabBar.layer.shadowOffset = CGSize.init(width: 0, height: 0);
        self.tabBar.layer.shadowRadius = 5;

        self.tabBar.backgroundImage = UIImage.init()
        self.tabBar.shadowImage = UIImage.init()
        
        if let uid = UserDefaults.standard.object(forKey: imUidKey) as? String, let token = UserDefaults.standard.object(forKey: imTokenKey) as? String {
            SVProgressHUD.show()
            loginIM(uid: uid, token: token, completion: nil)
        } else {
            DispatchQueue.main.async {
                self.presentLoginController()
            }
        }
        
        JNNotificationCenter.shared.observeEvent { [weak self] (event: OIMUIKit.EventLogout) in
            self?.save(uid: nil, token: nil)
            self?.presentLoginController()
        }.disposed(by: _disposeBag)
    }
    
    private func presentLoginController() {
        let vc = LoginViewController()
        vc.loginBtn.rx.tap.subscribe(onNext: { [weak vc, weak self] in
            guard let controller = vc, let sself = self else { return }
            guard let phone = controller.phone, let pwd = controller.password else { return }
            
            SVProgressHUD.show()
            self?._viewModel.loginDemo(phone: phone, pwd: pwd).subscribe(onNext: { (response: LoginViewModel.Response?) in
                    guard let resp = response else { return }
                    self?.loginIM(uid: resp.data.userID, token: resp.data.token, completion: { [weak controller] in
                        controller?.dismiss(animated: true)
                    })
                }, onError: { err in
                    SVProgressHUD.showError(withStatus: err.localizedDescription)
                }).disposed(by: sself._disposeBag)
        }).disposed(by: _disposeBag)
        
        vc.modalPresentationStyle = .fullScreen
        
        self.present(vc, animated: true)
    }
    
    private func loginIM(uid: String, token: String, completion: (() -> Void)?) {
        IMController.shared.login(uid: uid, token: token) { [weak self] (resp2: String?) in
            print("login onSuccess \(String(describing: resp2))")
            JPUSHService.setAlias(uid, completion: { code, msg, code2 in
                print("别名设置成功：", code, msg ?? "no message", code2)
            }, seq: 0)
            self?.save(uid: uid, token: token)
            SVProgressHUD.dismiss()
            completion?()
        } onFail: { [weak self] (code: Int, msg: String?) in
            let reason = "login onFail: code \(code), reason \(String(describing: msg))"
            SVProgressHUD.showError(withStatus: reason)
            self?.save(uid: nil, token: nil)
            self?.presentLoginController()
        }
    }
    
    private func save(uid: String?, token: String?) {
        UserDefaults.standard.set(uid, forKey: imUidKey)
        UserDefaults.standard.set(token, forKey: imTokenKey)
        UserDefaults.standard.synchronize()
    }
}

extension MainTabViewController: ContactsDataSource {
    func getFrequentUsers() -> [OIMUserInfo] {
        return []
    }
    
    func setFrequentUsers(_ users: [OIMUserInfo]) {
        
    }
}
