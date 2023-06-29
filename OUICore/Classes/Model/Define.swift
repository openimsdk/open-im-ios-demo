
import Foundation

public enum ContactType {
    case undefine
    case friends // 好友
    case members // 群成员
    case groups  // 群
}

public struct ContactInfo {
    public let ID: String?
    public let name: String?
    public let faceURL: String?
    public let sub: String?
    public let type: ContactType
    
    public init(ID: String? = nil, name: String? = nil, faceURL: String? = nil, sub: String? = nil, type: ContactType = .friends) {
        self.ID = ID
        self.name = name
        self.faceURL = faceURL
        self.sub = sub
        self.type = type
    }
}
