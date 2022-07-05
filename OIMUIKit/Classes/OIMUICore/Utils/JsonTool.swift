
import Foundation

struct JsonTool {
    static func fromJson<T: Decodable>(_ json: String, toClass: T.Type) -> T? {
        let decoder = JSONDecoder()
        do {
            let result = try decoder.decode(toClass, from: json.data(using: .utf8)!)
            return result
        } catch let DecodingError.dataCorrupted(context) {
            return nil
        } catch let DecodingError.keyNotFound(_, context) {
            return nil
        } catch let DecodingError.typeMismatch(_, context) {
            return nil
        } catch let DecodingError.valueNotFound(_, context) {
            return nil
        } catch {
            return nil
        }
    }

    static func toJson<T: Encodable>(fromObject: T) -> String {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(fromObject)
            guard let json = String(data: data, encoding: .utf8) else {
                fatalError("check your data is encodable from utf8!")
            }
            return json
        } catch let err {
            return ""
        }
    }
}
