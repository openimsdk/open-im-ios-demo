






import Foundation

extension String {
    public func append(string: String?) -> String {
        if let string = string {
            var mutString: String = self
            mutString.append(string)
            return mutString
        }
        return self
    }
}
