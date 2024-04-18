
import UIKit
import RxSwift
import RxCocoa
import RxGesture
import MMBAlertsPickers
import SnapKit
import ProgressHUD

public class InputAccountViewController: UIViewController {
    
    private let _disposeBag = DisposeBag()
    private var _areaCode = "+86"
    private var usedFor: UsedFor!
    
    init(usedFor: UsedFor = .register) {
        super.init(nibName: nil, bundle: nil)
        self.usedFor = usedFor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var phoneSegment: UILabel = {
        let v = UILabel()
        v.textColor = DemoUI.color_8E9AB0
        v.text = "手机号".innerLocalized()
        v.font = .preferredFont(forTextStyle: .footnote)
        
        return v
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
    
    public var phone: String? {
        return phoneTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    public var areaCode: String {
        return _areaCode
    }
    
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
            
            alert.addAction(title: "取消", style: .cancel)
            sself.present(alert, animated: true)
        }).disposed(by: _disposeBag)
        return t
    }()
        
    private lazy var phoneTextField: UITextField = {
        let v = UITextField()
        v.keyboardType = .numberPad
        v.placeholder = "请输入手机号码".localized()
        v.text = AccountViewModel.perLoginAccount
        v.borderStyle = .none
        v.textColor = DemoUI.color_0C1C33
        v.clearButtonMode = .whileEditing
        v.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        v.leftViewMode = .always
        
        return v
    }()
    
    private let invitationCodeLabel: UILabel = {
        let v = UILabel()
        v.text = "邀请码".localized()
        v.textColor = DemoUI.color_8E9AB0
        v.font = .preferredFont(forTextStyle: .footnote)
        
        return v
    }()
    
    private lazy var invitationCodeTextField: UITextField = {
        let v = UITextField()
        v.placeholder = "请输入邀请码".localized()
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
        v.setTitle("立即注册".localized(), for: .normal)
        v.setTitleColor(.white, for: .normal)
        v.backgroundColor = DemoUI.color_0089FF
        v.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
        v.layer.cornerRadius = DemoUI.cornerRadius
        
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let sself = self else { return }
            sself.toVerifyCode()
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
        label.text = "新用户注册".localized()
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textColor = .systemBlue
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalTo(backButton)
            make.top.equalTo(backButton.snp.bottom).offset(42)
        }
        
        let line = UIView()
        line.backgroundColor = DemoUI.color_E8EAEF
        
        let accountStack = UIStackView(arrangedSubviews: [areaCodeButton, line, phoneTextField])
        accountStack.spacing = 8
        accountStack.alignment = .center
        accountStack.layer.cornerRadius = DemoUI.cornerRadius
        accountStack.layer.borderColor = DemoUI.color_E8EAEF.cgColor
        accountStack.layer.borderWidth = 1
                
        areaCodeButton.snp.makeConstraints { make in
            make.width.equalTo(60)
        }
        
        phoneTextField.snp.makeConstraints { make in
            make.height.equalTo(42)
        }
        
        line.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.top.bottom.equalToSuperview().inset(4)
        }
        
        let useInvitationCode = AccountViewModel.clientConfig?.needInvitationCodeRegister == 1
        
        if useInvitationCode {
            invitationCodeTextField.snp.makeConstraints { make in
                make.height.equalTo(42)
            }
        }
        
        loginBtn.setTitle(usedFor == .register ? "立即注册" : "获取验证码", for: .normal)
        let verSV = UIStackView.init(arrangedSubviews: usedFor == .register ?
                                     (useInvitationCode ? [phoneSegment, accountStack, invitationCodeLabel, invitationCodeTextField] : [phoneSegment, accountStack]) :
                                        [phoneSegment, accountStack])
        
        verSV.axis = .vertical
        verSV.spacing = 16
        verSV.alignment = .fill
        view.addSubview(verSV)
        
        verSV.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.top.equalTo(label.snp.bottom).offset(48)
        }
        
        view.addSubview(loginBtn)
        loginBtn.snp.makeConstraints { make in
            make.top.equalTo(verSV.snp.bottom).offset(100)
            make.leading.trailing.equalTo(verSV)
            make.height.equalTo(40)
        }
        
        if usedFor == .forgotPassword {
            return
        }
        
        let protocalLabel = UILabel()
        protocalLabel.isUserInteractionEnabled = true
        protocalLabel.font = .systemFont(ofSize: 13)
        let text = NSMutableAttributedString.init(string: "我已阅读并同意:")
        text.append(NSAttributedString(string: "《服务协议》《隐私权政策》", attributes: [NSAttributedString.Key.foregroundColor: DemoUI.color_0089FF]))
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
    
    func toVerifyCode() {
        view.endEditing(true)
        
        if let phone = phoneTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), phone.isEmpty  {
            ProgressHUD.error("请输入正确的手机号码")
            return
        }
        
        let invaitationCode = invitationCodeTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        AccountViewModel.requestCode(phone: phone!, areaCode: areaCode, invaitationCode: invaitationCode, useFor: usedFor) { [weak self] errCode, errMsg in
            
            guard let sself = self else { return }
            
            if errCode != 0 {
                ProgressHUD.error(errMsg)
                
                if errCode == 20002 {
                    let vc = InputCodeViewController(usedFor: sself.usedFor)
                    vc.basicInfo = ["phone": sself.phone!,
                                    "areaCode": sself.areaCode,
                                    "invitationCode": invaitationCode ?? ""]
                    sself.navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                
                ProgressHUD.success("验证码发送成功".localized())
                let vc = InputCodeViewController(usedFor: sself.usedFor)
                vc.basicInfo = ["phone": sself.phone!,
                                "areaCode": sself.areaCode,
                                "invitationCode": invaitationCode ?? ""]
                sself.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func agreeProtocal() {
        checkBoxButton.isSelected = !checkBoxButton.isSelected
    }
    
    func toPrivacyRule() {
        UIApplication.shared.openURL(NSURL.init(string:"https://www.baidu.com/")! as URL);
    }
}
