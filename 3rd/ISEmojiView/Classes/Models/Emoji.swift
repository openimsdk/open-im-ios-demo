






import Foundation

public class Emoji: Codable {

    
    public var selectedEmoji: String?
    public var emojis: [String]!
    public var emoji: String {
        return emojis[0]
    }

    
    public init(emojis: [String]) {
        self.emojis = emojis
    }

    
    private enum CodingKeys: String, CodingKey {
        case selectedEmoji, emojis
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        selectedEmoji = try values.decode(String.self, forKey: .selectedEmoji)
        emojis = try values.decodeIfPresent([String].self, forKey: .emojis)
    }
    
    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(selectedEmoji, forKey: .selectedEmoji)
        try values.encode(emojis, forKey: .emojis)
    }
    
}

extension Emoji:Equatable {
    public static func == (lhs: Emoji, rhs: Emoji) -> Bool {
        return lhs.selectedEmoji == rhs.selectedEmoji
    }
}

public struct FaceEmoji: Codable {
    public let imageURL: URL
    public let localImagePath: String?
    public let index: Int
}
