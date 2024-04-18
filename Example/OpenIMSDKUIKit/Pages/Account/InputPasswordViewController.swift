
import UIKit
import RxSwift
import RxCocoa
import RxGesture
import SnapKit
import ProgressHUD
import Localize_Swift
//import GTSDK

public class InputPasswordViewController: UIViewController {
    
    private let _disposeBag = DisposeBag()
    lazy var basicInfo: [String: String] = [:]
    private var usedFor: UsedFor = .register
    
    init(usedFor: UsedFor = .register) {
        super.init(nibName: nil, bundle: nil)
        self.usedFor = usedFor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let nameLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.preferredFont(forTextStyle: .footnote)
        v.text = "昵称".localized()
        v.textColor = DemoUI.color_8E9AB0
        
        return v
    }()
    
    private lazy var nameTextField: UITextField = {
        let v = UITextField()
        v.placeholder = "请输入你的昵称".localized()
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
    
    private lazy var pswLabel: UILabel = {
        let v = UILabel()
        v.font = .preferredFont(forTextStyle: .footnote)
        v.textColor = DemoUI.color_8E9AB0
        v.text = "密码".localized()
        
        return v
    }()
    
    private lazy var eyesButton: UIButton = {
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
            self.pswTextField.isSecureTextEntry = !self.pswTextField.isSecureTextEntry
        }).disposed(by: _disposeBag)
        
        return t
    }()
    
    private lazy var pswTextField: UITextField = {
        let v = UITextField()
        v.placeholder = "请输入密码".localized()
        v.isSecureTextEntry = true
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
    
    private lazy var againPswLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.preferredFont(forTextStyle: .footnote)
        v.textColor = DemoUI.color_8E9AB0
        v.text = "确认密码".localized()
        
        return v
    }()
    
    private lazy var againPswTextField: UITextField = {
        let v = UITextField()
        v.placeholder = "请再次输入密码".localized()
        v.isSecureTextEntry = true
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
        v.setTitle("下一步".localized(), for: .normal)
        v.setTitleColor(.white, for: .normal)
        v.backgroundColor = DemoUI.color_0089FF
        v.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
        v.layer.cornerRadius = DemoUI.cornerRadius
        
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let sself = self else { return }
            sself.toComplate()
        }).disposed(by: _disposeBag)
        
        return v
    }()
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let bgImageView = UIImageView(image: UIImage(named: "login_bg"))
        bgImageView.frame = view.bounds
        view.addSubview(bgImageView)
        
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: _disposeBag)

        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }
        let label = UILabel()
        label.text = usedFor == .forgotPassword ? "设置密码".localized() : "设置信息".localized()
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textColor = .systemBlue

        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalTo(backButton)
            make.top.equalTo(backButton.snp.bottom).offset(42)
        }

        let pswTipsLabel = UILabel()
        pswTipsLabel.textColor = DemoUI.color_8E9AB0
        pswTipsLabel.font = .preferredFont(forTextStyle: .footnote)
        pswTipsLabel.text = "包含6~20位字符、大小写字母、特殊字符组合"
        
        let nameStack = UIStackView(arrangedSubviews: [nameLabel, nameTextField])
        nameStack.axis = .vertical
        nameStack.spacing = 4
        
        nameTextField.snp.makeConstraints { make in
            make.height.equalTo(42)
        }
        
        let pswStack = UIStackView(arrangedSubviews: [pswLabel, pswTextField, pswTipsLabel])
        pswStack.axis = .vertical
        pswStack.spacing = 4
        
        pswTextField.snp.makeConstraints { make in
            make.height.equalTo(42)
        }
        
        let againStack = UIStackView(arrangedSubviews: [againPswLabel, againPswTextField])
        againStack.axis = .vertical
        againStack.spacing = 4
        
        againPswTextField.snp.makeConstraints { make in
            make.height.equalTo(42)
        }

        let verSV = UIStackView(arrangedSubviews:
                                    usedFor == .forgotPassword ?
                                [pswStack, againStack] : [nameStack, pswStack, againStack])
        verSV.spacing = 24
        verSV.axis = .vertical

        view.addSubview(verSV)

        verSV.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.top.equalTo(label.snp.bottom).offset(48)
        }

        view.addSubview(loginBtn)
        loginBtn.snp.makeConstraints { make in
            make.top.equalTo(verSV.snp.bottom).offset(48)
            make.leading.trailing.equalTo(verSV)
            make.height.equalTo(40)
        }

        let tap = UITapGestureRecognizer()
        view.addGestureRecognizer(tap)
        
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            self?.view.endEditing(true)
        }).disposed(by: _disposeBag)
    }
    
    deinit {
#if DEBUG
        print("dealloc \(type(of: self))")
#endif
    }
    
    func toComplate() {
        view.endEditing(true)
        if let psw = againPswTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), psw.count >= 6 {
            if usedFor == .register {
                guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
                    ProgressHUD.error("输入昵称".localized())
                    return
                }
                ProgressHUD.animate()
                AccountViewModel.registerAccount(phone: basicInfo["phone"]!,
                                                 areaCode: basicInfo["areaCode"]!,
                                                 verificationCode: basicInfo["verCode"]!,
                                                 password: psw,
                                                 faceURL: "",
                                                 nickName: name,
                                                 invitationCode: basicInfo["invitationCode"]) { (errCode, errMsg) in
                    if errMsg != nil {
                        ProgressHUD.error(errMsg)
                    } else {
                        AccountViewModel.loginIM(uid: AccountViewModel.baseUser.userID,
                                                 imToken: AccountViewModel.baseUser.imToken,
                                                 chatToken: AccountViewModel.baseUser.chatToken) { errCode, errMsg in
                            
                            if let userID = AccountViewModel.userID {
//                                GeTuiSdk.bindAlias(userID, andSequenceNum: "im")
                            }
                            
                            AccountViewModel.updateUserInfo(userID: AccountViewModel.userID!) { (errCode, errMsg) in
                                ProgressHUD.dismiss()
                                self.dismiss(animated: true)
                            }
                        }
                    }
                }
            } else {
                AccountViewModel.resetPassword(phone: basicInfo["phone"]!,
                                               areaCode: basicInfo["areaCode"]!,
                                               verificationCode: basicInfo["verCode"]!,
                                               password: psw) { [weak self] (errCode, errMsg) in
                    
                    if errCode == 0, let `self` = self {
                        ProgressHUD.success("修改密码成功，请重新登录")
                        self.navigationController?.popToRootViewController(animated: true)
                    } else {
                        ProgressHUD.error(errMsg)
                    }
                }
            }
        } else {
            ProgressHUD.error("输入正确的密码")
        }
    }
}
