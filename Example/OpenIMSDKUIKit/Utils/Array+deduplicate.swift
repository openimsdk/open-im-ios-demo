
import Foundation

extension Array {
    func deduplicate<E: Equatable>(filter: (Element) -> E) -> [Element] {
        var ret = [Element]()
        for value in self {
            let key = filter(value)
            if !ret.map({filter($0)}).contains(key) {
                ret.append(value)
            }
        }
        return ret
    }
}
