
import UIKit
import RxSwift

class LoginViewController: UIViewController {
    
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.text = "欢迎使用OpenIM"
        v.font = UIFont.systemFont(ofSize: 32, weight: .semibold)
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
}
