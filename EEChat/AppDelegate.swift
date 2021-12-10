//
//  AppDelegate.swift
//  EEChat
//
//  Created by Snow on 2021/6/10.
//

import UIKit
import RxSwift
//import OpenIM
import OpenIMUI
import IQKeyboardManagerSwift
import Bugly

@main
class AppDelegate: UIResponder, UIApplicationDelegate, JPUSHRegisterDelegate {
    
    lazy var window: UIWindow? = {
        let window = UIWindow()
        window.backgroundColor = .white
        window.makeKeyAndVisible()
        return window
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Logger.debugMode = .verbose
        
        OUIKit.shared.initSDK()
        OUIKit.shared.messageDelegate = MessageModule.shared
        configBugly()
        configKeyboard()
        configQMUIKit()
        
        UIViewController.initHook()
        
        PushManager.shared.launchOptions(launchOptions)
        
        _ = Observable.merge(
            NotificationCenter.default.rx.notification(AccountManager.loginNotification),
            NotificationCenter.default.rx.notification(AccountManager.logoutNotification)
        )
        .map { (_) -> Bool in
            return AccountManager.shared.isLogin()
        }
        .startWith(AccountManager.shared.isLogin())
        .subscribe(onNext: { (isLogin) in
            let vc = isLogin ? MainTabBarController() : LoginVC.vc()
            self.window?.rootViewController = UINavigationController(rootViewController: vc)
        })
        
        checkUpdate()
        
        if #available(iOS 10, *) {
              let entity = JPUSHRegisterEntity()
              entity.types = NSInteger(UNAuthorizationOptions.alert.rawValue) |
                NSInteger(UNAuthorizationOptions.sound.rawValue) |
                NSInteger(UNAuthorizationOptions.badge.rawValue)
              JPUSHService.register(forRemoteNotificationConfig: entity, delegate: self)
              
            } else if #available(iOS 8, *) {
              // 可以自定义 categories
              JPUSHService.register(
                forRemoteNotificationTypes: UIUserNotificationType.badge.rawValue |
                  UIUserNotificationType.sound.rawValue |
                  UIUserNotificationType.alert.rawValue,
                categories: nil)
            } else {
              // ios 8 以前 categories 必须为nil
              JPUSHService.register(
                forRemoteNotificationTypes: UIRemoteNotificationType.badge.rawValue |
                  UIRemoteNotificationType.sound.rawValue |
                  UIRemoteNotificationType.alert.rawValue,
                categories: nil)
            }
        
            #if DEBUG // DEBUG || BETA
                JPUSHService.setup(withOption: launchOptions, appKey: "cf47465a368f24c659608e7e", channel: "channel", apsForProduction: false)
            #elseif
                JPUSHService.setup(withOption: launchOptions, appKey: "cf47465a368f24c659608e7e", channel: "channel", apsForProduction: true)
            #endif
            
            _ = NotificationCenter.default
        
        return true
    }
    
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, openSettingsFor notification: UNNotification!) {
        let userInfo = notification.request.content.userInfo
        if(notification.request.trigger?.isKind(of: UNPushNotificationTrigger.self)==true) {
            JPUSHService.handleRemoteNotification(userInfo)
        }
        //completionHandler(UNNotificationPresentationOptionAlert);
    }
    
    @available(iOS 10.0, *)
      func jpushNotificationCenter(_ center: UNUserNotificationCenter!, didReceive response: UNNotificationResponse!, withCompletionHandler completionHandler: (() -> Void)!) {

    //    let userInfo = response.notification.request.content.userInfo
    //    let request = response.notification.request // 收到推送的请求
    //    let content = request.content // 收到推送的消息内容
    //
    //    let badge = content.badge // 推送消息的角标
    //    let body = content.body   // 推送消息体
    //    let sound = content.sound // 推送消息的声音
    //    let subtitle = content.subtitle // 推送消息的副标题
    //    let title = content.title // 推送消息的标题
          let userInfo = response.notification.request.content.userInfo
          if(response.notification.request.trigger?.isKind(of: UNPushNotificationTrigger.self)==true) {
              JPUSHService.handleRemoteNotification(userInfo)
          }
          completionHandler()
      }
      
      @available(iOS 10.0, *)
      func jpushNotificationCenter(_ center: UNUserNotificationCenter!, willPresent notification: UNNotification!,
                                   withCompletionHandler completionHandler: ((Int) -> Void)!) {
    //    let userInfo = notification.request.content.userInfo
    //
    //    let request = notification.request // 收到推送的请求
    //    let content = request.content // 收到推送的消息内容
    //
    //    let badge = content.badge // 推送消息的角标
    //    let body = content.body   // 推送消息体
    //    let sound = content.sound // 推送消息的声音
    //    let subtitle = content.subtitle // 推送消息的副标题
    //    let title = content.title // 推送消息的标题
          let userInfo = notification.request.content.userInfo
          if(notification.request.trigger?.isKind(of: UNPushNotificationTrigger.self)==true) {
              JPUSHService.handleRemoteNotification(userInfo)
          }
          completionHandler(Int(UNNotificationPresentationOptions.alert.rawValue))
      }
      
      func applicationWillResignActive(_ application: UIApplication) {
        
      }
      
      func applicationDidEnterBackground(_ application: UIApplication) {
        
      }
      
      func applicationWillEnterForeground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        application.cancelAllLocalNotifications()
      }
      
      func applicationDidBecomeActive(_ application: UIApplication) {
        
      }
      
      func applicationWillTerminate(_ application: UIApplication) {
        
      }
      
      func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
          JPUSHService.registerDeviceToken(deviceToken)
      }
      
      func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
          print("did fail to register for remote notification with error ", error)
      }
      
      func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        JPUSHService.handleRemoteNotification(userInfo)
      }
      
      func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        JPUSHService.showLocalNotification(atFront: notification, identifierKey: nil)
      }
      
      @available(iOS 7, *)
      func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        
      }
      
      @available(iOS 7, *)
      func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
        
      }
      
      @available(iOS 7, *)
      func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable: Any], withResponseInfo responseInfo: [AnyHashable: Any], completionHandler: @escaping () -> Void) {
        
      }

}

