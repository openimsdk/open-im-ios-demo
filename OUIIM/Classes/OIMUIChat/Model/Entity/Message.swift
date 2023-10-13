
import ChatLayout
import DifferenceKit
import Foundation
import OUICore
import CoreLocation

    
enum MessageType: Hashable {
    case incoming
    case outgoing
    
    var isIncoming: Bool {
        self == .incoming
    }
}

    
enum MessageStatus: Hashable {
    case sent
    case received
}

    
enum MessageRawType: Hashable {
    case normal     
    case system
    case date       
}

enum MediaMessageType: Hashable {
    case image
    case audio
    case video
}

enum TextMessageType: Hashable {
    case text   
    case notice     
}

extension ChatItemAlignment {
    
    var isIncoming: Bool {
        self == .leading
    }
}

struct DateGroup: Hashable {
    
    var id: String
    var date: Date
    var value: String {
        ChatDateFormatter.shared.string(from: date)
    }
    
    init(id: String, date: Date) {
        self.id = id
        self.date = date
    }
}

extension DateGroup: Differentiable {
    
    public var differenceIdentifier: Int {
        id.hashValue
    }
    
    public func isContentEqual(to source: DateGroup) -> Bool {
        self == source
    }
}

struct SystemGroup: Hashable {
    
    enum Data: Hashable {
        case text(String)
    }
    
    var id: String
    var value: NSAttributedString
}

extension SystemGroup: Differentiable {
    
    public var differenceIdentifier: Int {
        id.hashValue
    }
    
    public func isContentEqual(to source: SystemGroup) -> Bool {
        self == source
    }
}

struct MessageGroup: Hashable {
    
    var id: String
    var title: String
    var type: MessageType
    
    init(id: String, title: String, type: MessageType) {
        self.id = id
        self.title = title
        self.type = type
    }
    
}

extension MessageGroup: Differentiable {
    
    public var differenceIdentifier: Int {
        id.hashValue
    }
    
    public func isContentEqual(to source: MessageGroup) -> Bool {
        self == source
    }
}

// MARK: - MockMediaItem

struct TextMessageSource: Hashable {
    var text: String
    var type: TextMessageType = .text
}

struct MediaMessageSource: Hashable {
    
    struct Info: Hashable {
        var url: URL!
        var relativePath: String?
    }
    
    var image: UIImage?
    var source: Info
    var thumb: Info?
    var duration: Int?
}

    
struct CustomMessageSource: Hashable {
    var data: String?
    private(set) var attributedString: NSAttributedString?
}

extension CustomMessageSource {
    public var value: [String: Any]? {
        if let data = data {
            let obj = try! JSONSerialization.jsonObject(with: data.data(using: .utf8)!) as! [String: Any]
            return obj["data"] as? [String: Any]
        }
        
        return nil
    }
    
    public var type: CustomMessageType? {
        if let data = data {
            let obj = try! JSONSerialization.jsonObject(with: data.data(using: .utf8)!) as! [String: Any]
            let t = obj["customType"] as! Int
            
            return CustomMessageType.init(rawValue: t)
        }
        
        return nil
    }
}

struct Message: Hashable {
    
    indirect enum Data: Hashable {
        
        case text(TextMessageSource)
        
        case attributeText(NSAttributedString)
        
        case url(URL, isLocallyStored: Bool)
        
        case image(MediaMessageSource, isLocallyStored: Bool)
        
        case video(MediaMessageSource, isLocallyStored: Bool) 
        
        case custom(CustomMessageSource)
    }
    
    var id: String
    
    var date: Date
    
    var contentType: MessageRawType
    
    var data: Data
    
    var owner: User
    
    var type: MessageType
    
    var status: MessageStatus = .sent
    
    var isSelected: Bool = false    
    
    var isAnchor: Bool = false
}

extension Message {
    func getSummary() -> String? {
        var abstruct: String?
        
        switch data {
        case .text(let source):
            abstruct = source.type == .notice ? "[公告]" : source.text
        case .attributeText(let value):
            abstruct = value.string
        case .url(_, isLocallyStored: let isLocallyStored):
            abstruct = "[链接]".innerLocalized()
        case .image(_, isLocallyStored: let isLocallyStored):
            abstruct = "[图片]".innerLocalized()
        case .video(_, isLocallyStored: let isLocallyStored):
            abstruct = "[视频]".innerLocalized()
        
        default:
            break
        }
        
        return abstruct
    }
}

extension Message: Differentiable {

    public var differenceIdentifier: Int {
        id.hashValue
    }

    public func isContentEqual(to source: Message) -> Bool {
        self == source
    }

}


