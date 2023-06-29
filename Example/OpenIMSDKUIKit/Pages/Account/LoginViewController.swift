
import UIKit
import RxSwift
import RxCocoa
import RxGesture
import MMBAlertsPickers
import SnapKit
import ProgressHUD

class LoginViewController: UIViewController {
    
    private let _disposeBag = DisposeBag()
    
    private var _areaCode = "+86"
    
    private let logoImageView: UIImageView = {
        let v = UIImageView(image: UIImage(named: "logo_image"))
        
        return v
    }()
    
    
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.text = "欢迎使用OpenIM".localized()
        v.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        v.textColor = DemoUI.color_0089FF
        v.isUserInteractionEnabled = true
        
        return v
    }()
    
    private lazy var phoneSegment: UIButton = {
        let v = UIButton()
        var placeholder = "手机号".localized()
        v.setTitle(placeholder, for: .normal)
        v.setTitleColor(DemoUI.color_8E9AB0, for: .normal)
        v.titleLabel?.font = DemoUI.smallFont
        
        return v
    }()
    
    lazy var registerButton: UIButton = {
        let t = UIButton(type: .system)
        t.setTitle("注册账号".localized(), for: .normal)
        t.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        t.snp.makeConstraints { make in
            make.width.equalTo(70)
        }
        t.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let sself = self else { return }
            sself.toRegister()
        }).disposed(by: _disposeBag)
        
        return t
    }()
    
    lazy var forgotButton: UIButton = {
        let t = UIButton(type: .system)
        t.setTitle("忘记密码".localized(), for: .normal)
        t.setTitleColor(DemoUI.color_8E9AB0, for: .normal)
        t.titleLabel?.font = .systemFont(ofSize: 12)

        t.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let sself = self else { return }
            sself.toForgotPasswordLogin()
        }).disposed(by: _disposeBag)
        
        return t
    }()
    
    lazy var codeLoginButton: UIButton = {
        let t = UIButton(type: .custom)
        t.setTitle("验证码登录".localized(), for: .normal)
        t.setTitle("密码登录".localized(), for: .selected)
        t.setTitleColor(DemoUI.color_0089FF, for: .selected)
        t.setTitleColor(DemoUI.color_0089FF, for: .normal)
        t.titleLabel?.font = .systemFont(ofSize: 12)
        
        t.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let sself = self else { return }
            t.isSelected = !t.isSelected
            sself.toCodeLogin()
        }).disposed(by: _disposeBag)
        return t
    }()
    
    lazy var checkBoxButton: UIButton = {
        let t = UIButton(type: .custom)
        t.snp.makeConstraints { make in
            make.size.equalTo(20)
        }
        t.setImage(UIImage(named: "common_checkbox_unselected"), for: .normal)
        t.setImage(UIImage(named: "common_checkbox_selected"), for: .selected)
        t.isSelected = true
        
        t.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let sself = self else { return }
            sself.agreeProtocal()
        }).disposed(by: _disposeBag)
        
        return t
    }()
    
    var phone: String? {
        return phoneTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    var password: String? {
        return !codeLoginButton.isSelected ? passwordTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) : nil
    }
    
    var areaCode: String {
        return _areaCode
    }
    
    var verificationCode: String? {
        return codeLoginButton.isSelected ? passwordTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) : nil
    }
    
    let countDownButton: CountDownTimerButton = {
        let t = CountDownTimerButton()
        
        return t
    }()
    
    lazy var areaCodeButton: UIButton = {
        let t = UIButton(type: .custom)
        t.setTitle("\(_areaCode)", for: .normal)
        t.setTitleColor(DemoUI.color_0C1C33, for: .normal)
        t.titleLabel?.font = .systemFont(ofSize: 17)
        
        t.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let sself = self else { return }
            let alert = UIAlertController(style: .actionSheet, title: "Phone Codes")
            alert.addLocalePicker(type: .phoneCode) {[weak self] info in
                // action with selected object
                guard let phoneCode = info?.phoneCode else {return}
                self?._areaCode = phoneCode
                t.setTitle("\(phoneCode)", for: .normal)
            }
            
            alert.addAction(title: "取消".localized(), style: .cancel)
            sself.present(alert, animated: true)
        }).disposed(by: _disposeBag)
        return t
    }()
    
    private lazy var phoneTextField: UITextField = {
        let v = UITextField()
        v.keyboardType = .numberPad
        var placeholder = "请输入手机号码".localized()
        v.placeholder = placeholder
        v.clearButtonMode = .whileEditing
        v.text = AccountViewModel.perLoginAccount
        v.textColor = DemoUI.color_0C1C33
        
        return v
    }()
    
    private let passwordLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 14)
        v.textColor = DemoUI.color_0C1C33
        v.text = "密码".localized()
        v.textColor = DemoUI.color_8E9AB0
        v.font = DemoUI.smallFont
        
        return v
    }()
    
    lazy var eyesButton: UIButton = {
        let t = UIButton(type: .custom)
        t.snp.makeConstraints { make in
            make.size.equalTo(20)
        }
        t.setImage(UIImage(named: "ic_eyes_close"), for: .normal)
        t.setImage(UIImage(named: "ic_eyes_open"), for: .selected)
        t.isSelected = false
        
        t.rx.tap.subscribe(onNext: { [weak self] _ in
            t.isSelected = !t.isSelected
            guard let `self` = self else { return }
            self.passwordTextField.isSecureTextEntry = !self.passwordTextField.isSecureTextEntry
        }).disposed(by: _disposeBag)
        
        return t
    }()
    
    private lazy var passwordTextField: UITextField = {
        let v = UITextField()
        v.placeholder = "请输入密码".localized()
        v.isSecureTextEntry = true
        v.rightView = eyesButton
        v.rightViewMode = .always
        v.layer.cornerRadius = DemoUI.cornerRadius
        v.layer.borderColor = DemoUI.color_E8EAEF.cgColor
        v.layer.borderWidth = 1
        v.borderStyle = .none
        v.textColor = DemoUI.color_0C1C33
        v.clearButtonMode = .whileEditing
        v.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        v.leftViewMode = .always
        
        return v
    }()
    
    lazy var loginBtn: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("登录".localized(), for: .normal)
        v.setTitleColor(.white, for: .normal)
        v.backgroundColor = DemoUI.color_0089FF
        v.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
        v.layer.cornerRadius = DemoUI.cornerRadius
        
        return v
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let bgImageView = UIImageView(image: UIImage(named: "login_bg"))
        bgImageView.frame = view.bounds
        view.addSubview(bgImageView)
        
        countDownButton.clickedBlock = { [weak self] sender in
            guard let sself = self,
                  let phone = sself.phoneTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            
            AccountViewModel.requestCode(phone: phone, areaCode: sself.areaCode, useFor: .login) { (errCode, errMsg) in
                if errMsg != nil {
                    ProgressHUD.showError(errMsg)
                } else {
                    ProgressHUD.showSuccess("验证码发送成功".localized())
                }
            }
        }
        
        view.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(88)
            make.size.equalTo(64)
        }
        
        titleLabel.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                let vc = ConfigViewController()
                self?.navigationController?.pushViewController(vc, animated: true)
            }).disposed(by: _disposeBag)
        
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        
        // 登录
        let container: UIView = {
            let v = UIView()
            return v
        }()
        
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(50)
            make.leading.trailing.equalToSuperview().inset(32)
        }
        
        container.addSubview(phoneSegment)
        phoneSegment.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        let line = UIView()
        line.backgroundColor = DemoUI.color_E8EAEF
        
        let accountStack = UIStackView(arrangedSubviews: [areaCodeButton, line, phoneTextField])
        accountStack.spacing = 8
        accountStack.alignment = .center
        accountStack.layer.cornerRadius = DemoUI.cornerRadius
        accountStack.layer.borderColor = DemoUI.color_E8EAEF.cgColor
        accountStack.layer.borderWidth = 1
        
        phoneTextField.setContentHuggingPriority(UILayoutPriority(248), for: .horizontal)
        
        areaCodeButton.snp.makeConstraints { make in
            make.width.equalTo(60)
        }
        
        container.addSubview(accountStack)
        accountStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(phoneSegment.snp.bottom).offset(4)
        }
        
        line.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.top.bottom.equalToSuperview().inset(4)
        }
        
        phoneTextField.snp.makeConstraints { make in
            make.height.equalTo(42)
        }
        
        container.addSubview(passwordLabel)
        passwordLabel.snp.makeConstraints { make in
            make.top.equalTo(accountStack.snp.bottom).offset(16)
            make.left.equalToSuperview()
        }
        
        container.addSubview(passwordTextField)
        passwordTextField.snp.makeConstraints { make in
            make.top.equalTo(passwordLabel.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(42)
        }

        view.addSubview(forgotButton)
        forgotButton.snp.makeConstraints { make in
            make.top.equalTo(container.snp.bottom).offset(10)
            make.leading.equalTo(container)
            make.height.equalTo(30)
        }
        
        view.addSubview(codeLoginButton)
        codeLoginButton.snp.makeConstraints { make in
            make.top.equalTo(forgotButton)
            make.trailing.equalTo(container)
            make.height.equalTo(30)
        }

        view.addSubview(loginBtn)
        loginBtn.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.top.equalTo(container.snp.bottom).offset(68)
            make.leading.trailing.equalTo(container)
        }
        
        let protocalLabel = UILabel()
        protocalLabel.isUserInteractionEnabled = true
        protocalLabel.font = .systemFont(ofSize: 13)
        let text = NSMutableAttributedString.init(string: "我已阅读并同意:".localized())
        text.append(NSAttributedString(string: "《服务协议》《隐私权政策》".localized(), attributes: [NSAttributedString.Key.foregroundColor: DemoUI.color_0089FF]))
        protocalLabel.attributedText = text
        
        protocalLabel.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let sself = self else { return }
                sself.toPrivacyRule()
            }).disposed(by: _disposeBag)
        
        // 协议
        let horSV = UIStackView.init(arrangedSubviews: [checkBoxButton, protocalLabel])
        horSV.alignment = .center
        horSV.spacing = 8
        view.addSubview(horSV)
        
        horSV.snp.makeConstraints { make in
            make.leading.trailing.equalTo(loginBtn)
            make.top.equalTo(loginBtn.snp.bottom).offset(16)
        }

        // 注册/找回密码
        let label = UILabel()
        label.textColor = DemoUI.color_8E9AB0
        label.font = .preferredFont(forTextStyle: .footnote)
        label.text = "还没有账号？".localized()
        let horSV2 = UIStackView.init(arrangedSubviews: [UIView(), label, registerButton, UIView()])
        horSV2.alignment = .center
        view.addSubview(horSV2)
        
        horSV2.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(24)
        }
    }
    
    deinit {
#if DEBUG
        print("dealloc \(type(of: self))")
#endif
    }
    
    func toRegister() {
        let vc = InputAccountViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func toCodeLogin() {
        if codeLoginButton.isSelected {
            passwordTextField.rightView = countDownButton
            passwordTextField.rightViewMode = .always
        } else {
            passwordTextField.rightView = nil
        }
    }
    
    func toForgotPasswordLogin() {
        let vc = InputAccountViewController(usedFor: .forgotPassword)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func agreeProtocal() {
        checkBoxButton.isSelected = !checkBoxButton.isSelected
    }
    
    func toPrivacyRule() {
        UIApplication.shared.openURL(NSURL.init(string:"https://www.baidu.com/")! as URL);
    }
}

extension UIButton {
    
    func setBackgroundColor(color: UIColor, forState: UIControl.State) {
        
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(colorImage, for: forState)
    }
}
