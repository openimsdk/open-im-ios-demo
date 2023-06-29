
import OUICore

class ApplicationViewModel {
    var groupApplication: GroupApplicationInfo!
    var friendApplication: FriendApplication!
    
    init(groupApplication: GroupApplicationInfo?, friendApplication: FriendApplication?) {

        self.groupApplication = groupApplication
        self.friendApplication = friendApplication
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var companyString: NSMutableAttributedString {
        get {
            let a = NSMutableAttributedString(string: "申请加入".innerLocalized(), attributes: [ NSAttributedString.Key.foregroundColor: UIColor.c8E9AB0])
            let c = NSAttributedString(string: groupApplication.groupName ?? "",
                                       attributes: [ NSAttributedString.Key.foregroundColor: UIColor.c0089FF])
            a.append(c)
            
            return a
        }
    }
    
    var joinSourceString: String {
        get {
            var v = "来源：".innerLocalized()
            switch groupApplication.joinSource {
            case .search:
                v += "搜索".innerLocalized()
            case .QRCode:
                v += "二维码".innerLocalized()
            case .invited:
                v += "邀请".innerLocalized()
            }
            
            return v
        }
    }
    
    var requestDescString: String {
        get {
            return ((groupApplication != nil ? groupApplication.reqMsg : friendApplication.reqMsg) ?? "") ?? ""
        }
    }
    
    func accept(completion: @escaping CallBack.StringOptionalReturnVoid) {
        if let friendApplication = friendApplication {
            IMController.shared.acceptFriendApplication(uid: friendApplication.fromUserID) { [weak self] r in
                completion(r)
                // 发送通知，告诉列表入群申请或者好友申请数量发生改变
                NotificationCenter.default.post(name: ContactsViewModel.NotificationApplicationCountChanged, object: nil)
            }
            
        } else if let groupApplication = groupApplication {
            IMController.shared.acceptGroupApplication(groupID: groupApplication.groupID, fromUserId: groupApplication.userID!) { [weak self] r in
                completion(r)
                // 发送通知，告诉列表入群申请或者好友申请数量发生改变
                NotificationCenter.default.post(name: ContactsViewModel.NotificationApplicationCountChanged, object: nil)
            }
        }
    }
    
    func refuse(completion: @escaping CallBack.StringOptionalReturnVoid) {
        if let friendApplication = friendApplication {
            IMController.shared.refuseFriendApplication(uid: friendApplication.fromUserID ) { [weak self] r in
                completion(r)
                // 发送通知，告诉列表入群申请或者好友申请数量发生改变
                NotificationCenter.default.post(name: ContactsViewModel.NotificationApplicationCountChanged, object: nil)
            }
            
        } else if let groupApplication = groupApplication {
            IMController.shared.refuseGroupApplication(groupID: groupApplication.groupID, fromUserId: groupApplication.userID!) { [weak self] r in
                completion(r)
                // 发送通知，告诉列表入群申请或者好友申请数量发生改变
                NotificationCenter.default.post(name: ContactsViewModel.NotificationApplicationCountChanged, object: nil)
            }
        }
    }
}
