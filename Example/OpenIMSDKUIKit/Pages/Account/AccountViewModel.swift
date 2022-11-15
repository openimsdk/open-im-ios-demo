
import Alamofire
import Foundation
import OIMUIKit
import RxSwift

class AccountViewModel {
    // 业务服务器地址
    static let API_BASE_URL = UserDefaults.standard.string(forKey: bussinessSeverAddrKey) ?? "https://web.rentsoft.cn/chat"
    
    // 实际开发，抽离网络部分
    static let IMUidKey = "DemoIMUidKey"
    static let IMTokenKey = "DemoIMTokenKey"
    static let bussinessTokenKey = "bussinessTokenKey"
    
    private static let LoginAPI = "/account/login"
    private static let RegisterAPI = "/account/password"
    private static let CodeAPI = "/account/code"
    private static let VerifyCodeAPI = "/account/verify"
    private static let UpdateUserInfoAPI = "/user/update_user_info"
    
    private let _disposeBag = DisposeBag()
    
    static func loginDemo(phone: String, pwd: String, completionHandler: @escaping (_ errCode: Int, _ errMsg: String?) -> Void) {
        let body = JsonTool.toJson(fromObject: Request(phoneNumber: phone, pwd: pwd)).data(using: .utf8)
        
        var req = try! URLRequest(url: API_BASE_URL + LoginAPI, method: .post)
        req.httpBody = body
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<UserEntity>.self) {
                    if res.errCode == 0 {
                        completionHandler(res.errCode, nil)
                        // 登录IM
                        loginIM(uid: res.data!.userID, imToken: res.data!.imToken, chatToken: res.data!.chatToken, completionHandler: completionHandler)
                    } else {
                        completionHandler(res.errCode, res.errMsg)
                    }
                } else {
                    let err = JsonTool.fromJson(result, toClass: DemoError.self)
                    completionHandler(err?.errCode ?? -1, err?.errMsg)
                }
            case .failure(let err):
                completionHandler(-1, err.localizedDescription)
            }
        }
    }
    
    static func registerAccount(phone: String,
                                areaCode: String,
                                verificationCode: String,
                                password: String,
                                faceURL: String,
                                nickName: String,
                                birth: Int = Int(NSDate().timeIntervalSince1970),
                                gender: Int = 1,
                                email: String = "",
                                invitationCode: String = "",
                                completionHandler: @escaping (_ errCode: Int, _ errMsg: String?) -> Void)
    {
        let body = JsonTool.toJson(fromObject:
            RegisterRequest(
                phone: phone,
                areaCode: areaCode,
                verificationCode: verificationCode,
                password: password,
                faceURL: faceURL,
                nickName: nickName,
                birth: birth,
                gender: gender,
                invitationCode: invitationCode)).data(using: .utf8)
        
        var req = try! URLRequest(url: API_BASE_URL + RegisterAPI, method: .post)
        req.httpBody = body
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<UserEntity>.self) {
                    if res.errCode == 0 {
                        saveUser(uid: res.data?.userID, imToken: res.data?.imToken, chatToken: res.data?.chatToken)
                        completionHandler(res.errCode, nil)
                    } else {
                        completionHandler(res.errCode, res.errMsg)
                    }
                } else {}
            case .failure(let err):
                completionHandler(-1, err.localizedDescription)
            }
        }
    }
    
    // [usedFor] 1：注册，2：重置密码
    static func requestCode(phone: String, areaCode: String, useFor: Int, completionHandler: @escaping ((_ errCode: Int?, _ errMsg: String?) -> Void)) {
        let body = JsonTool.toJson(fromObject:
            CodeRequest(
                phone: phone,
                areaCode: areaCode,
                usedFor: useFor)).data(using: .utf8)
        
        var req = try! URLRequest(url: API_BASE_URL + CodeAPI, method: .post)
        req.httpBody = body
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<UserEntity>.self) {
                    if res.errCode == 0 {
                        completionHandler(res.errCode, nil)
                    } else {
                        completionHandler(res.errCode, res.errMsg)
                    }
                } else {}
            case .failure(let err):
                completionHandler(-1, err.localizedDescription)
            }
        }
    }
    
    // [usedFor] 1：注册，2：重置密码
    static func verifyCode(phone: String, areaCode: String, useFor: Int, verificationCode: String, completionHandler: @escaping ((_ errCode: Int?, _ errMsg: String?) -> Void)) {
        let body = JsonTool.toJson(fromObject:
            CodeRequest(
                phone: phone,
                areaCode: areaCode,
                usedFor: useFor,
                verificationCode: verificationCode)).data(using: .utf8)
        
        var req = try! URLRequest(url: API_BASE_URL + VerifyCodeAPI, method: .post)
        req.httpBody = body
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<UserEntity>.self) {
                    if res.errCode == 0 {
                        completionHandler(res.errCode, nil)
                    } else {
                        completionHandler(res.errCode, res.errMsg)
                    }
                } else {}
            case .failure(let err):
                completionHandler(-1, err.localizedDescription)
            }
        }
    }
    
    // 更新个人信息
    static func updateUserInfo(userID: String,
                               account: String? = nil,
                               areaCode: String? = nil,
                               phone: String? = nil,
                               email: String? = nil,
                               nickname: String? = nil,
                               faceURL: String? = nil,
                               gender: Int? = nil,
                               birth: Int? = nil,
                               level: Int? = nil,
                               allowAddFriend: Int? = nil,
                               allowBeep: Int? = nil,
                               allowVibration: Int? = nil,
                               completionHandler: @escaping ((_ errMsg: String?) -> Void))
    {
        let body = JsonTool.toJson(fromObject:
            UpdateUserInfoRequest(userID: userID,
                                  phone: phone,
                                  faceURL: faceURL,
                                  nickName: nickname,
                                  birth: birth,
                                  gender: gender,
                                  account: account,
                                  level: level,
                                  email: email,
                                  allowAddFriend: allowAddFriend,
                                  allowBeep: allowBeep,
                                  allowVibration: allowVibration)).data(using: .utf8)
        
        var req = try! URLRequest(url: API_BASE_URL + UpdateUserInfoAPI, method: .post)
        req.httpBody = body
        req.addValue(UserDefaults.standard.string(forKey: bussinessTokenKey)!, forHTTPHeaderField: "token")
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<UpdateUserInfoRequest>.self) {
                    if res.errCode == 0 {
                        completionHandler(nil)
                    } else {
                        completionHandler(res.errMsg)
                    }
                } else {}
            case .failure(let err):
                completionHandler(err.localizedDescription)
            }
        }
    }
    
    // 获取个人信息
    static func updateUserInfo(pageNumber: Int = 1,
                               showNumber: Int = 10,
                               userIDList: [String],
                               completionHandler: @escaping ((_ errMsg: String?) -> Void))
    {
        let body = JsonTool.toJson(fromObject:
            QueryUserInfoRequest(userIDList: userIDList)).data(using: .utf8)
        
        var req = try! URLRequest(url: API_BASE_URL + UpdateUserInfoAPI, method: .post)
        req.httpBody = body
        req.addValue(UserDefaults.standard.string(forKey: bussinessTokenKey)!, forHTTPHeaderField: "token")
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<QueryUserInfoData>.self) {
                    if res.errCode == 0 {
                        completionHandler(nil)
                    } else {
                        completionHandler(res.errMsg)
                    }
                } else {}
            case .failure(let err):
                completionHandler(err.localizedDescription)
            }
        }
    }
    
    static func loginIM(uid: String, imToken: String, chatToken: String, completionHandler: @escaping (_ errCode: Int, _ errMsg: String?) -> Void) {
        IMController.shared.login(uid: uid, token: imToken) { resp in
            print("login onSuccess \(String(describing: resp))")
            saveUser(uid: uid, imToken: imToken, chatToken: chatToken)
            completionHandler(0, nil)
        } onFail: { (code: Int, msg: String?) in
            let reason = "login onFail: code \(code), reason \(String(describing: msg))"
            completionHandler(code, reason)
            saveUser(uid: nil, imToken: nil, chatToken: nil)
        }
    }
    
    static func saveUser(uid: String?, imToken: String?, chatToken: String?) {
        UserDefaults.standard.set(uid, forKey: IMUidKey)
        UserDefaults.standard.set(imToken, forKey: IMTokenKey)
        UserDefaults.standard.set(chatToken, forKey: bussinessTokenKey)
        UserDefaults.standard.synchronize()
    }
    
    static var userID: String? {
        return UserDefaults.standard.string(forKey: IMUidKey)
    }
    
    static var baseUser: UserEntity {
        return UserEntity(userID: UserDefaults.standard.string(forKey: IMUidKey) ?? "",
                          imToken: UserDefaults.standard.string(forKey: IMTokenKey) ?? "",
                          chatToken: UserDefaults.standard.string(forKey: bussinessTokenKey) ?? "",
                          expiredTime: nil)
    }
}

