//
//  BlacklistVC.swift
//  EEChat
//
//  Created by Snow on 2021/4/27.
//

import UIKit
import RxCocoa
import OpenIMSDKiOS

class BlacklistVC: BaseViewController {
    
    override class func show(param: Any? = nil, callback: BaseViewController.Callback? = nil) {
//        _ = rxRequest(showLoading: true, action: { OIMManager.getBlackList($0) })
//            .subscribe(onSuccess: { array in
//                super.show(param: array, callback: callback)
//            })
        OpenIMiOSSDK.shared().getBlackList { array in
            DispatchQueue.main.async {
                super.show(param: array, callback: callback)
            }
        } onError: { code, msg in
            
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
    }
    
    @IBOutlet var tableView: UITableView!
    
    private let relay = BehaviorRelay<[UserInfo]>(value: [])
    private func bindAction() {
        assert(param is [UserInfo])
        let array = param as! [UserInfo]
        relay.accept(array)
        
        relay
            .bind(to: tableView.rx.items(cellIdentifier: "cell",
                                         cellType: BlacklistCell.self))
            { [unowned self] row, model, cell in
                cell.model = model
                cell.removeCallback = {
                    self.removeAction(model: model, row: row)
                }
            }
            .disposed(by: disposeBag)
    }

    func removeAction(model: UserInfo, row: Int) {
//        rxRequest(showLoading: true, action: { OIMManager.deleteFromBlackList(uid: model.uid, callback: $0) })
//            .subscribe(onSuccess: { [unowned self] _ in
//                var array = self.relay.value
//                array.remove(at: row)
//                self.relay.accept(array)
//            })
//            .disposed(by: disposeBag)
        OpenIMiOSSDK.shared().delete(fromBlackList: model.uid!) { msg in
            DispatchQueue.main.async {
                var array = self.relay.value
                array.remove(at: row)
                self.relay.accept(array)
            }
        } onError: { code, msg in
            
        }

        
    }
    
}
