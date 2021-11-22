//
//  NewFriendVC.swift
//  EEChat
//
//  Created by Snow on 2021/4/21.
//

import UIKit
import RxCocoa
import OpenIMSDKiOS
import OpenIMUI

class NewFriendVC: BaseViewController {
    
    override class func show(param: Any? = nil, callback: BaseViewController.Callback? = nil) {
//        _ = rxRequest(showLoading: true, action: { OIMManager.getFriendApplicationList($0) })
//            .subscribe(onSuccess: { array in
//                super.show(param: array, callback: callback)
//            })
        OpenIMiOSSDK.shared().getFriendApplicationList { array in
            DispatchQueue.main.async {
                super.show(param: array, callback: callback)
            }
        } onError: { code, msg in
            
        }

    }

    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
    }
    
    private lazy var relay = BehaviorRelay<[UserInfo]>(value: [])
    
    private func bindAction() {
        assert(param is [UserInfo])
        let array = param as! [UserInfo]
        relay.accept(array)
        
        relay
            .bind(to: tableView.rx.items(cellIdentifier: "cell", cellType: NewFriendCell.self))
            { _, model, cell in
                cell.model = model
            }
            .disposed(by: disposeBag)
        
        tableView.rx.modelSelected(UserInfo.self)
            .subscribe(onNext: { model in
                if model.flag == 2 {
//                    OIMManager.getConversation(type: .c2c, id: model.info.uid) { result in
//                        if case let .success(conversation) = result {
//                            FriendSettingVC.show(param: conversation)
//                        }
//                    }
                    OpenIMiOSSDK.shared().getOneConversation(model.uid!, session: 1) { conversation in
                        DispatchQueue.main.async {
                            FriendSettingVC.show(param: conversation)
                        }
                    } onError: { code, msg in
                        
                    }

                }
            })
            .disposed(by: disposeBag)
    }

}