extension AccountViewModel {
    class Request: Encodable {
        private let areaCode: String = "+86"
        private let phoneNumber: String
        private let password: String
        private let platform: Int = 1
        private let operationID = UUID().uuidString
        init(phoneNumber: String, pwd: String) {
            self.phoneNumber = phoneNumber
            self.password = pwd.md5()
        }
    }
    
    class Response<T: Decodable>: Decodable {
        var data: T? = nil
        var errCode: Int = 0
        var errMsg: String? = nil
    }
    
    struct UserEntity: Decodable {
        let userID: String
        let imToken: String
        let chatToken: String
        let expiredTime: Int?
    }
    
    class RegisterRequest: Encodable {
        private let areaCode: String?
        private let faceURL: String?
        private let nickName: String?
        private var verificationCode: String?
        private let phoneNumber: String?
        private let password: String?
        private let platform: Int = 1
        private let operationID = UUID().uuidString
        private let birth: Int?
        private let gender: Int?
        private let email: String?
        private let invitationCode: String?
        private let deviceID: String = UUID().uuidString
        
        init(phone: String, areaCode: String, verificationCode: String?, password: String?, faceURL: String?, nickName: String?, birth: Int?, gender: Int?, email: String? = nil, invitationCode: String?) {
            self.areaCode = areaCode
            self.phoneNumber = phone
            self.password = password?.md5()
            self.verificationCode = verificationCode
            self.faceURL = faceURL
            self.nickName = nickName
            self.birth = birth
            self.gender = gender
            self.email = email
            self.invitationCode = invitationCode
        }
    }
    
