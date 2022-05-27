
import Foundation
import JNFoundation
import RxSwift
import OpenIMSDK

class UserModel: Model, ModelAble {
    
    //MARK: 数据库读写
    func getAllTables() -> [Table] {
        return [_table]
    }
    
    private lazy var _table = FrequentUserTable.init(db: self.selfDB)
    
    func setItem(_ item: OIMUserInfo) -> Bool {
        let entity = item.toEntity()
        return _table.setItems([entity])
    }
    @discardableResult
    func setItems(_ items: [OIMUserInfo]) -> Bool {
        let entities: [FrequentUserTable.Entity] = items.compactMap{$0.toEntity()}
        return _table.setItems(entities)
    }
    
    func getItem(by id: String) -> FrequentUserTable.Entity? {
        let entity = _table.getItem(by: id)
        return entity
    }
    
    func getAllItems() -> [FrequentUserTable.Entity] {
        let items = _table.getAll()
        return items
    }
}

extension OIMUserInfo {
    func toEntity() -> FrequentUserTable.Entity {
        let entity = FrequentUserTable.Entity.init(id: self.userID!, name: self.nickname, faceUrl: self.faceURL)
        return entity
    }
}