extension AppDelegate {
    private func configKeyboard() {
        let keyboardManager = IQKeyboardManager.shared
        
        keyboardManager.enable = true
        keyboardManager.shouldResignOnTouchOutside = true
        keyboardManager.keyboardDistanceFromTextField = 64

        keyboardManager.enableAutoToolbar = false
        keyboardManager.toolbarManageBehaviour = .byPosition
        keyboardManager.shouldShowToolbarPlaceholder = true

        let classes: [UIViewController.Type] = [
            EEChatVC.self,
            IMConversationViewController.self,
            IMInputViewController.self,
            IMMessageViewController.self,
        ]
        keyboardManager.disabledDistanceHandlingClasses.append(contentsOf: classes)
        keyboardManager.disabledToolbarClasses.append(contentsOf: classes)
        keyboardManager.disabledTouchResignedClasses.append(contentsOf: classes)
    }
    
    private func configQMUIKit() {
        guard let instance = QMUIConfiguration.sharedInstance() else {
            return
        }
        instance.sendAnalyticsToQMUITeam = false
        instance.shouldPrintDefaultLog = false
        instance.shouldPrintInfoLog = false
        instance.shouldPrintWarnLog = false
        instance.shouldPrintQMUIWarnLogToConsole = false
        instance.applyInitialTemplate()
    }
    
    func configBugly() {
        Bugly.start(withAppId: "21ae582b11")
    }
    
    func checkUpdate() {
        #if BETA // DEBUG || BETA
        PgyUpdateManager.sharedPgy().start(withAppId: "8823db48e4d89ab039a00b25dc14f9e5")
        DispatchQueue.main.async {
            PgyUpdateManager.sharedPgy().checkUpdate()
        }
        #endif
    }
}
