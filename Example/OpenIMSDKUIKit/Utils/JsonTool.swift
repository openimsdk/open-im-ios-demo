
import Foundation

 struct JsonTool {
     static func fromJson<T: Decodable>(_ json: String, toClass: T.Type) -> T? {
        let decoder = JSONDecoder()
        do {
          let result = try decoder.decode(toClass, from: json.data(using: .utf8)!)
          return result
        } catch DecodingError.dataCorrupted(_) {
          return nil
        } catch DecodingError.keyNotFound(_, _) {
          return nil
        } catch DecodingError.typeMismatch(_, _) {
          return nil
        } catch DecodingError.valueNotFound(_, _) {
          return nil
        } catch _ {
          return nil
        }
    }

     static func toJson<T: Encodable>(fromObject: T) -> String {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(fromObject)
            guard let json = String.init(data: data, encoding: .utf8) else {
                fatalError("check your data is encodable from utf8!")
            }
            return json
        } catch _ {
            return ""
        }
    }
     
     static func toMap<T: Encodable>(fromObject: T) -> [String: Any] {
         let encoder = JSONEncoder()
         do {
             let data = try encoder.encode(fromObject)
             guard let map = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
                 fatalError("check your data is encodable from utf8!")
             }
             
             print("输出参数：\(map)")
             return map
         } catch _ {
             return [:]
         }
      }
}
