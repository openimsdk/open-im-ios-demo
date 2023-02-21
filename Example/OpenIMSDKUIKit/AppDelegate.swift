
import UIKit
import OIMUIKit
import Localize_Swift
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    var window: UIWindow?
    private let _disposeBag = DisposeBag();
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                
        // 主要配置这里，注意http 与 https、 ws 与 wss之分，IP 用端口， 域名用路由
        let defaultHost = "web.rentsoft.cn" // 填入host
        let enableTLS = true   // host是否有tls
        
        
        let httpScheme = enableTLS ? "https://" : "http://"
        let wsScheme = enableTLS ? "wss://" : "ws://"
        
        let predicateStr = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", predicateStr)
        let isIP = predicate.evaluate(with: defaultHost)
        
        
        // -------设置各种base url-------
        
        
        let severAddress = UserDefaults.standard.string(forKey: severAddressKey) ?? defaultHost
        
        // 设置获取全局配置
        UserDefaults.standard.setValue(httpScheme + severAddress + (isIP ? ":10009" : "/complete_admin"), forKey: adminSeverAddrKey)
        
        // 设置登录注册等 - AccountViewModel
        UserDefaults.standard.setValue(httpScheme + severAddress + (isIP ? ":10008" : "/chat"), forKey: bussinessSeverAddrKey)
        
        // 设置sdk接口地址
        let sdkAPIAddr = UserDefaults.standard.string(forKey: sdkAPIAddrKey) ??
        httpScheme + severAddress + (isIP ? ":10002" : "/api")
        
        // 设置ws地址
        let sdkWSAddr = UserDefaults.standard.string(forKey: sdkWSAddrKey) ??
        wsScheme + severAddress + (isIP ? ":10001" : "/msg_gateway")
        
        // 设置对象存储
        let sdkObjectStorage = UserDefaults.standard.string(forKey: sdkObjectStorageKey) ??
        "minio"
        
        // 初始化SDK
        // 注意http + ws 与 https + wss 的区别
        IMController.shared.setup(apiAdrr: sdkAPIAddr,
                                  wsAddr: sdkWSAddr,
                                  os: sdkObjectStorage)
        AccountViewModel.getClientConfig()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
                    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "taskname", expirationHandler: {

            if (self.backgroundTaskIdentifier != .invalid) {
                UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!);
                self.backgroundTaskIdentifier = .invalid;
              }
           });
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!);
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("did Fail To Register For Remote Notifications With Error: %@", error)
    }
    
}

