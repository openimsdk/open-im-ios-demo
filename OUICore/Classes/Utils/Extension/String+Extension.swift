
import Foundation
import Localize_Swift
import CryptoKit

extension String {
    /// 根据下标获取某个下标字符
    subscript(of index: Int) -> String {
        if index < 0 || index >= count {
            return ""
        }
        for (i, item) in enumerated() {
            if index == i {
                return "\(item)"
            }
        }
        return ""
    }

    /// 根据range获取字符串 a[1...3]
    subscript(r: ClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(r.lowerBound, 0))
        let end = index(startIndex, offsetBy: min(r.upperBound, count - 1))
        return String(self[start ... end])
    }

    /// 根据range获取字符串 a[0..<2]
    subscript(r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: max(r.lowerBound, 0))
        let end = index(startIndex, offsetBy: min(r.upperBound, count))
        return String(self[start ..< end])
    }

    /// 根据range获取字符串 a[...2]
    subscript(r: PartialRangeThrough<Int>) -> String {
        let end = index(startIndex, offsetBy: min(r.upperBound, count - 1))
        return String(self[startIndex ... end])
    }

    /// 根据range获取字符串 a[0...]
    subscript(r: PartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(r.lowerBound, 0))
        let end = index(startIndex, offsetBy: count - 1)
        return String(self[start ... end])
    }

    /// 根据range获取字符串 a[..<3]
    subscript(r: PartialRangeUpTo<Int>) -> String {
        let end = index(startIndex, offsetBy: min(r.upperBound, count))
        return String(self[startIndex ..< end])
    }

    /// 截取字符串: index 开始到结尾
    /// - Parameter index: 开始截取的index
    /// - Returns: string
    func subString(_ index: Int) -> String {
        guard index < count else {
            return ""
        }
        let start = self.index(endIndex, offsetBy: index - count)
        return String(self[start ..< endIndex])
    }

    /// 截取字符串
    /// - Parameters:
    ///   - begin: 开始截取的索引
    ///   - count: 需要截取的个数
    /// - Returns: 字符串
    func substring(start: Int, _ count: Int) -> String {
        let begin = index(startIndex, offsetBy: max(0, start))
        let end = index(startIndex, offsetBy: min(count, start + count))
        return String(self[begin ..< end])
    }
    
    public func innerLocalized() -> String {
        let bundle = ViewControllerFactory.getBundle()
        let str = localized(using: nil, in: bundle)
        return str
    }
    
    public func append(string: String?) -> String {
        if let string = string {
            var mutString: String = self
            mutString.append(string)
            return mutString
        }
        return self
    }
    
    public func getFirstPinyinUppercaseCharactor() -> String? {
        if !self.isEmpty {
            let format: HanyuPinyinOutputFormat = {
                let v = HanyuPinyinOutputFormat.init()!
                v.caseType = CaseType.init(0)
                v.toneType = ToneType.init(1)
                v.vCharType = VCharType.init(1)
                return v
            }()
            let ret = PinyinHelper.toHanyuPinyinString(with: "\(self.first!)", with: format, with: " ")
            
            if let first = ret?.first?.uppercased() {
                if first >= "A", first <= "Z" {
                    return "\(first)"
                }
                return "#"
            }
            return ret
        } else {
            return nil
        }
    }
    
    /// 获取文字的每一行字符串 空字符串为空数组
    ///
    /// - Parameters:
    ///   - maxWidth: 空间的最大宽度
    ///   - font: 文字字体
    /// - Returns: 返回计算好的行字符串
    public func textLines(_ maxWidth: CGFloat, font: UIFont) -> [String] {
        let myFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        
        let attStr = NSMutableAttributedString(string: self)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        
        attStr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attStr.length))
        attStr.addAttribute(NSAttributedString.Key(kCTFontAttributeName as String), value: myFont, range: NSRange(location: 0, length: attStr.length))
        let frameSetter = CTFramesetterCreateWithAttributedString(attStr)
        
        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width:maxWidth, height: 100000), transform: .identity)
        
        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(CFIndex(0), CFIndex(0)), path, nil)
        let lines = CTFrameGetLines(frame) as? [AnyHashable]
        var linesArray: [String] = []
        
        for line in lines ?? [] {
            let lineRange = CTLineGetStringRange(line as! CTLine)
            let range = NSRange(location: lineRange.location, length: lineRange.length)
            
            let lineString = (self as NSString).substring(with: range)
            CFAttributedStringSetAttribute(attStr, lineRange, kCTKernAttributeName, (NSNumber(value: 0.0)))
            linesArray.append(lineString)
        }
        return linesArray
    }
    
    public var md5: String {
        let inputData = Data(self.utf8)
        let md5Data = Insecure.MD5.hash(data: inputData)
        let md5Hex = md5Data.map { String(format: "%02hhx", $0) }.joined()
        
        return md5Hex
    }
}
