
import OUIIM
import OUICore
import OpenIMSDK
import RxSwift
import RxCocoa
import ProgressHUD
import Localize_Swift
import MJExtension
import GTSDK

#if ENABLE_CALL
import OUICalling
#endif

private let signupuserKey = "signupuserKey"

class MainTabViewController: UITabBarController {
    
    func clearConversation() {
        conversationViewController.clearRecord()
    }
    
    private let _disposeBag = DisposeBag()
    var lastTabBarItemTag: Int = 0
    var lastTabBarItemSelectedTime: Date?
    private let conversationViewController = ChatListViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var controllers: [UIViewController] = []
        
        let chatNav = NavigationController.init(rootViewController: conversationViewController)
        chatNav.tabBarItem.image = UIImage.init(named: "tab_home_icon_normal")?.withRenderingMode(.alwaysOriginal)
        chatNav.tabBarItem.selectedImage = UIImage.init(named: "tab_home_icon_selected")?.withRenderingMode(.alwaysOriginal)
        controllers.append(chatNav)
        IMController.shared.totalUnreadSubject.map({ (unread: Int) -> String? in
            var badge: String?
            if unread == 0 {
                badge = nil
            } else if unread > 99 {
                badge = "99+"
            } else {
                badge = String(unread)
            }
            return badge
        }).bind(to: chatNav.tabBarItem.rx.badgeValue).disposed(by: _disposeBag)
        
        let contactVC = ContactsViewController()
        let contactNav = NavigationController.init(rootViewController: contactVC)
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
        
        let disconveryVC = DiscoveryViewController()
        let disconveryNav = UINavigationController.init(rootViewController: disconveryVC)
        disconveryNav.tabBarItem.image = UIImage.init(named: "tab_discovery_icon_normal")?.withRenderingMode(.alwaysOriginal)
        disconveryNav.tabBarItem.selectedImage = UIImage.init(named: "tab_discovery_icon_selected")?.withRenderingMode(.alwaysOriginal)
        controllers.append(disconveryNav)

        let mineNav = UINavigationController.init(rootViewController: MineViewController())
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
        delegate = self
        
        setText()
        NotificationCenter.default.addObserver(self, selector: #selector(setText), name: NSNotification.Name(LCLLanguageChangeNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(logout), name: .init("logout"), object: nil)
        
        loginExsitAccount()
    }
    
    @objc
    private func setText() {
        viewControllers?[0].tabBarItem.title = "OpenIM"
        viewControllers?[1].tabBarItem.title = "通讯录".localized()
        viewControllers?[2].tabBarItem.title = "发现".localized()
        viewControllers?[3].tabBarItem.title = "我的".localized()
    }
    
    private func loginExsitAccount() {
        IMController.shared.currentUserRelay.subscribe(onNext: { r in
            guard let r else { return }
            
            let p = ["userID": r.userID, "nickname": r.nickname, "faceURL": r.faceURL]

            if let json = try? JSONSerialization.data(withJSONObject: p, options: .fragmentsAllowed) {
                UserDefaults.standard.set(json, forKey: signupuserKey)
                UserDefaults.standard.synchronize()
            }
        }).disposed(by: _disposeBag)
        
        if let uid = UserDefaults.standard.object(forKey: AccountViewModel.IMUidKey) as? String,
           let token = UserDefaults.standard.object(forKey: AccountViewModel.IMTokenKey) as? String,
           let chatToken = UserDefaults.standard.object(forKey: AccountViewModel.bussinessTokenKey) as? String {
            
            if let u = UserDefaults.standard.object(forKey: signupuserKey) as? String, let user = JsonTool.fromJson(u, toClass: UserInfo.self) {
                conversationViewController.refreshUserInfo(userInfo: user)
            }
            AccountViewModel.loginIM(uid: uid, imToken: token, chatToken: chatToken) {[weak self] (errCode, errMsg) in

                if errMsg != nil {
                    ProgressHUD.error( errMsg)
                    self?.presentLoginController()
                } else {
                    self?.loginSuccess()
                }
            }
        } else {
            DispatchQueue.main.async {
                self.presentLoginController()
            }
        }
    }
    
