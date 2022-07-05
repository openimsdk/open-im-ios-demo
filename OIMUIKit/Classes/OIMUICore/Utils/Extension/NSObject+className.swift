
import Foundation

extension NSObject {
    var clazzName: String {
        return type(of: self).description()
    }

    class var className: String {
        return String(describing: self)
    }
}
