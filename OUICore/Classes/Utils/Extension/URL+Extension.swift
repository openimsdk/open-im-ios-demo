
import Foundation
import CryptoKit

extension URL {
    public var md5: String {
        let inputData = Data(self.relativeString.utf8)
        let md5Data = Insecure.MD5.hash(data: inputData)
        let md5Hex = md5Data.map { String(format: "%02hhx", $0) }.joined()
        
        return md5Hex
    }
}
