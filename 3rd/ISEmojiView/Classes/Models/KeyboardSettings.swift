






import Foundation

final public class KeyboardSettings {


    public var identity: String?

    public var updateRecentEmojiImmediately:Bool = true

    public var bottomType: BottomType! = .pageControl

    public var customEmojis: [EmojiCategory]?

    public var isShowPopPreview: Bool = true

    public var countOfRecentsEmojis: Int = MaxCountOfRecentsEmojis



    public var needToShowAbcButton: Bool = false

    public var needToShowDeleteButton: Bool = true

    
    public init(bottomType: BottomType, identity: String? = nil) {
        self.bottomType = bottomType
        self.identity = identity
    }
    
}
