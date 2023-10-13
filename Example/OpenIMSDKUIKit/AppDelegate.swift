
import OUICore
import Localize_Swift
import RxSwift
//import GTSDK

let kGtAppId = ""
let kGtAppKey = ""
let kGtAppSecret = ""

//The domain name used by default
let defaultHost = "14.29.213.197"

// The default IP or domain name used in the settings page. After the settings page is saved, defaultHost will become invalid.
let defaultIP = "127.0.0.1"
let defaultDomain = "web.rentsoft.cn"

let businessPort = ":10008"
let businessRoute = "/chat"

let adminPort = ":10009"
let adminRoute = "/complete_admin"
let sdkAPIPort = ":10002"
let sdkAPIRoute = "/api"
let sdkWSPort = ":10001"
let sdkWSRoute = "/msg_gateway"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    var window: UIWindow?
    private let _disposeBag = DisposeBag();
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UINavigationBar.appearance().tintColor = .c0C1C33
        // Main configuration here, pay attention to the differences between http and https, ws and wss, IP uses port, domain name uses routing
        let enableTLS = UserDefaults.standard.object(forKey: useTLSKey) == nil
        ? false : UserDefaults.standard.bool(forKey: useTLSKey)
        
        let httpScheme = enableTLS ? "https://" : "http://"
        let wsScheme = enableTLS  ? "wss://" : "ws://"
        
//        let predicateStr = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
//        let predicate = NSPredicate(format: "SELF MATCHES %@", predicateStr)
//        let isIP = predicate.evaluate(with: defaultHost)
        
        let enableDomain = UserDefaults.standard.object(forKey: useDomainKey) == nil
        ? false : UserDefaults.standard.bool(forKey: useDomainKey)
        
        let serverAddress = UserDefaults.standard.string(forKey: serverAddressKey) ?? defaultHost
        
        // Set and retrieve global configuration
        UserDefaults.standard.setValue(httpScheme + serverAddress + (!enableDomain ? adminPort : adminRoute), forKey: adminServerAddrKey)

        // Set login, registration, and more - AccountViewModel
        UserDefaults.standard.setValue(httpScheme + serverAddress + (!enableDomain ? businessPort: businessRoute), forKey: bussinessServerAddrKey)

        // Set SDK API address
        let sdkAPIAddress = UserDefaults.standard.string(forKey: sdkAPIAddrKey) ??
        httpScheme + serverAddress + (!enableDomain ? sdkAPIPort : sdkAPIRoute)

        // Set WebSocket address
        let sdkWebSocketAddress = UserDefaults.standard.string(forKey: sdkWSAddrKey) ??
        wsScheme + serverAddress + (!enableDomain ? sdkWSPort : sdkWSRoute)

        // Set object storage
        let sdkObjectStorage = UserDefaults.standard.string(forKey: sdkObjectStorageKey) ??
        "minio"

        // Initialize the SDK
        IMController.shared.setup(sdkAPIAdrr: sdkAPIAddress,
                                  sdkWSAddr: sdkWebSocketAddress,
                                  sdkOS: sdkObjectStorage) {
            IMController.shared.currentUserRelay.accept(nil)
            AccountViewModel.saveUser(uid: nil, imToken: nil, chatToken: nil)
            NotificationCenter.default.post(name: .init("logout"), object: nil)
        }
        
//        GeTuiSdk.start(withAppId: kGtAppId, appKey: kGtAppKey, appSecret: kGtAppSecret, delegate: self)
//        GeTuiSdk.registerRemoteNotification([.alert, .badge, .sound])
    
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
    
    // MARK: - GeTuiSdkDelegate
    func geTuiSdkDidRegisterClient(_ clientId: String) {
        let msg = "[ TestDemo ] \(#function):\(clientId)"
        print(msg)
    }
    
    func geTuiSdkDidOccurError(_ error: Error) {
        let msg = "[ TestDemo ] \(#function) \(error.localizedDescription)"
        print(msg)
    }
    
    func getuiSdkGrantAuthorization(_ granted: Bool, error: Error?) {
        let msg = "[ TestDemo ] \(#function) \(granted ? "Granted":"NO Granted")"
        print(msg)
    }
    
    @available(iOS 10.0, *)
    func geTuiSdkNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .sound, .alert])
    }
    
    @available(iOS 10.0, *)
    func geTuiSdkDidReceiveNotification(_ userInfo: [AnyHashable : Any], notificationCenter center: UNUserNotificationCenter?, response: UNNotificationResponse?, fetchCompletionHandler completionHandler: ((UIBackgroundFetchResult) -> Void)? = nil) {
        completionHandler?(.noData)
    }
    
    func pushLocalNotification(_ title: String, _ userInfo:[AnyHashable:Any]) {
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = title
            let req = UNNotificationRequest.init(identifier: "id1", content: content, trigger: nil)
            
            UNUserNotificationCenter.current().add(req) { _ in
                print("addNotificationRequest added")
            }
        }
    }
    
    func geTuiSdkDidReceiveSlience(_ userInfo: [AnyHashable : Any], fromGetui: Bool, offLine: Bool, appId: String?, taskId: String?, msgId: String?, fetchCompletionHandler completionHandler: ((UIBackgroundFetchResult) -> Void)? = nil) {
        var dic: [AnyHashable : Any] = [:]
        if fromGetui {
            
            dic = ["_gmid_":"\(String(describing: taskId)):\(String(describing: msgId))"]
        } else {
            //APNs静默通知
            dic = userInfo;
        }
        if fromGetui && !offLine {
            pushLocalNotification(userInfo["payload"] as! String, dic)
        }
    }
    
    @available(iOS 10.0, *)
    func geTuiSdkNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
    }
    
    func geTuiSdkDidSendMessage(_ messageId: String, result: Int32) {
        let msg = "[ TestDemo ] \(#function) \(String(describing: messageId)), result=\(result)"
        print(msg)
    }
    
    func geTuiSdkDidAliasAction(_ action: String, result isSuccess: Bool, sequenceNum aSn: String, error aError: Error?) {
    }
    
    
    //MARK: - 标签设置
    func geTuiSdkDidSetTagsAction(_ sequenceNum: String, result isSuccess: Bool, error aError: Error?) {
        
        let msg = "[ TestDemo ] \(#function)  sequenceNum:\(sequenceNum) isSuccess:\(isSuccess) error: \(String(describing: aError))"
        
        print(msg)
    }
}

