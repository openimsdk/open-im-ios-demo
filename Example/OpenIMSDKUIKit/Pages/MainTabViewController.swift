
import UIKit
import OIMUIKit
import RxSwift
import SVProgressHUD

class MainTabViewController: UITabBarController {
    private let _disposeBag = DisposeBag()
    private let imUidKey = "DemoIMUidKey"
    private let imTokenKey = "DemoIMTokenKey"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var controllers: [UIViewController] = []
        
        let chatNav = UINavigationController.init(rootViewController: ChatListViewController())
        chatNav.tabBarItem.title = "OpenIM"
        chatNav.tabBarItem.image = UIImage.init(named: "tab_home_icon_normal")?.withRenderingMode(.alwaysOriginal)
        chatNav.tabBarItem.selectedImage = UIImage.init(named: "tab_home_icon_selected")?.withRenderingMode(.alwaysOriginal)
        controllers.append(chatNav)
        
        let nav = UINavigationController.init(rootViewController: ContactsViewController())
        nav.tabBarItem.title = "通讯录"
        nav.tabBarItem.image = UIImage.init(named: "tab_contact_icon_normal")?.withRenderingMode(.alwaysOriginal)
        nav.tabBarItem.selectedImage = UIImage.init(named: "tab_contact_icon_selected")?.withRenderingMode(.alwaysOriginal)
        controllers.append(nav)
        
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
            loginIM(uid: uid, token: token, completion: nil)
        } else {
            DispatchQueue.main.async {
                self.presentLoginController()
            }
        }
    }
    
    private func presentLoginController() {
        let vc = LoginViewController()
        vc.loginBtn.rx.tap.subscribe(onNext: { [weak vc, weak self] in
            guard let controller = vc, let sself = self else { return }
            guard let phone = controller.phone, let pwd = controller.password else { return }
            
            SVProgressHUD.show()
            LoginAPI.init(req: .init(phoneNumber: phone, pwd: pwd)).send()
                .subscribe(onNext: { (api: LoginAPI) in
                    guard let resp = api.response else { return }
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
            
            self?.save(uid: uid, token: token)
            SVProgressHUD.dismiss()
            completion?()
        } onFail: { (code: Int, msg: String?) in
            let reason = "login onFail: code \(code), reason \(String(describing: msg))"
            SVProgressHUD.showError(withStatus: reason)
        }
    }
    
    private func save(uid: String, token: String) {
        UserDefaults.standard.set(uid, forKey: imUidKey)
        UserDefaults.standard.set(token, forKey: imTokenKey)
        UserDefaults.standard.synchronize()
    }
}
