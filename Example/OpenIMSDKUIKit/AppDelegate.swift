
import UIKit
import OIMUIKit
import Localize_Swift
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let _disposeBag = DisposeBag();
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let ud = UserDefaults.standard
        
        // 初始化SDK
        IMController.shared.setup(apiAdrr:ud.string(forKey: sdkAPIAddrKey) ??
                                  "https://open-im-online.rentsoft.cn:50002",
                                  wsAddr:ud.string(forKey: sdkWSAddrKey) ??
                                  "wss://open-im-online.rentsoft.cn:50001",
                                  os: ud.string(forKey: sdkObjectStorageKey) ??
                                  "minio")
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
                    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
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

