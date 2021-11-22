//
//  GroupListVC.swift
//  EEChat
//
//  Created by Snow on 2021/7/13.
//

import UIKit
import RxSwift
import RxCocoa
import OpenIMSDKiOS

class GroupListVC: BaseViewController {

    @IBOutlet var textField: UITextField!
    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
    }
    
    private var relay = BehaviorRelay<[GroupInfo]>(value: [])
    
    private func bindAction() {
        relay
            .bind(to: tableView.rx.items(cellIdentifier: "cell", cellType: GroupListCell.self))
            { _ , model, cell in
                cell.model = model
            }
            .disposed(by: disposeBag)
        
        tableView.rx.modelSelected(GroupInfo.self)
            .subscribe(onNext: { model in
                EEChatVC.show(groupID: model.groupID!)
            })
            .disposed(by: disposeBag)
        
        textField.rx.text
            .skip(1)
            .debounce(DispatchTimeInterval.microseconds(500), scheduler: MainScheduler.instance)
            .startWith("")
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] text in
                self?.request(key: text!)
            })
            .disposed(by: disposeBag)
    }
    
    private func request(key: String) {
//        OIMManager.getJoinedGroupList { [weak self] result in
//            guard let self = self else { return }
//            if case .success(let array) = result {
//                let array = key.isEmpty ? array : array.filter{ $0.groupName.range(of: key, options: .caseInsensitive) != nil }
//                self.relay.accept(array)
//            }
//        }
        OpenIMiOSSDK.shared().getJoinedGroupList { [weak self] array in
            guard let self = self else { return }
            let array = key.isEmpty ? array : array.filter{ $0.groupName!.range(of: key, options: .caseInsensitive) != nil }
            DispatchQueue.main.async {
                self.relay.accept(array)
            }
        } onError: { code, msg in
            
        }

    }

}
