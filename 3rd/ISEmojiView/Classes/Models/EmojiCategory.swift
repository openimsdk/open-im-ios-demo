






import Foundation

public class EmojiCategory {

    
    public var category: Category!
    public var emojis: [Emoji]!
    public var faceEmoji: [FaceEmoji]!

    
    public init(category: Category, emojis: [Emoji] = [], faceEmoji: [FaceEmoji] = []) {
        self.category = category
        self.emojis = emojis
        self.faceEmoji = faceEmoji
    }
}
