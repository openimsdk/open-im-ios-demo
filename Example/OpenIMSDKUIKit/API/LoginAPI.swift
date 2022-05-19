
import Foundation
import JNFoundation
import RxSwift

final class LoginAPI: DemoAPI, DemoAPIable {
    
    var request: Request
    var response: Response?
    
    func getUrl() -> String {
        return "demo/login"
    }
    
    override var needToken: Bool {
        return false
    }
    
    init(req: Request) {
        self.request = req
    }
    
    func setModel(_ postModelEvent: Bool) -> Observable<Void> {
        if let token = response?.data.token {
            DemoPlugin.shared.getMainNet().setToken(token)
        }
        return Observable.just(())
    }
    
    class Request: APIRequest {
        var token: String?
        var uuid: String?
        
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
    
    class Response: APIResponse {
        let data: UserEntity
    }
    
    struct UserEntity: Decodable {
        let userID: String
        let token: String
    }
    
    class LoginEvent: JNFoundation.Event {
        let token: String
        init(token: String) {
            self.token = token
        }
    }
}