    @objc private func logout() {
#if ENABLE_CALL
        OUICalling.CallingManager.manager.end()
        OUICalling.CallingManager.manager.forceDismiss()
#endif
#if ENABLE_LIVE_ROOM
        OUILive.LiveRoomViewController.forceDismiss()
#endif
        IMController.shared.currentUserRelay.accept(nil)
        AccountViewModel.saveUser(uid: nil, imToken: nil, chatToken: nil)
        presentLoginController()
    }
    
    private func presentLoginController() {
        self.selectedIndex = 0
        viewControllers?.first?.tabBarItem.badgeValue = nil
        if let viewControllers, viewControllers.count > 1 {
            self.viewControllers?[1].tabBarItem.badgeValue = nil
            viewControllers.forEach({ $0.navigationController?.popToRootViewController(animated: false) })
        }
        pushBindAlias(false)
        let vc = LoginViewController()
        vc.loginBtn.rx.tap.subscribe(onNext: { [weak vc, weak self] in
            guard let controller = vc, let phone = controller.phone, !phone.isEmpty else { return }
            
            guard let phone = controller.phone, !phone.isEmpty else {
                if vc?.loginType == .phone {
                    ProgressHUD.error( "填写正确的手机号码".localized())
                } else {
                    ProgressHUD.error( "填写正确的邮箱".localized())
                }
                return
            }
            
            let psw = controller.password
            let code = controller.verificationCode
            
            guard psw?.isEmpty == false || code?.isEmpty == false else {
                ProgressHUD.error( "填写正确的密码/验证码")
                return
            }

            ProgressHUD.animate()
            let curAccount = vc?.loginType == .phone ? phone : nil
            let preAccount = AccountViewModel.perLoginAccount
            
            if curAccount != preAccount {
                self?.clearConversation()
            }
            
            AccountViewModel.loginDemo(phone: vc?.loginType == .phone ? phone : nil,
                                       account: vc?.loginType == .account ? phone : nil,
                                       email: vc?.loginType == .email ? phone : nil,
                                       psw: code != nil ? nil : psw,
                                       verificationCode: code,
                                       areaCode: controller.areaCode) {[weak self] (errCode, errMsg) in
                if errMsg != nil {
                    ProgressHUD.error(errCode == -1 ? errMsg : String(errCode).localized())
                    self?.presentLoginController()
                } else {
                    UserDefaults.standard.setValue(vc?.loginType.rawValue, forKey: loginTypeKey)
                    UserDefaults.standard.synchronize()
                    self?.loginSuccess(dismiss: true)
                }
            }
        }).disposed(by: _disposeBag)
        
        vc.modalPresentationStyle = .fullScreen
        let nav = UINavigationController.init(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        
        self.present(nav, animated: false)
    }
    
    func loginSuccess(dismiss: Bool = false) {
        let event = EventLoginSucceed()
        JNNotificationCenter.shared.post(event)
        
#if ENABLE_CALL
            CallingManager.manager.start()
#endif
        
        IMController.shared.getSelfInfo { [self] r in
            guard let r else { return }
            
            let p = JsonTool.toJson(fromObject: r)
            UserDefaults.standard.set(p, forKey: signupuserKey)
            UserDefaults.standard.synchronize()
       
            conversationViewController.refreshUserInfo(userInfo: r)
            
            ProgressHUD.dismiss()
            
            if dismiss {
                self.dismiss(animated: true)
            }
        }
        
        pushBindAlias()
    }
    
    func pushBindAlias(_ bind: Bool = true) {
        if let userID = AccountViewModel.userID {
            bind ? GeTuiSdk.bindAlias(userID, andSequenceNum: "im") : GeTuiSdk.unbindAlias(userID, andSequenceNum: "im", andIsSelf: true)
        }
    }
}

extension MainTabViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let currentTabBarItemTag = tabBarController.selectedIndex

        if currentTabBarItemTag == lastTabBarItemTag {
            let currentTime = Date()
            if let lastSelectedTime = lastTabBarItemSelectedTime,
               currentTime.timeIntervalSince(lastSelectedTime) < 0.3 {
                conversationViewController.scrollToUnreadItem()
            }
        }

        lastTabBarItemTag = currentTabBarItemTag
        lastTabBarItemSelectedTime = Date()
        
        if let nav = viewController as? UINavigationController, nav.topViewController is ChatListViewController {
            conversationViewController.tapTab = true
        }
        
        return true
    }
}
