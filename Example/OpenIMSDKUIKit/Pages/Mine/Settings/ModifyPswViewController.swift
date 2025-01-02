import OUICore
import RxSwift
import ProgressHUD

class ModifyPswViewController: UIViewController {
    private lazy var oldPswTextFiled: UITextField = {
        let v = UITextField()
        let t = UILabel()
        t.text = "旧密码：".innerLocalized()
        v.leftView = t
        v.leftViewMode = .always
        
        return v
    }()
    
    private lazy var newPswTextFiled: UITextField = {
        let v = UITextField()
        let t = UILabel()
        t.text = "新密码：".innerLocalized()
        v.leftView = t
        v.leftViewMode = .always
        
        return v
    }()
    
    private lazy var againPswTextFiled: UITextField = {
        let v = UITextField()
        let t = UILabel()
        t.text = "确认密码：".innerLocalized()
        v.leftView = t
        v.leftViewMode = .always
        
        return v
    }()
    
    private let disposeBag = DisposeBag()
    private let viewModel = SettingViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "修改密码".innerLocalized()
        view.backgroundColor = .viewBackgroundColor
        
        let confirmButton = UIBarButtonItem()
        confirmButton.title = "确定".innerLocalized()
        confirmButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            
            guard let oldPsw = oldPswTextFiled.text?.trimmingCharacters(in: .whitespacesAndNewlines), !oldPsw.isEmpty else {
                presentAlert(title: "plsEnterOldPwd".innerLocalized())
                return
            }
            guard let newPsw = newPswTextFiled.text?.trimmingCharacters(in: .whitespacesAndNewlines), !newPsw.isEmpty else {
                return
            }
            guard newPsw.validatePassword() else {
                presentAlert(title: "passwordFormatError".innerLocalized())
                return
            }
            guard let againPsw = againPswTextFiled.text?.trimmingCharacters(in: .whitespacesAndNewlines), !againPsw.isEmpty else {
                return
            }
            guard newPsw != oldPsw else {
                presentAlert(title: "newAndOldAreSame".innerLocalized())
                return
            }
            guard newPsw == againPsw else {
                presentAlert(title: "twicePwdNoSame".innerLocalized())
                return
            }
            
            viewModel.changePassword(current: oldPsw, to: newPsw) { errCode, errMsg in
                if errCode != 0 {
                    ProgressHUD.error(errMsg)
                } else {
                    IMController.shared.logout { r in
                        NotificationCenter.default.post(name: .init("logout"), object: nil)
                    }
                }
            }
        }).disposed(by: disposeBag)
        
        navigationItem.rightBarButtonItem = confirmButton
        
        let contentView = UIView()
        contentView.layer.cornerRadius = 5
        contentView.backgroundColor = .cellBackgroundColor
        
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
        }
        
        let line1 = UIView()
        line1.backgroundColor = .sepratorColor
        let line2 = UIView()
        line2.backgroundColor = .sepratorColor

        let vStack = UIStackView(arrangedSubviews: [oldPswTextFiled, line1, newPswTextFiled, line2, againPswTextFiled])
        vStack.axis = .vertical
        vStack.spacing = 8
        
        contentView.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        
        oldPswTextFiled.snp.makeConstraints { make in
            make.height.equalTo(42)
        }
        
        newPswTextFiled.snp.makeConstraints { make in
            make.height.equalTo(42)
        }
        
        againPswTextFiled.snp.makeConstraints { make in
            make.height.equalTo(42)
        }
        
        line1.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
        
        line2.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
        
        #if ENABLE_ORGANIZATION
        vStack.removeArrangedSubview(oldPswTextFiled)
        #endif
    }
}
