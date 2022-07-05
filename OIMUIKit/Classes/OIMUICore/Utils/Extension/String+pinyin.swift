
import Foundation
extension String {
    func pinyin() -> String? {
        let str = NSMutableString(string: self)
        CFStringTransform(str as CFMutableString, nil, kCFStringTransformMandarinLatin, false)
        CFStringTransform(str as CFMutableString, nil, kCFStringTransformStripDiacritics, false)
        let ret = String(str).replacingOccurrences(of: " ", with: "")
        return ret
    }
}
