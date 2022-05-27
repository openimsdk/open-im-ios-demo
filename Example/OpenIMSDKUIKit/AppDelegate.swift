
import UIKit
import OIMUIKit
import Localize_Swift
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let _disposeBag = DisposeBag();
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        DemoPlugin.shared.setup(baseUrl: "http://121.37.25.71:10004/")
        IMController.shared.setup(apiAdrr: "http://121.37.25.71:10002", wsAddr: "ws://121.37.25.71:10001")
        
        NotificationCenter.default.rx.notification(NSNotification.Name(LCLLanguageChangeNotification), object: nil).subscribe(onNext: { [weak self] _ in
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
                    }

    func applicationWillEnterForeground(_ application: UIApplication) {
            }

    func applicationDidBecomeActive(_ application: UIApplication) {
            }

    func applicationWillTerminate(_ application: UIApplication) {
            }


}

