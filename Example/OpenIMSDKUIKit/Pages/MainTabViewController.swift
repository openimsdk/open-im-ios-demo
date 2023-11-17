
import OUIIM
import OUICore
import OpenIMSDK
import RxSwift
import RxCocoa
import ProgressHUD
import Localize_Swift
import MJExtension
//import GTSDK

class MainTabViewController: UITabBarController {
    private let _disposeBag = DisposeBag()
    
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
                badge = "99+"
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
        
        if let uid = UserDefaults.standard.object(forKey: AccountViewModel.IMUidKey) as? String,
           let token = UserDefaults.standard.object(forKey: AccountViewModel.IMTokenKey) as? String,
           let chatToken = UserDefaults.standard.object(forKey: AccountViewModel.bussinessTokenKey) as? String {
            ProgressHUD.animate()
            AccountViewModel.loginIM(uid: uid, imToken: token, chatToken: chatToken) {[weak self] (errCode, errMsg) in
                if errMsg != nil {
                    ProgressHUD.error(errMsg)
                    self?.presentLoginController()
                } else {
                    self?.pushBindAlias()
                    ProgressHUD.dismiss()
                }
            }
        } else {
            DispatchQueue.main.async {
                self.presentLoginController()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(presentLoginController), name: .init("logout"), object: nil)
    }
    
    @objc private func presentLoginController() {
        self.selectedIndex = 0
        pushBindAlias(false)
        let vc = LoginViewController()
        vc.loginBtn.rx.tap.subscribe(onNext: { [weak vc, weak self] in
            guard let controller = vc, let phone = controller.phone, !phone.isEmpty else { return }
            
            guard let phone = controller.phone, !phone.isEmpty else {
                ProgressHUD.error("填写正确的手机号码")
                return
            }
            
            let psw = controller.password
            let code = controller.verificationCode
            
            guard psw?.isEmpty == false || code?.isEmpty == false else {
                ProgressHUD.error("填写正确的密码/验证码")
                return
            }
            var account: String?

            ProgressHUD.animate()
            AccountViewModel.loginDemo(phone: phone,
                                       account: account,
                                       psw: code != nil ? nil : psw,
                                       verificationCode: code,
                                       areaCode: controller.areaCode) {[weak self] (errCode, errMsg) in
                if errMsg != nil {
                    ProgressHUD.error(errMsg)
                    self?.presentLoginController()
                } else {
                    self?.pushBindAlias()
                    ProgressHUD.dismiss()
                    self?.dismiss(animated: true)
                }
            }
        }).disposed(by: _disposeBag)
        
        vc.modalPresentationStyle = .fullScreen
        let nav = UINavigationController.init(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        
        self.present(nav, animated: false)
    }
    
    func pushBindAlias(_ bind: Bool = true) {
        if let userID = AccountViewModel.userID {
//            bind ? GeTuiSdk.bindAlias(userID, andSequenceNum: "im") : GeTuiSdk.unbindAlias(userID, andSequenceNum: "im", andIsSelf: true)
        }
    }
}

extension MainTabViewController: ContactsDataSource {
    func getFrequentUsers() -> [OIMUserInfo] {
        guard let uid = AccountViewModel.userID else { return [] }
        guard let usersJson = UserDefaults.standard.object(forKey: uid) as? String else { return [] }
        
        guard let users = JsonTool.fromJson(usersJson, toClass: [UserEntity].self) else {
            return []
        }
        let current = Int(Date().timeIntervalSince1970)
        let oUsers: [OIMUserInfo] = users.compactMap { (user: UserEntity) in
            if current - user.savedTime <= 7 * 24 * 3600 {
                return user.toOIMUserInfo()
            }
            return nil
        }
        return oUsers
    }
    
    func setFrequentUsers(_ users: [OIMUserInfo]) {
        guard let uid = AccountViewModel.userID else { return }
        let saveTime = Int(Date().timeIntervalSince1970)
        let before = getFrequentUsers()
        var mUsers: [OIMUserInfo] = before
        mUsers.append(contentsOf: users)
        let ret = mUsers.deduplicate(filter: {$0.userID})
        
        let uEntities: [UserEntity] = ret.compactMap { (user: OIMUserInfo) in
            var uEntity = UserEntity.init(user: user)
            uEntity.savedTime = saveTime
            return uEntity
        }
        let json = JsonTool.toJson(fromObject: uEntities)
        UserDefaults.standard.setValue(json, forKey: uid)
        UserDefaults.standard.synchronize()
    }
    
    struct UserEntity: Codable {
        var userID: String?
        var nickname: String?
        var faceURL: String?
        var savedTime: Int = 0
        
        init(user: OIMUserInfo) {
            self.userID = user.userID
            nickname = user.nickname
            faceURL = user.faceURL
        }
        
        func toOIMUserInfo() -> OIMUserInfo {
            let item = OIMUserInfo.init()
            item.userID = userID
            item.nickname = nickname
            item.faceURL = faceURL
            return item
        }
    }
}