    class CodeRequest: Encodable {
        private let areaCode: String
        private let phoneNumber: String
        private let usedFor: Int
        private let verificationCode: String
        private let platform: Int = 1
        private let operationID = UUID().uuidString
        
        init(phone: String, areaCode: String, usedFor: Int, verificationCode: String = "") {
            self.phoneNumber = phone
            self.areaCode = areaCode
            self.usedFor = usedFor
            self.verificationCode = verificationCode
        }
    }
    
    class QueryUserInfoRequest: Encodable {
        private let pageNumber: Int
        private let showNumber: Int
        private let userIDList: [String]
        private let platform: Int = 1
        private let operationID = UUID().uuidString
        
        init(pageNumber: Int = 1, showNumber: Int = 10, userIDList: [String]) {
            self.pageNumber = pageNumber
            self.showNumber = showNumber
            self.userIDList = userIDList
        }
    }
    
    class QueryUserInfoData: Decodable {
        private let userFullInfoList: [QueryUserInfo]
        private let totalNumber: Int
    }
    
    class QueryUserInfo: UpdateUserInfoRequest {}
    
    class UpdateUserInfoRequest: Codable {
        private let userID: String?
        private let account: String?
        private let level: Int?
        private let faceURL: String?
        private let nickName: String?
        private let phoneNumber: String?
        private var platform: Int = 1
        private var operationID = UUID().uuidString
        private let birth: Int?
        private let gender: Int?
        private let email: String?
        private let allowAddFriend: Int?
        private let allowBeep: Int?
        private let allowVibration: Int?
        
        init(userID: String,
             phone: String?,
             faceURL: String?,
             nickName: String?,
             birth: Int?,
             gender: Int?,
             account: String?,
             level: Int?,
             email: String?,
             allowAddFriend: Int?,
             allowBeep: Int?,
             allowVibration: Int?)
        {
            self.phoneNumber = phone
            self.faceURL = faceURL
            self.nickName = nickName
            self.birth = birth
            self.gender = gender
            self.email = email
            self.account = account
            self.level = level
            self.userID = userID
            self.allowAddFriend = allowAddFriend
            self.allowBeep = allowBeep
            self.allowVibration = allowVibration
        }
    }
}

struct DemoError: Error, Decodable {
    let errCode: Int
    let errMsg: String?
    
    var localizedDescription: String {
        let msg: String = errMsg ?? "no message"
        return "code: \(errCode), msg: \(msg)"
    }
}
