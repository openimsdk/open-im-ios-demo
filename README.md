<img src="https://openim-1253691595.cos.ap-nanjing.myqcloud.com/WechatIMG20.jpeg" alt="image" style="width: 200px; " />

# Open-IM-iOS-Demo: 

OpenIM Messaging Client for [OpenIM](https://github.com/OpenIMSDK/Open-IM-Server) in Swift.

### Demo content
Demo is a set of UI components implemented based on Open-IM SDK, which includes functions such as conversation, chat, relationship chain, group, etc. Based on UI components, you can quickly build your own business logic.
Please use the latest v3 version of the server.

### Direct testflight download app experience

<img src="https://github.com/OpenIMSDK/OpenIM-Docs/blob/main/docs/images/ios_native.png" alt="image" style="width: 200px; " />

### Source code experience

1. Development environment requirements
     Xcode 14 and above
    
     iOS 13 and above

2. git clone:
     ```ruby
     https://github.com/OpenIMSDK/Open-IM-iOS-Demo.git
     ```

3. Execute the following command on the terminal to install the dependent library.

     ```ruby
     //iOS
     cd Open-IM-iOS-Demo/Example
     pod install
     ```
4. If the installation fails, execute the following command to update the local CocoaPods warehouse list.
     ```ruby
     pod repo update
     ```
5. Compile and run:

     Enter the Open-IM-iOS-Demo/Example folder, open OpenIMSDKUIKit.xcworkspace to compile and run.
    
6. Experience your own server
 
      6.1 If you have built OpenIM Server yourself, you can modify the server in the file [AppDelegate.swift](https://github.com/OpenIMSDK/Open-IM-iOS-Demo/blob/main/Example/OpenIMSDKUIKit/AppDelegate.swift) The address is the server address built by yourself;

     6.2 After downloading the app from testflight, click "Welcome to OpenIM" on the [Login] page to enter the setting page, make relevant settings, save and restart to use.
    
### Demo main implementation steps introduction

Commonly used chat software is composed of several basic interfaces such as session list, chat window, friend list, audio and video calls, etc. Refer to the following steps, you only need a few lines of code to quickly build these UI interfaces in the project.
    
Step 1: Initialize SDK, set ip:
1. Example
     ```ruby
     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
         // The address of the IM server, used by the OpenIM SDK
         IMController.shared.setup(apiAdrr: "",
                                   wsAddr: "",
                                   os: "minio")
     }
     ```

Step 2: Login
1. Log in to your own business server to obtain userID and token;
2. Use 1. to obtain userID and token to log in to the IM server;
3. Example:
     ```ruby
     // 1: Log in to your own business server to obtain userID and token;
    
     // Business server address Pages/LoginViewModel.swift
     let API_BASE_URL = "http://xxx/";

     static func loginDemo(phone: String, pwd: String, completionHandler: @escaping ((_ errMsg: String?) -> Void)) {
         let body = JsonTool.toJson(fromObject: Request.init(phoneNumber: phone, pwd: pwd)).data(using: .utf8)
        
         var req = try! URLRequest.init(url: API_BASE_URL + LoginAPI, method: .post)
         req.httpBody = body
        
         Alamofire.request(req).responseString { (response: DataResponse<String>) in
             switch response. result {
             case.success(let result):
                 if let res = JsonTool.fromJson(result, toClass: Response.self) {
                     if res.errCode == 0 {
                         completionHandler(nil)
                         // log in to the IM server
                         loginIM(uid: res.data.userID, token: res.data.token, completionHandler: completionHandler)
                     } else {
                         completionHandler(res.errMsg)
                     }
                 } else {
                     let err = JsonTool.fromJson(result, toClass: DemoError.self)
                     completionHandler(err?.errMsg)
                 }
             case.failure(let err):
                 completionHandler(err. localizedDescription)
             }
         }
     }
     ```
        
     ```ruby
     static func loginIM(uid: String, token: String, completionHandler: @escaping ((_ errMsg: String?) -> Void)) {
         IMController.shared.login(uid: uid, token: token) { resp in
             print("login onSuccess \(String(describing: resp))")
             completionHandler(nil)
         } onFail: { (code: Int, msg: String?) in
             let reason = "login onFail: code \(code), reason \(String(describing: msg))"
             completionHandler(reason)
         }
     }
     ```
    
Step 3: Construct conversation list, chat window, address book interface, settings:
1. Example
     ```ruby
     // session list
     let chat = ChatListViewController()
     // chat window
     let message = MessageListViewController()
     // address book
     let contactVC = ContactsViewController()
     // set up
     let mineNav = MineViewController()
     ```


### common problem

1. Reminder: "resource loading is not complete" is returned when calling sdk-related API
     If this problem occurs, you need to call other APIs after the callback of login.

2. Reminder: "target has transitive dependencies that include statically linked binaries"?
     If this error occurs during the pod process, it is because UIKit uses a third-party static library, and you need to comment out use_frameworks! in the podfile.
     If you need to use use_frameworks! under certain circumstances, please use cocoapods 1.9.0 and above to perform pod install and modify it to:
     ```ruby
         use_frameworks! :linkage => :static
     ```
     If you are using swift, please change the header file reference to @import module name form reference.
3. Reminder: Some developers found that the current M1 chip build will report an error, but it will be normal after adding arm64, and the real machine will be normal after removing arm64.
![WeChat53896c52f31d22703d323db7aacfeba7](https://user-images.githubusercontent.com/99468005/177078181-7c7614b6-4282-4f1f-bf4a-e7af105ec4b6.png)
4. Reminder: Some developers have found that the error "Cannot find xxx module" can be solved by doing the following:
     ```ruby
     pod deintegrate;
     Clean (Command + K);
     pod install/update
     ```
