
import Foundation
import JNFoundation
import RxSwift

public protocol DemoAPIable: APIable {}

extension DemoAPIable {
    public var net: Net {
        return DemoPlugin.shared.getMainNet()
    }
    
    public var nc: JNNotificationCenter {
        return DemoPlugin.shared.getNc()
    }
    
    public var mf: ModelFactory {
        return DemoPlugin.shared.getMf()
    }
    
    public func getHttpMethod() -> HttpMethod {
        return .POST
    }
    
    public var needToken: Bool {
        return true
    }
    
    public var extraHeader: [String : String] {
        return [:]
    }
    
    func parse(json: String) -> Observable<Void> {
        self.response = JsonTool.fromJson(json, toClass: Response.self)
        return Observable.just(())
    }
    
    func setModel(_ postModelEvent: Bool) -> Observable<Void> {
        return Observable.just(())
    }
    public var extraInfo: [String : Any] {
        return [:]
    }
}

class DemoAPI {
    func processToken(_ response: String) { }
    func processCode() { }
    
    var needSetModel: Bool {
        return true
    }
    
    var shouldPostModelEvent: Bool {
        return true
    }
    
    var disposebag: DisposeBag = DisposeBag()
    
    var needToken: Bool {
        return true
    }
    
    var code: Int = 0
    var token: String = ""
    var message: String?
}
