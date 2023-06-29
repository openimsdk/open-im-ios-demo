
import ChatLayout
import DifferenceKit
import Foundation
import OUICore
import CoreLocation

// 控制消息出入
enum MessageType: Hashable {
    case incoming
    case outgoing
    
    var isIncoming: Bool {
        self == .incoming
    }
}

// 控制已读状态
enum MessageStatus: Hashable {
    case sent
    case received
}

// 控制显示类型
enum MessageRawType: Hashable {
    case normal // 消息正文
    case system // 系统提示消息： eg. xxx加入群聊 xxx撤回了一条消息
    case date   // 日期
}

enum MediaMessageType: Hashable {
    case image
    case audio
    case video
}

enum TextMessageType: Hashable {
    case text // 普通消息
    case notice // 公告
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
        var url: URL! // 远端地址 & 本地完整地址
        var relativePath: String? // 考虑断点续传 沙盒问题
    }
    
    var image: UIImage?
    var source: Info
    var thumb: Info?
    var duration: Int?
}

// 自定义消息
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
        
        case video(MediaMessageSource, isLocallyStored: Bool) // 视频路径，缩略图路径，时长
        
        case custom(CustomMessageSource)
    }
    
    var id: String
    
    var date: Date
    
    var contentType: MessageRawType
    
    var data: Data
    
    var owner: User
    
    var type: MessageType
    
    var status: MessageStatus = .sent
    
    var isSelected: Bool = false // 编辑状态使用
    
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


