
import Foundation
import Alamofire
import RxSwift

// 业务服务器地址
let API_BASE_URL = "http://121.37.25.71:10004/";

class LoginViewModel {    
    private let _disposeBag = DisposeBag()
    func loginDemo(phone: String, pwd: String) -> Observable<Response?> {
        let body = JsonTool.toJson(fromObject: Request.init(phoneNumber: phone, pwd: pwd)).data(using: .utf8)
        
        var req = try! URLRequest.init(url: API_BASE_URL + getUrl(), method: .post)
        req.httpBody = body
        
        let request: Observable<String> = Observable<String>.create { (observer) in
            let dataRequest = Alamofire.request(req).responseString { (response: DataResponse<String>) in
                switch response.result {
                case .success(let result):
                    if let err = JsonTool.fromJson(result, toClass: DemoError.self) {
                        if err.errCode == 0 {
                            observer.onNext(result)
                            observer.onCompleted()
                        } else {
                            observer.onError(err)
                        }
                    } else {
                        observer.onNext(result)
                        observer.onCompleted()
                    }
                case .failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create {
                dataRequest.cancel()
            }
        }
        
        return request.map { (resp: String) -> Response? in
            return JsonTool.fromJson(resp, toClass: Response.self)
        }
    }
    
    func getUrl() -> String {
        return "demo/login"
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
    }
    
    struct UserEntity: Decodable {
        let userID: String
        let token: String
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
