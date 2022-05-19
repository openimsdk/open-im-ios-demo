
import Foundation
import JNFoundation
import RxSwift
import Alamofire

class StubConnect: HttpString {
    
    required init(builder: PostStringHttpBuilder) {
        _builder = builder
    }
    
    func send() -> Observable<String> {
        let headersMap = ["Content-Type":"application/json; charset=utf-8","Accept":"application/json,text/json,text/javascript,text/html"]
        let combineHeaders = headersMap.merging(self._builder.getAllHeaders()) { $1 }
        
        let body = self._builder.getContent().data(using: .utf8)
        
        var req = try! URLRequest.init(url: self._builder.getUrl(), method: .post, headers: combineHeaders)
        req.httpBody = body
        
        return Observable<String>.create { (observer) in
            let dataRequest = Alamofire.request(req).responseString { (response: DataResponse<String>) in
                switch response.result {
                case .success(let result):
                    observer.onNext(result)
                    observer.onCompleted()
                case .failure(let err):
                    observer.onError(err)
                }
            }
            return Disposables.create {
                dataRequest.cancel()
            }
        }
    }
    
    private var request: Alamofire.Request? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    private let _builder: PostStringHttpBuilder
}

class StubHttpBuilder: PostStringHttpBuilder {
    
    func setExtraInfo(_ info: [String : Any]) -> PostStringHttpBuilder {
        _extraInfo = info
        return self
    }
    
    func getExtraInfo() -> [String : Any] {
        return _extraInfo
    }
    
    func deleteHeader(key: String) {
        _header.removeValue(forKey: key)
    }
    
    func build() -> HttpString {
        
        let connect = StubConnect.init(builder: self)
        return connect
    }
    
    func setUrl(_ url: String) -> PostStringHttpBuilder {
        _url = url
        return self
    }
    
    func getUrl() -> String {
        return _url
    }
    
    func setMethod(_ method: HttpMethod) -> PostStringHttpBuilder {
        _method = method
        return self
    }
    
    func getMethod() -> HttpMethod {
        return _method
    }
    
    func addHeader(keyValue: [String: String]) -> PostStringHttpBuilder {
        _header.removeAll()
        for pair in keyValue {
            _header[pair.key] = pair.value
        }
        return self
    }
    
    func getHeader(key: String) -> String? {
        return _header[key]
    }
    
    func getAllHeaders() -> [String: String] {
        return _header
    }
    
    func deleteAllHeaders() {
        _header.removeAll()
    }
    
    func setContent(_ content: String) -> PostStringHttpBuilder {
        _body = content
        return self
    }
    
    func getContent() -> String {
        return _body
    }
    
    func setNeedToken(_ needToken: Bool) -> PostStringHttpBuilder {
        _needToken = needToken
        return self
    }
    
    func getIsNeedToken() -> Bool {
        return _needToken
    }
    
    init() {}
    
    var codeResponseType: CodeResponse.Type {
        return DemoResponseCode.self
    }
    
    private var _url: String = ""
    private var _header: [String: String] = [:]
    private var _body: String = ""
    private var _method: HttpMethod = .POST
    private var _needToken = false
    private var _extraInfo: [String: Any] = [:]
}

class DemoResponseCode: CodeResponse {

    var status: Int = -1

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decodeIfPresent(Int.self, forKey: .errCode) ?? -1
        message = try container.decodeIfPresent(String.self, forKey: .errMsg) ?? "no message"
    }

    override class func codeSuccess() -> Int {
        return 0
    }

    override class func codeTokenExpired() -> Int {
        return 201
    }

    enum CodingKeys: String, CodingKey {
        case errCode, errMsg
    }
}
