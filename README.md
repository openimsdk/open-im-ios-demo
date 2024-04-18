<p align="center">
    <a href="https://www.openim.io">
        <img src="https://github.com/openimsdk/openim-electron-demo/blob/main/docs/images/openim-logo.gif" width="60%" height="30%"/>
    </a>
</p>

# OpenIM iOS Demo 💬💻

<p>
  <a href="https://doc.rentsoft.cn/">OpenIM Docs</a>
  •
  <a href="https://github.com/openimsdk/open-im-server">OpenIM Server</a>
  •
  <a href="https://github.com/openimsdk/open-im-sdk-ios">openim-sdk-ios</a>
  •
  <a href="https://github.com/openimsdk/openim-sdk-core">openim-sdk-core</a>
</p>

<br>

OpenIM iOS Demo is a set of UI components implemented based on Open-IM SDK, which includes functions such as conversation, chat, relationship chain, group, etc. Based on UI components, you can quickly build your own business logic.

## Dev Setup 🛠️

1. Development environment requirements
     + Xcode 14 and above
    
     + The minimum deployment target is iOS 13.0.

2. Git Clone:
     ```ruby
     https://github.com/OpenIMSDK/Open-IM-iOS-Demo.git
     ```

3. Execute the following command on the terminal to install the dependent library.
     ```ruby
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
      6.1 If you have [Deploy OpenIM Server](https://github.com/openimsdk/open-im-server#rocket-quick-start) yourself, you can modify the server in the file [AppDelegate.swift](https://github.com/OpenIMSDK/Open-IM-iOS-Demo/blob/main/Example/OpenIMSDKUIKit/AppDelegate.swift) The address is the server address built by yourself;

     6.2 After downloading the app from testflight, click "Welcome to OpenIM" on the [Login] page to enter the setting page, make relevant settings, save and restart to use.
7. Start development! 🎉

## Usage 🚀

> Commonly used chat software is composed of several basic interfaces such as session list, chat window, friend list, audio and video calls, etc. Refer to the following steps, you only need a few lines of code to quickly build these UI interfaces in the project.
    
Step 1: Change your own server IP address:
> [AppDelegate.swift](https://github.com/OpenIMSDK/Open-IM-iOS-Demo/blob/main/Example/OpenIMSDKUIKit/AppDelegate.swift)
   ```ruby
   // Default IP address to be used
   let defaultHost = ""; // Replace with the desired host
   ```

Step 2: Login
> 1. Log in to your own business server to obtain userID and token;
> 2. Use 1. to obtain userID and token to log in to the IM server;

   ```ruby
   // 1: Log in to your own business server to obtain userID and token;

     static func loginDemo(phone: String, pwd: String, completionHandler: @escaping ((_ errMsg: String?) -> Void)) {
         let body = JsonTool.toJson(fromObject: Request.init(phoneNumber: phone, pwd: pwd)).data(using: .utf8)
        
         var req = try! URLRequest.init(url: "your login api", method: .post)
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

## Community :busts_in_silhouette:

- 📚 [OpenIM Community](https://github.com/OpenIMSDK/community)
- 💕 [OpenIM Interest Group](https://github.com/Openim-sigs)
- 🚀 [Join our Slack community](https://join.slack.com/t/openimsdk/shared_invite/zt-22720d66b-o_FvKxMTGXtcnnnHiMqe9Q)
- :eyes: [Join our wechat (微信群)](https://openim-1253691595.cos.ap-nanjing.myqcloud.com/WechatIMG20.jpeg)

## Community Meetings :calendar:

We want anyone to get involved in our community and contributing code, we offer gifts and rewards, and we welcome you to join us every Thursday night.

Our conference is in the [OpenIM Slack](https://join.slack.com/t/openimsdk/shared_invite/zt-22720d66b-o_FvKxMTGXtcnnnHiMqe9Q) 🎯, then you can search the Open-IM-Server pipeline to join

We take notes of each [biweekly meeting](https://github.com/orgs/OpenIMSDK/discussions/categories/meeting) in [GitHub discussions](https://github.com/openimsdk/open-im-server/discussions/categories/meeting), Our historical meeting notes, as well as replays of the meetings are available at [Google Docs :bookmark_tabs:](https://docs.google.com/document/d/1nx8MDpuG74NASx081JcCpxPgDITNTpIIos0DS6Vr9GU/edit?usp=sharing).

## Who are using OpenIM :eyes:

Check out our [user case studies](https://github.com/OpenIMSDK/community/blob/main/ADOPTERS.md) page for a list of the project users. Don't hesitate to leave a [📝comment](https://github.com/openimsdk/open-im-server/issues/379) and share your use case.

## License :page_facing_up:

OpenIM is licensed under the Apache 2.0 license. See [LICENSE](https://github.com/openimsdk/open-im-server/tree/main/LICENSE) for the full license text.
