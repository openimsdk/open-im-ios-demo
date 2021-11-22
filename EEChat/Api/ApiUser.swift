//
//  ApiUser.swift
//  EEChat
//
//  Created by Snow on 2021/5/18.
//

import Foundation
import OpenIMSDKiOS
import web3swift
import OpenIMSDKiOS

public enum Gender: Int, Codable {
    case unknown = 0
    case male = 1
    case female = 2
}

public class UserInfo1: UserInfo, Codable {
//    public var uid = ""
//    public var name = ""
//    public var icon: URL?
//    public var gender = Gender.unknown
//    public var mobile = ""
//    public var birth = ""
//    public var email = ""
//    public var ex = ""
//    public var comment = ""

    public override init() {
        super.init()
    }

    private enum CodingKeys: String, CodingKey {
        case uid, name, icon, gender, mobile, birth, email, ex, comment
    }

    required public init(from decoder: Decoder) throws {
        super.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(String.self, forKey: .uid)
        name = try container.decode(String.self, forKey: .name)
        icon = try? container.decode(String.self, forKey: .icon)
        gender = try container.decode(Int32.self, forKey: .gender)
        mobile = try container.decode(String.self, forKey: .mobile)
        birth = try container.decode(String.self, forKey: .birth)
        email = try container.decode(String.self, forKey: .email)
        ex = try container.decode(String.self, forKey: .ex)
        if let value = try? container.decode(String.self, forKey: .comment) {
            comment = value
        }
    }
    
    public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(uid, forKey: .uid)
            try container.encode(name, forKey: .name)
            try container.encode(icon, forKey: .icon)
            try container.encode(gender, forKey: .gender)
            try container.encode(mobile, forKey: .mobile)
            try container.encode(birth, forKey: .birth)
            try container.encode(email, forKey: .email)
            try container.encode(ex, forKey: .ex)
            try container.encode(comment, forKey: .comment)
        }

    public static func == (lhs: UserInfo1, rhs: UserInfo1) -> Bool {
        return lhs.uid == rhs.uid
    }

//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(uid)
//    }

    public func getName() -> String {
        return comment!.isEmpty ? name! : comment!
    }
}

public struct AuthModel: Codable {
    public var uid = ""
    public var token = ""
    public var expiredTime = TimeInterval.zero
    
    public init() {}
}

struct ApiUserLogin: ApiType {
    let apiTarget: ApiTarget = ApiInfo(path: "auth/user_token")
    
    var param = Param()
    
    init() {}
    
    struct Param: Encodable {
        let platform = 1
        let operationID = OperationID()
        var uid = ""
        var secret = ""
    }
    
    struct ToeknModel: Codable {
        var accessToken = ""
        var expiredTime = TimeInterval.zero
    }
    
    struct Model: Codable {
        var userInfo = UserInfo1()
        var openImToken = AuthModel()
        var token = ToeknModel()
        
        init() {}
        
        private enum CodingKeys: String, CodingKey {
            case userInfo,
                 openImToken,
                 token
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            if let value = try? container.decode(UserInfo1.self, forKey: .userInfo) {
                userInfo = value
            } else {
                userInfo = try UserInfo1(from: decoder)
            }
            
            openImToken = try container.decode(AuthModel.self, forKey: .openImToken)
            token = try container.decode(ToeknModel.self, forKey: .token)
        }
        public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(userInfo, forKey: .userInfo)
                try container.encode(openImToken, forKey: .openImToken)
                try container.encode(token, forKey: .token)
            }
    }
    
    static func login(mnemonic: String) {
        MessageModule.showHUD(text: LocalizedString("Generating..."))
        DispatchQueue.global().async {
            let keystore = try? BIP32Keystore(
                    mnemonics: mnemonic,
                    password: "web3swift",
                    mnemonicsPassword: "",
                    language: .english)
            
            DispatchQueue.main.async {
                MessageModule.hideHUD()
                guard let address = keystore?.addresses?.first?.address else {
                    MessageModule.showMessage(LocalizedString("Mnemonic word error."))
                    return
                }
                
                var api = ApiUserLogin()
                api.param.uid = "openIM123456"
                api.param.secret = "tuoyun"
                _ = api.request(showLoading: true)
                    //.map(type: ApiUserLogin.Model.self)
                    .subscribe(onSuccess: { model in
//                        _ = rxRequest(showLoading: true,
//                                      action: { OIMManager.login(uid: model.openImToken.uid,
//                                                                 token: model.openImToken.token,
//                                                                 callback: $0) })
//                            .subscribe(onSuccess: { _ in
//                                DBModule.shared.set(key: LoginVC.cacheKey, value: mnemonic)
//                                AccountManager.shared.login(model: model)
//                            })
                        OpenIMiOSSDK.shared().login((model.content as! Dictionary<String, Any>)["uid"] as! String, token: (model.content as! Dictionary<String, Any>)["token"] as! String) { msg in
                            DBModule.shared.set(key: LoginVC.cacheKey, value: mnemonic)
                            var m = ApiUserLogin.Model()
                            m.userInfo = UserInfo1()
                            m.userInfo.uid = (model.content as! Dictionary<String, Any>)["uid"] as! String
                            m.token = ToeknModel()
                            m.token.accessToken = (model.content as! Dictionary<String, Any>)["token"] as! String
                            DispatchQueue.main.async {
                                AccountManager.shared.login(model: m)
                            }
                        } onError: { code, msg in

                        }

                    })
            }
        }
    }
    
}
