
import Foundation

class EmojiHelper {
    static let ReplaceableStringKey: NSAttributedString.Key = .init(rawValue: "ReplaceableStringKey")

    static let shared: EmojiHelper = {
        var emojis: [EmojiHelper.Emoji] = []
        for key in EmojiHelper.emojiMap.keys {
            if let imageName = EmojiHelper.emojiMap[key] {
                let emoji = EmojiHelper.Emoji(imageName: imageName, imageDesc: key)
                emojis.append(emoji)
            }
        }
        let v = EmojiHelper(emojis: emojis)
        return v
    }()

    static let emojiMap: [String: String] = [
        "[亲亲]": "ic_face_01",
        "[看穿]": "ic_face_02",
        "[色]": "ic_face_03",
        "[吓哭]": "ic_face_04",
        "[笑脸]": "ic_face_05",
        "[眨眼]": "ic_face_06",
        "[搞怪]": "ic_face_07",
        "[龇牙]": "ic_face_08",
        "[无语]": "ic_face_09",
        "[可怜]": "ic_face_10",
        "[咒骂]": "ic_face_11",
        "[晕]": "ic_face_12",
        "[尴尬]": "ic_face_13",
        "[暴怒]": "ic_face_14",
        "[可爱]": "ic_face_15",
        "[哭泣]": "ic_face_16",
    ]

    let emojis: [Emoji]

    init(emojis: [Emoji]) {
        self.emojis = emojis
    }

    /// 在属性文本中做可替换的文本标记
    func markReplaceableRange(inAttributedString: NSAttributedString, withString: String) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: inAttributedString)
        mutable.addAttribute(EmojiHelper.ReplaceableStringKey, value: withString, range: NSRange(location: 0, length: inAttributedString.length))
        return mutable
    }

    func replaceTextWithEmojiIn(attributedString: NSAttributedString, font: UIFont = UIFont.systemFont(ofSize: 14)) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(attributedString: attributedString)
        if attributedString.length <= 0 {
            return attributedString
        }

        let matchedResults = getMatchedEmojiResultIn(string: attributedString.string)
        var offset = 0
        for result in matchedResults {
            let emojiHeight = font.lineHeight
            let attachment = NSTextAttachment()
            attachment.image = result.emojiImage
            attachment.bounds = CGRect(x: 0, y: font.descender, width: emojiHeight, height: emojiHeight)
            let emojiAttString = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
            let marked = markReplaceableRange(inAttributedString: emojiAttString, withString: result.emojiDesc)

            let actualRange = NSRange(location: result.range.location - offset, length: result.emojiDesc.length)
            attributedString.replaceCharacters(in: actualRange, with: marked)
            offset += result.emojiDesc.length - marked.length
        }
        return attributedString
    }

    func getPlainTextIn(attributedString: NSAttributedString, atRange: NSRange) -> NSString {
        let string: NSString = attributedString.string as NSString
        let result = NSMutableString()
        attributedString.enumerateAttribute(EmojiHelper.ReplaceableStringKey, in: atRange, options: .longestEffectiveRangeNotRequired) { (mark: Any?, range: NSRange, _: UnsafeMutablePointer<ObjCBool>) in
            if let mark = mark as? String {
                result.append(mark)
            } else {
                result.append(string.substring(with: range))
            }
        }

        return result
    }

    private func getMatchedEmojiResultIn(string: String) -> [EmojiMatchedResult] {
        if string.isEmpty {
            return []
        }

        let string = NSString(string: string)

        do {
            let regex: NSRegularExpression = try NSRegularExpression(pattern: "\\[.+?\\]", options: .caseInsensitive)
            let results: [NSTextCheckingResult] = regex.matches(in: string as String, options: .reportCompletion, range: NSRange(location: 0, length: string.length))

            var emojiResults: [EmojiMatchedResult] = []
            for result in results {
                let emojiName = string.substring(with: result.range)
                if let emoji = getEmojiWith(name: emojiName) {
                    let img = getImageWith(name: emoji.imageName)
                    let res = EmojiMatchedResult(range: result.range, emojiImage: img, emojiDesc: emoji.imageDesc)
                    emojiResults.append(res)
                }
            }
            return emojiResults
        } catch {
            print("获取匹配Emoji结果失败:", error.localizedDescription)
        }
        return []
    }

    private func getEmojiWith(name: String) -> Emoji? {
        for emoji in emojis {
            if emoji.imageDesc == name {
                return emoji
            }
        }
        return nil
    }

    private func getImageWith(name: String) -> UIImage? {
        let image = UIImage(nameInEmoji: name)
        return image
    }

    struct Emoji {
        let imageName: String
        let imageDesc: String
    }

    struct EmojiMatchedResult {
        let range: NSRange
        let emojiImage: UIImage?
        let emojiDesc: String
    }
}

extension String {
    var length: Int {
        let string = NSString(string: self)
        return string.length
    }
}
