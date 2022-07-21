
import UIKit
import RxSwift
import RxCocoa
import RxGesture

class LoginViewController: UIViewController {
    
    private let _disposeBag = DisposeBag()
    
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.text = "欢迎使用OpenIM"
        v.font = UIFont.systemFont(ofSize: 32, weight: .semibold)
        v.isUserInteractionEnabled = true
        return v
    }()
    
    private lazy var phoneSegment: UnderlineButton = {
        let v = UnderlineButton.init()
        v.setTitle("手机号码", for: .normal)
        v.setTitleColor(DemoUI.color_1D6BED, for: .normal)
        v.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        v.underline.backgroundColor = DemoUI.color_1D6BED
        return v
    }()
    
    lazy var registerButton: UIButton = {
        let t = UIButton(type: .system)
        t.setTitle("注册账号", for: .normal)

        return t
    }()
    
    var phone: String? {
        return phoneTextField.text
    }
    
    var password: String? {
        return passwordTextField.text
    }
        
    private lazy var phoneTextField: UnderlineTextField = {
        let v = UnderlineTextField.init()
        v.attributedPlaceholder = NSAttributedString.init(string: "请输入手机号码", attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18),
            NSAttributedString.Key.foregroundColor: DemoUI.color_999999
        ])
        v.clearButtonMode = .whileEditing
        return v
    }()
    
    private let passwordLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 14)
        v.textColor = DemoUI.color_333333
        v.text = "密码"
        return v
    }()
    
    private lazy var passwordTextField: UnderlineTextField = {
        let v = UnderlineTextField()
        v.attributedPlaceholder = NSAttributedString.init(string: "请输入密码", attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18),
            NSAttributedString.Key.foregroundColor: DemoUI.color_999999
        ])
        return v
    }()
    
    lazy var loginBtn: UIButton = {
        let v = UIButton()
        v.setTitle("登录", for: .normal)
        v.backgroundColor = DemoUI.color_1D6BED
        v.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        titleLabel.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                let vc = ConfigViewController()
                self?.navigationController?.pushViewController(vc, animated: true)
            }).disposed(by: _disposeBag)

        
        let container: UIView = {
            let v = UIView()
            return v
        }()
        
        container.addSubview(phoneSegment)
        phoneSegment.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
        }
        
        container.addSubview(phoneTextField)
        phoneTextField.snp.makeConstraints { make in
            make.top.equalTo(phoneSegment.snp.bottom).offset(30)
            make.left.right.equalToSuperview()
            make.height.equalTo(31)
        }
        
        container.addSubview(passwordLabel)
        passwordLabel.snp.makeConstraints { make in
            make.top.equalTo(phoneTextField.snp.bottom).offset(30)
            make.left.equalToSuperview()
        }
        
        container.addSubview(passwordTextField)
        passwordTextField.snp.makeConstraints { make in
            make.top.equalTo(passwordLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(31)
        }
        
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.centerY.equalToSuperview()
        }
        
        registerButton.addTarget(self, action: #selector(toRegister), for: .touchUpInside)
        
        view.addSubview(registerButton)
        registerButton.snp.makeConstraints { make in
            make.top.equalTo(container.snp_bottom).offset(24)
            make.trailing.equalTo(container)
            make.height.equalTo(30)
            make.width.equalTo(100)
        }
        
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(container.snp.top).offset(-50)
            make.left.equalTo(container)
        }
        
        view.addSubview(loginBtn)
        loginBtn.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.top.equalTo(container.snp.bottom).offset(115)
            make.left.right.equalTo(container)
        }
    }
    
    deinit {
        #if DEBUG
        print("dealloc \(type(of: self))")
        #endif
    }
    
    @objc func toRegister() {
        let storyboard = UIStoryboard(name: "Register", bundle: nil)
        self.navigationController?.pushViewController(storyboard.instantiateViewController(withIdentifier: "RegisterViewController"), animated: true)
    }
}
