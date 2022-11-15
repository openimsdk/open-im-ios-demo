
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
        
        let ud = UserDefaults.standard
        
        // 初始化SDK
        // 注意http + ws 与 https + wss 的区别
        IMController.shared.setup(apiAdrr: ud.string(forKey: sdkAPIAddrKey) ??
                                  "https://web.rentsoft.cn/api",
                                  wsAddr:ud.string(forKey: sdkWSAddrKey) ??
                                  "wss://web.rentsoft.cn/msg_gateway",
                                  os: ud.string(forKey: sdkObjectStorageKey) ??
                                  "minio")
        
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

