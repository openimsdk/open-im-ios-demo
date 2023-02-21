import Foundation

public typealias QueryInfoHandler = ((_ keywords: [String], _ completion: @escaping (([UserInfo]) -> Void)) -> Void)
public typealias QueryDataHandler<T: Any> = ((_ completion: @escaping (T) -> Void) -> Void)

public class OIMApi {

    public static var queryConfigHandler: QueryDataHandler<[String: Any]>?
}
