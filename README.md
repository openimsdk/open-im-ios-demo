<img src="https://openim-1253691595.cos.ap-nanjing.myqcloud.com/WechatIMG20.jpeg" alt="image" style="width: 200px; " />
# Open-IM-iOS-Demo: OpenIM Messaging Client for iOS
iOS client for [OpenIM](https://github.com/OpenIMSDK/Open-IM-Server) in Swift.

### Demo内容
Demo 是基于 Open-IM SDK 实现的一套 UI 组件，其包含会话、聊天、关系链、群组等功能，基于 UI 组件您可以快速搭建起自己的业务逻辑。
请使用最v3版本的服务端。

### 直接testflight下载app体验

<img src="https://github.com/OpenIMSDK/OpenIM-Docs/blob/main/docs/images/ios_native.png" alt="image" style="width: 200px; " />

### 源代码体验

1. 开发环境要求
    Xcode 10 及以上
    
    iOS 11 及以上（后续提高iOS13及以上）

2. git clone：
    ```ruby
    https://github.com/OpenIMSDK/Open-IM-iOS-Demo.git
    ```

3. 终端执行以下命令，安装依赖库。

    ```ruby
    //iOS
    cd Open-IM-iOS-Demo/Example
    pod install
    ```
4. 如果安装失败，执行以下命令更新本地的 CocoaPods 仓库列表。
    ```ruby
    pod repo update
    ```
5. 编译运行：

    进入Open-IM-iOS-Demo/Example 文件夹，打开OpenIMSDKUIKit.xcworkspace编译运行。
    
6. 体验自己的服务器
 
     6.1 如果自己搭建了OpenIM Server，可修改 [AppDelegate.swift](https://github.com/OpenIMSDK/Open-IM-iOS-Demo/blob/main/Example/OpenIMSDKUIKit/AppDelegate.swift)文件里的服务器地址为自己搭建的服务器地址；

    6.2 从testflight下载app以后，点击【登录】页的“欢迎使用OpenIM”进入设置页，进行相关设置，保存成功重启后即可使用。
    
### Demo主要实现步骤介绍

常用的聊天软件都是由会话列表、聊天窗口、好友列表、音视频通话等几个基本的界面组成，参考下面步骤，您仅需几行代码即可在项目中快速搭建这些 UI 界面。
    
步骤一：初始化SDK，设置ip：
1. 举例
    ```ruby
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // IM服务器的地址，OpenIM SDK使用
        IMController.shared.setup(apiAdrr: "",
                                  wsAddr: "",
                                  os: "minio")
    }
    ```

步骤二：登录
1. 登录自己的业务服务器，获取userID 和 token；
2. 使用1.获取userID 和 token 登录IM服务器；
3. 举例：
    ```ruby
    // 1: 登录自己的业务服务器，获取userID 和 token；
    
    // 业务服务器地址 Pages/LoginViewModel.swift
    let API_BASE_URL = "http://xxx/";

    static func loginDemo(phone: String, pwd: String, completionHandler: @escaping ((_ errMsg: String?) -> Void)) {
        let body = JsonTool.toJson(fromObject: Request.init(phoneNumber: phone, pwd: pwd)).data(using: .utf8)
        
        var req = try! URLRequest.init(url: API_BASE_URL + LoginAPI, method: .post)
        req.httpBody = body
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response.self) {
                    if res.errCode == 0 {
                        completionHandler(nil)
                        // 登录IM服务器
                        loginIM(uid: res.data.userID, token: res.data.token, completionHandler: completionHandler)
                    } else {
                        completionHandler(res.errMsg)
                    }
                } else {
                    let err = JsonTool.fromJson(result, toClass: DemoError.self)
                    completionHandler(err?.errMsg)
                }
            case .failure(let err):
                completionHandler(err.localizedDescription)
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
    
步骤三：构建会话列表、聊天窗口、通讯录界面、设置：
1. 举例
    ```ruby
    // 会话列表
    let chat = ChatListViewController()
    // 聊天窗口
    let message = MessageListViewController()
    // 通讯录
    let contactVC = ContactsViewController()
    // 设置
    let mineNav = MineViewController()        
    ```


### 常见问题

1. 提醒: 在调用sdk相关API返回“resource loading is not complete”
    如果出现该问题，需在login的callback以后调用其它API。

2. 提醒：“target has transitive dependencies that include statically linked binaries”？
    如果在 pod 过程中出现该错误，是因为 UIKit 使用到了第三方静态库，需要在 podfile 中注释掉 use_frameworks!。
    如果在某种情况下，需要使用use_frameworks!，则请使用 cocoapods 1.9.0及以上版本进行 pod install，并修改为：
    ```ruby
        use_frameworks! :linkage => :static
    ```
    如果您使用的是 swift，请将头文件引用改成 @import 模块名形式引用。
3. 提醒：有开发者发现，目前M1芯片build会出现报错，添加arm64后正常，真机去掉arm64正常。
![WeChat53896c52f31d22703d323db7aacfeba7](https://user-images.githubusercontent.com/99468005/177078181-7c7614b6-4282-4f1f-bf4a-e7af105ec4b6.png)
4. 提醒：有开发者发现，报错“找不到xxx模块”,做如下操作可解决：
    ```ruby
    pod deintegrate；
    Clean(Command + K)；
    pod install/update
    ```

