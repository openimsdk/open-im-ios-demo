
import OUICore
import RxSwift
import ProgressHUD
import LocalAuthentication

class ScreenLockSettingViewController: UITableViewController {
    
    func showScreenLock(inController:UIViewController, onFailure: @escaping () -> Void) {
        if AccountViewModel.userID == nil {
            // 未登录，不展示
            return
        }
        self.onFailure = onFailure
        
        if LocalAuthManager.enablePasswordLock {
            if let vc = JKLLockScreenViewController(mode: .normal) {
                vc.delegate = self
                vc.dataSource = self
                
                addChild(vc)
                view.addSubview(vc.view)
                vc.view.center = view.center
                
                modalPresentationStyle = .overFullScreen
                inController.present(self, animated: true)
            }
        }
    }
    
    let _disposeBag = DisposeBag()
    
    private var rowItems: [RowType] = [.enablePasswordLock]
    private var enablePasswordLock = false
    private var enableBiometrics = false
    private var isBiometricsAvailable = false
    private var biometricsType = ""
    private var unlockFailureMaxTimes = 3
    private var onFailure: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "手势密码设置".localized()
        view.backgroundColor = DemoUI.color_F7F7F7

        configureTableView()
        setupData()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        let hasSet = LocalAuthManager.hasSetPassword
        
        if !hasSet {
            enablePasswordLock = false
            rowItems = [.enablePasswordLock]
            
            tableView.performBatchUpdates {
                tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            }

            LocalAuthManager.enablePasswordLock = enablePasswordLock
        } else {
            if LocalAuthManager.enablePasswordLock {
                rowItems = RowType.allCases
            }
            tableView.reloadData()
        }
    }

    private func configureTableView() {
        tableView = UITableView(frame: tableView.frame, style: .insetGrouped)
        tableView.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.className)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.className)
        tableView.tableFooterView = UIView()
    }

    private func setupData() {
        //生物解锁
        let authenticationContext = LAContext()
        var error: NSError?
        isBiometricsAvailable = authenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        authenticationContext.biometryType == .faceID ? (biometricsType = "面容".localized()) : (biometricsType = "指纹".localized())
        enablePasswordLock = LocalAuthManager.enablePasswordLock
        enableBiometrics = isBiometricsAvailable ? LocalAuthManager.enableBiometrics : false
        
        if enablePasswordLock {
            rowItems = RowType.allCases
        }
        tableView.reloadData()
    }
    
    @objc func toggleEnablePasswordLock() {
        enablePasswordLock = !enablePasswordLock
        
        if !LocalAuthManager.hasSetPassword {
            setPasswordLock()
        } else {
            reloadEnablePasswordLock()
            LocalAuthManager.updatePassword(nil)
        }
    }
    
    private func reloadEnablePasswordLock() {
        enablePasswordLock ? (rowItems = RowType.allCases) : (rowItems = [.enablePasswordLock])

        tableView.performBatchUpdates {
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
        
        LocalAuthManager.enablePasswordLock = enablePasswordLock
    }
    
    @objc func toggleEnableBiometrics() {
        
        guard isBiometricsAvailable else {
            ProgressHUD.error("设备不支持生物识别。")
            tableView.performBatchUpdates {
                tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
            }
            return
        }
        enableBiometrics = !enableBiometrics
        
        LocalAuthManager.enableBiometrics = enableBiometrics
    }
    
    func setPasswordLock()  {
        let hasSet = LocalAuthManager.hasSetPassword
        
        if let vc = JKLLockScreenViewController(mode: hasSet ? .change : .new) {
            vc.modalPresentationStyle = .overFullScreen
            vc.delegate = self
            vc.dataSource = self
            
            present(vc, animated: true)
        }
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return rowItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType: RowType = rowItems[indexPath.row]
        
        switch rowType {
//        case.tips:
//            let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.className, for: indexPath)
//            cell.textLabel?.text = "开启后，可使用".localized() + biometricsType + "解锁".localized()
//            cell.textLabel?.textColor = DemoUI.color_999999
//            cell.textLabel?.font = .systemFont(ofSize: 12)
//            cell.backgroundColor = .clear
//            return cell
        case .enablePasswordLock:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.className, for: indexPath) as! SwitchTableViewCell
            cell.titleLabel.text = rowType.title
            cell.switcher.isOn = enablePasswordLock
            cell.switcher.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self] _ in
                self?.toggleEnablePasswordLock()
            }).disposed(by: cell.disposeBag)
            
            return cell
        case .enableBiometrics:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.className, for: indexPath) as! SwitchTableViewCell
            cell.titleLabel.text = "开启".localized() + biometricsType + "解锁".localized()
            cell.switcher.isOn = enableBiometrics
            cell.switcher.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self] _ in
                self?.toggleEnableBiometrics()
            }).disposed(by: cell.disposeBag)
            
            return cell
        }
        
//        let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className, for: indexPath) as! OptionTableViewCell
//
//        cell.titleLabel.text = rowType.title
        
//        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        let rowType: RowType = rowItems[indexPath.row]
        
//        if rowType == .tips {
//            return 30
//        } else {
        return 60.h
//        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        16
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType: RowType = rowItems[indexPath.row]
        switch rowType {
//        case .resetGestureLock:
//            setPasswordLock()
        default:
            break
        }
    }

    enum RowType: CaseIterable {
    
        case enablePasswordLock
        case enableBiometrics
//        case tips
//        case resetGestureLock
        
        var title: String {
            switch self {
            case .enablePasswordLock:
                return "开启".localized() + "密码锁定".localized()
            case .enableBiometrics:
                return "开启".localized() + "生物识别".localized()
//            case .tips:
//                return "开启后，可使用".localized() + "面容ID/指纹解锁".localized()
//            case .resetGestureLock:
//                return "重置手势密码".localized()
            }
        
        }
    }
}

extension ScreenLockSettingViewController: JKLLockScreenViewControllerDelegate, JKLLockScreenViewControllerDataSource {
    @objc func lockScreenViewController(_ lockScreenViewController: JKLLockScreenViewController!, pincode: String!) -> Bool {
        LocalAuthManager.currentPassword() == pincode
    }
    
    @objc func allowTouchIDLockScreenViewController(_ lockScreenViewController: JKLLockScreenViewController!) -> Bool {
        true
    }
    
    @objc func lockScreenViewControllerDidFinish(_ lockScreenViewController: JKLLockScreenViewController) {
        dismiss(animated: true)
    }
    
    @objc func unlockWasSuccessfulLockScreenViewController(_ lockScreenViewController: JKLLockScreenViewController!, pincode: String!) {
        reloadEnablePasswordLock()
        LocalAuthManager.updatePassword(pincode)
    }
    
    @objc func unlockWasFailureLockScreenViewController(_ lockScreenViewController: JKLLockScreenViewController!) {
        unlockFailureMaxTimes -= 1
        
        if unlockFailureMaxTimes <= 0 {
            LocalAuthManager.updatePassword(nil)
            onFailure?()
        }
    }
    
    func unlockWasCancelledLockScreenViewController(_ lockScreenViewController: JKLLockScreenViewController!) {
        enablePasswordLock = false
        reloadEnablePasswordLock()
    }
}
