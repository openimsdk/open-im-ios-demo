
import Foundation
import Alamofire
import RxSwift
import OIMUIKit

// 业务服务器地址
let API_BASE_URL = UserDefaults.standard.string(forKey: bussinessSeverAddrKey) ?? "http://121.37.25.71:10004";

class LoginViewModel {
    static let IMUidKey = "DemoIMUidKey"
    static let IMTokenKey = "DemoIMTokenKey"
    
    private static let LoginAPI = "/demo/login"
    private static let RegisterAPI = "/demo/password"
    
    private let _disposeBag = DisposeBag()
    
    static func loginDemo(phone: String, pwd: String, completionHandler: @escaping ((_ errMsg: String?) -> Void)) {
        let body = JsonTool.toJson(fromObject: Request.init(phoneNumber: phone, pwd: pwd)).data(using: .utf8)
        
        var req = try! URLRequest.init(url: API_BASE_URL + LoginAPI, method: .post)
        req.httpBody = body
        req.timeoutInterval = 30
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response.self) {
                    if res.errCode == 0 {
                        completionHandler(nil)
                        // 登录IM
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
    
    static func registerAccount(phone: String, code: String, password: String, faceURL: String, nickName: String, completionHandler: @escaping ((_ errMsg: String?) -> Void)) {
        let body = JsonTool.toJson(fromObject:
                                    RegisterRequest.init(
                                        phone: phone,
                                        code: code,
                                        password: password,
                                        faceURL: faceURL,
                                        nickName: nickName)).data(using: .utf8)
        
        var req = try! URLRequest.init(url: API_BASE_URL + RegisterAPI, method: .post)
        req.httpBody = body
        req.timeoutInterval = 30
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response.self) {
                    if res.errCode == 0 {
                        completionHandler(nil)
                        // 登录IM
                        loginIM(uid: res.data.userID, token: res.data.token, completionHandler: completionHandler)
                    } else {
                        completionHandler(res.errMsg)
                    }
                } else {
                }
            case .failure(let err):
                completionHandler(err.localizedDescription)
            }
        }
    }
    
    
    static func loginIM(uid: String, token: String, completionHandler: @escaping ((_ errMsg: String?) -> Void)) {
        IMController.shared.login(uid: uid, token: token) { resp in
            print("login onSuccess \(String(describing: resp))")
            JPUSHService.setAlias(uid, completion: { code, msg, code2 in
                print("别名设置成功：", code, msg ?? "no message", code2)
            }, seq: 0)
            saveUser(uid: uid, token: token)
            completionHandler(nil)
        } onFail: { (code: Int, msg: String?) in
            let reason = "login onFail: code \(code), reason \(String(describing: msg))"
            completionHandler(reason)
            saveUser(uid: nil, token: nil)
        }
    }
    
    static func saveUser(uid: String?, token: String?) {
        UserDefaults.standard.set(uid, forKey: IMUidKey)
        UserDefaults.standard.set(token, forKey: IMTokenKey)
        UserDefaults.standard.synchronize()
    }
}


extension LoginViewModel {
    class Request: Encodable {
        private let areaCode: String = "+86"
        private let phoneNumber: String
        private let password: String
        private let platform: Int = 1
        private let operationID = UUID.init().uuidString
        init(phoneNumber: String, pwd: String) {
            self.phoneNumber = phoneNumber
            self.password = pwd.md5()
        }
    }
    
    class Response: Decodable {
        let data: UserEntity
        let errCode: Int
        let errMsg: String
    }
    
    struct UserEntity: Decodable {
        let userID: String
        let token: String
        let expiredTime: Int
    }
    
    class RegisterRequest: Encodable {
        private let faceURL: String
        private let nickName: String
        private let verificationCode: String
        private let phoneNumber: String
        private let password: String
        private let platform: Int = 1
        private let operationID = UUID.init().uuidString
        
        init(phone: String, code: String, password: String, faceURL: String, nickName: String) {
            self.phoneNumber = phone
            self.password = password.md5()
            self.verificationCode = code
            self.faceURL = faceURL
            self.nickName = nickName
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
