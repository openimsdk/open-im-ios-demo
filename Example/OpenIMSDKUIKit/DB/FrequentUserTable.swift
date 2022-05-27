
import Foundation
import JNFoundation
import WCDBSwift
import OpenIMSDK

class FrequentUserTable: TableAble {
    var db: Database
    init(db: Database) {
        self.db = db
    }
    
    func setItems(_ items: [Entity]) -> Bool {
        if items.isEmpty { return true }
        do {
            try db.insertOrReplace(objects: items, intoTable: self.name)
            return true
        } catch let err {
            JPrint(items: err)
            return false
        }
    }
    
    func getItem(by id: String) -> Entity? {
        let item: Entity? = try! db.getObject(fromTable: self.name, where: Entity.Properties.id == id)
        return item
    }
    
    func getAll() -> [Entity] {
        let items: [Entity] = try! db.getObjects(fromTable: self.name)
        return items
    }
    
    struct Entity: TableCodable {
        var id: String
        var name: String?
        var faceUrl: String?
        
        enum CodingKeys: String, CodingTableKey {
            typealias Root = Entity
            static let objectRelationalMapping: TableBinding<FrequentUserTable.Entity.CodingKeys> = TableBinding.init(CodingKeys.self)
            case id, name, faceUrl
            static var columnConstraintBindings: [FrequentUserTable.Entity.CodingKeys : ColumnConstraintBinding]? {
                return [
                    id: ColumnConstraintBinding.init(isPrimary: true),
                ]
            }
        }
        
        func toItem() -> OIMUserInfo {
            let item = OIMUserInfo.init()
            item.userID = self.id
            item.nickname = self.name
            item.faceURL = self.faceUrl
            return item
        }
    }
}
