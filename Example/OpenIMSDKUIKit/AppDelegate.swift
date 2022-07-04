
import UIKit
import OIMUIKit
import Localize_Swift
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let _disposeBag = DisposeBag();
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 初始化SDK
        IMController.shared.setup(apiAdrr: "http://121.37.25.71:10002",
                                  wsAddr: "ws://121.37.25.71:10001")
        
        let pushConfig: JPUSHRegisterEntity = {
            let v = JPUSHRegisterEntity.init()
            if #available(iOS 12.0, *) {
                v.types = Int(JPAuthorizationOptions.alert.rawValue | JPAuthorizationOptions.sound.rawValue | JPAuthorizationOptions.badge.rawValue | JPAuthorizationOptions.providesAppNotificationSettings.rawValue)
            } else {
                v.types = Int(JPAuthorizationOptions.alert.rawValue | JPAuthorizationOptions.sound.rawValue | JPAuthorizationOptions.badge.rawValue)
            }
            return v
        }()
        JPUSHService.register(forRemoteNotificationConfig: pushConfig, delegate: self)
        let isProduction: Bool
        #if DEBUG
        isProduction = false
        #else
        isProduction = true
        #endif
        JPUSHService.setup(withOption: launchOptions, appKey: "cf47465a368f24c659608e7e", channel: "developer-default", apsForProduction: isProduction)
        
        NotificationCenter.default.rx.notification(NSNotification.Name(LCLLanguageChangeNotification), object: nil).subscribe(onNext: { [weak self] _ in
            print("应用语言已切换")
            DispatchQueue.main.async {
                let root = MainTabViewController()
                let window = UIWindow.init()
                window.rootViewController = root
                self?.window = window
                window.makeKeyAndVisible()
            }
        }).disposed(by: _disposeBag)
        
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
        JPUSHService.registerDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("did Fail To Register For Remote Notifications With Error: %@", error)
    }

}

extension AppDelegate: JPUSHRegisterDelegate {
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, willPresent notification: UNNotification!, withCompletionHandler completionHandler: ((Int) -> Void)!) {
        let userInfo = notification.request.content.userInfo
        JPUSHService.handleRemoteNotification(userInfo)
        completionHandler(Int(UNNotificationPresentationOptions.badge.rawValue | UNNotificationPresentationOptions.sound.rawValue | UNNotificationPresentationOptions.alert.rawValue))
    }
    
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, didReceive response: UNNotificationResponse!, withCompletionHandler completionHandler: (() -> Void)!) {
        let userInfo = response.notification.request.content.userInfo
        JPUSHService.handleRemoteNotification(userInfo)
        completionHandler()
    }
    
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, openSettingsFor notification: UNNotification!) {
        let title: String
        if (notification != nil) {
            title = "从通知界面直接进入应用";
        }else{
            title = "从系统设置界面进入应用";
        }
        print(title)
    }
    
    func jpushNotificationAuthorization(_ status: JPAuthorizationStatus, withInfo info: [AnyHashable : Any]!) {
        print("receive notification authorization status:%lu", status)
    }
}
