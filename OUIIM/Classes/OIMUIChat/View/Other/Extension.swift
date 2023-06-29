import Foundation
import UIKit

extension UIView {

    var isHiddenSafe: Bool {
        get {
            isHidden
        }
        set {
            guard isHidden != newValue else {
                return
            }
            isHidden = newValue
        }
    }

}

extension UIViewController {
    // https://github.com/ekazaev/route-composer can do it better
    func topMostViewController() -> UIViewController {
        if presentedViewController == nil {
            return self
        }
        if let navigationViewController = presentedViewController as? UINavigationController {
            if let visibleViewController = navigationViewController.visibleViewController {
                return visibleViewController.topMostViewController()
            } else {
                return navigationViewController
            }
        }
        if let tabBarViewController = presentedViewController as? UITabBarController {
            if let selectedViewController = tabBarViewController.selectedViewController {
                return selectedViewController.topMostViewController()
            }
            return tabBarViewController.topMostViewController()
        }
        return presentedViewController!.topMostViewController()
    }
}

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        UIApplication.shared.windows.filter(\.isKeyWindow).first?.rootViewController?.topMostViewController()
    }
}
