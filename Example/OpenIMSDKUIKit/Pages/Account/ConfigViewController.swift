
import Foundation
import UIKit
import RxSwift
import SnapKit

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
let adminSeverAddrKey = "com.oiuikit.admin.adr"
let bussinessSeverAddrKey = "com.oimuikit.bussiness.api.adr"
let sdkAPIAddrKey = "com.oimuikit.sdk.api.adr"
let sdkWSAddrKey = "com.oimuikit.sdk.ws.adr"
let sdkObjectStorageKey = "com.oimuikit.sdk.os"
let useDomainKey = "com.oimuikit.use.domain"
let useTLSKey = "com.oimuikit.use.TLS"

let defaultIP = "198.18.3.106"
let defaultDomain = "web.rentsoft.cn"

class ConfigViewController: UIViewController {

    let disposeBag = DisposeBag()

    let ports = [bussinessSeverAddrKey: ":10008", sdkAPIAddrKey: ":10002", sdkWSAddrKey: ":10001"]
    let routes = [bussinessSeverAddrKey: "/chat", sdkAPIAddrKey: "/api", sdkWSAddrKey: "/msg_gateway"]
    let scheme = [bussinessSeverAddrKey: "http", sdkAPIAddrKey: "http", sdkWSAddrKey: "ws"]

    private var severAddress = UserDefaults.standard.string(forKey: severAddressKey) ?? defaultDomain
    private var bussinessSeverAddr = UserDefaults.standard.string(forKey: bussinessSeverAddrKey) ??
    "http://\(defaultIP):10008"
    private var sdkAPIAddr = UserDefaults.standard.string(forKey: sdkAPIAddrKey) ??
    "http://\(defaultIP):10002"
    private var sdkWSAddr = UserDefaults.standard.string(forKey: sdkWSAddrKey) ??
    "ws://\(defaultIP):10001"
    private var sdkObjectStorage = UserDefaults.standard.string(forKey: sdkObjectStorageKey) ??
    "minio"
    
    var modifyIP = ""
    var modifyDomain = ""

    var data: [Dictionary<String, String>] = [];

    let list: UITableView = {
        let t = UITableView.init()
        t.register(ConfigCell.self, forCellReuseIdentifier: "cell")
        return t
    }()

    lazy var tlsSwitcher: UISwitch = {
        let t = UISwitch()
        t.isOn = UserDefaults.standard.value(forKey: useTLSKey) != nil ? UserDefaults.standard.bool(forKey: useTLSKey) : true
        t.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self] in

            guard let sself = self else { return }
            sself.view.endEditing(false)
            sself.updateIP(newValue: sself.severAddress)
            sself.list.reloadData()
        }).disposed(by: disposeBag)

        return t
    }()

    lazy var domainSwitcher: UISwitch = {
        let t = UISwitch()
        t.isOn = UserDefaults.standard.value(forKey: useDomainKey) != nil ? UserDefaults.standard.bool(forKey: useDomainKey) : true
        t.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self] in
            guard let sself = self else { return }
            sself.view.endEditing(false)
            
            if t.isOn {
                sself.updateIP(newValue: sself.modifyDomain.isEmpty ? defaultDomain : sself.modifyDomain)
            } else {
                sself.updateIP(newValue: sself.modifyIP.isEmpty ? defaultIP : sself.modifyIP)
            }
            sself.list.reloadData()
        }).disposed(by: disposeBag)

        return t
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        self.navigationItem.rightBarButtonItem = .init(title: "保存", style: .done, target: self, action: #selector(saveAddress))
        list.delegate = self
        list.dataSource = self
        view.addSubview(list)
        
        let label1 = UILabel()
        label1.text = "使用TLS"
        
        let label2 = UILabel()
        label2.text = "使用域名"

        let hs = UIStackView.init(arrangedSubviews: [UIView(), label1, tlsSwitcher, label2, domainSwitcher, UIView()])
        hs.distribution = .equalCentering
        hs.alignment = .center
        view.addSubview(hs)

        hs.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
        }

        list.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalTo(hs.snp.bottom).offset(8)
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateIP(newValue:severAddress , force: true)
        list.reloadData()
    }
    
    func updateIP(index: Int = 0, newValue: String = "", force: Bool = false) {

        if (index == 0 && !newValue.isEmpty) || force {
            severAddress = newValue
            
            if !force {
                if domainSwitcher.isOn {
                    modifyDomain = newValue
                } else {
                    modifyIP = newValue
                }
            }
            
            bussinessSeverAddr = (tlsSwitcher.isOn ? scheme[bussinessSeverAddrKey]!  + "s" : scheme[bussinessSeverAddrKey]!) +
            "://" + newValue +
            (domainSwitcher.isOn ? routes[bussinessSeverAddrKey]! : ports[bussinessSeverAddrKey]!)
            
            sdkAPIAddr = (tlsSwitcher.isOn ? scheme[sdkAPIAddrKey]!  + "s" : scheme[sdkAPIAddrKey]!) +
            "://" + newValue +
            (domainSwitcher.isOn ? routes[sdkAPIAddrKey]! : ports[sdkAPIAddrKey]!)
            
            sdkWSAddr = (tlsSwitcher.isOn ? scheme[sdkWSAddrKey]!  + "s" : scheme[sdkWSAddrKey]!) +
            "://" + newValue +
            (domainSwitcher.isOn ? routes[sdkWSAddrKey]! : ports[sdkWSAddrKey]!)
        }
        else if index == 1 {
            bussinessSeverAddr = (tlsSwitcher.isOn ? scheme[bussinessSeverAddrKey]!  + "s" : scheme[bussinessSeverAddrKey]!) +
            "://" + newValue +
            (domainSwitcher.isOn ? routes[bussinessSeverAddrKey]! : ports[bussinessSeverAddrKey]!)
        } else if index == 2 {
            sdkAPIAddr = (tlsSwitcher.isOn ? scheme[sdkAPIAddrKey]!  + "s" : scheme[sdkAPIAddrKey]!) +
            "://" + newValue +
            (domainSwitcher.isOn ? routes[sdkAPIAddrKey]! : ports[sdkAPIAddrKey]!)
        } else if index == 3 {
            sdkWSAddr = (tlsSwitcher.isOn ? scheme[sdkWSAddrKey]!  + "s" : scheme[sdkWSAddrKey]!) +
            "://" + newValue +
            (domainSwitcher.isOn ? routes[sdkWSAddrKey]! : ports[sdkWSAddrKey]!)
        } else if index == 4 {
            sdkObjectStorage = newValue
        }

        data = [["服务器地址:(点击修改IP/域名,保存后重启生效)": severAddress],
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
        ud.set(tlsSwitcher.isOn, forKey: useTLSKey)
        ud.set(domainSwitcher.isOn, forKey: useDomainKey)
        ud.synchronize()

        let alert = UIAlertController.init(title: nil, message: "保存成功，重启app后设置生效", preferredStyle: .alert)
        alert.addAction(.init(title: "确定", style: .cancel))

        self.present(alert, animated: true)
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
            .controlEvent([.editingChanged])
            .asObservable().subscribe(onNext: {[weak self, weak cell] t in
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
