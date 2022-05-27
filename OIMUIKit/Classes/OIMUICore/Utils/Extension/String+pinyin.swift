







import Foundation
extension String {
    func pinyin() -> String? {
        let str = NSMutableString.init(string: self)
        CFStringTransform(str as CFMutableString, nil, kCFStringTransformMandarinLatin, false)
        CFStringTransform(str as CFMutableString, nil, kCFStringTransformStripDiacritics, false)
        let ret = String.init(str).replacingOccurrences(of: " ", with: "")
        return ret
    }
}
