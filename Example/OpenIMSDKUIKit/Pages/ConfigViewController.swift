//
//  ConfigViewController.swift
//  OpenIMSDKUIKit_Example
//
//  Created by x on 2022/7/13.
//  Copyright © 2022 rentsoft. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import OpenIMSDK

class ConfigCell: UITableViewCell {
    
    var titleLabel: UILabel = UILabel()
    var inputTextFiled: UnderlineTextField = UnderlineTextField()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let st = UIStackView.init(arrangedSubviews: [titleLabel, inputTextFiled])
        st.axis = .vertical
        contentView.addSubview(st)
        
        inputTextFiled.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        
        st.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

let severAddressKey = "com.oimuikit.adr"
let bussinessSeverAddrKey = "com.oimuikit.bussiness.api.adr"
let sdkAPIAddrKey = "com.oimuikit.sdk.api.adr"
let sdkWSAddrKey = "com.oimuikit.sdk.ws.adr"
let sdkObjectStorageKey = "com.oimuikit.sdk.os"

class ConfigViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    var severAddress = UserDefaults.standard.string(forKey: severAddressKey) ??
    "http://121.37.25.71"
    var bussinessSeverAddr = UserDefaults.standard.string(forKey: bussinessSeverAddrKey) ??
    "http://121.37.25.71:10004"
    var sdkAPIAddr = UserDefaults.standard.string(forKey: sdkAPIAddrKey) ??
    "http://121.37.25.71:10002"
    var sdkWSAddr = UserDefaults.standard.string(forKey: sdkWSAddrKey) ??
    "http://121.37.25.71:10001"
    var sdkObjectStorage = UserDefaults.standard.string(forKey: sdkObjectStorageKey) ??
    "minio"
    
    var data: [Dictionary<String, String>] = [];
    
    let list: UITableView = {
        let t = UITableView.init()
        t.register(ConfigCell.self, forCellReuseIdentifier: "cell")
        return t
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = .init(title: "保存", style: .done, target: self, action: #selector(saveAddress))
        
        list.delegate = self
        list.dataSource = self
        view.addSubview(list)
        
        list.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        updateIP()
    }
    
    func updateIP(index: Int = 0, newValue: String = "") {
        
        if index == 0 && !newValue.isEmpty {
            bussinessSeverAddr = bussinessSeverAddr.replacingOccurrences(of: severAddress, with: newValue)
            sdkAPIAddr = sdkAPIAddr.replacingOccurrences(of: severAddress, with: newValue)
            sdkWSAddr = sdkWSAddr.replacingOccurrences(of: severAddress, with: newValue)
            
            severAddress = newValue
        } else if index == 1 {
            bussinessSeverAddr = newValue
        } else if index == 2 {
            sdkAPIAddr = newValue
        } else if index == 3 {
            sdkWSAddr = newValue
        } else if index == 4 {
            sdkObjectStorage = newValue
        }
        
        data = [["服务器地址:(点击修改IP,保存后重启生效)": severAddress],
                ["业务服务器地址": bussinessSeverAddr],
                ["IM API地址": sdkAPIAddr],
                ["IM WS地址": sdkWSAddr],
                ["对象存储": sdkObjectStorage]]
    }
    
    func reloadRelatedRows() {
        DispatchQueue.main.async {
            
            self.list.performBatchUpdates {
                
                self.list.reloadRows(at: [.init(row: 1, section: 0),
                                          .init(row: 2, section: 0),
                                          .init(row: 3, section: 0)],
                                     with: .none)
            }
        }
    }
    
    @objc func saveAddress() {
        
        self.view.endEditing(true)
        
        let ud = UserDefaults.standard
        ud.set(severAddress, forKey: severAddressKey)
        ud.set(bussinessSeverAddr, forKey: bussinessSeverAddrKey)
        ud.set(sdkAPIAddr, forKey: sdkAPIAddrKey)
        ud.set(sdkWSAddr, forKey: sdkWSAddrKey)
        ud.set(sdkObjectStorage, forKey: sdkObjectStorageKey)
    }
}

extension ConfigViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: ConfigCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ConfigCell
        let item = data[indexPath.row];
        
        cell.titleLabel.text = item.keys.first
        cell.inputTextFiled.text = item.values.first
        cell.inputTextFiled.rx
            .controlEvent([.editingChanged, .editingDidEnd])
            .asObservable().subscribe(onNext: {[weak self, weak cell] t in
                print("inputTextFiled:\(cell?.inputTextFiled.text) ")
                
                self?.updateIP(index: indexPath.row, newValue: cell?.inputTextFiled.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
                if indexPath.row == 0 {
                    self?.reloadRelatedRows()
                }
                
            })
            .disposed(by: disposeBag)
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    
}
