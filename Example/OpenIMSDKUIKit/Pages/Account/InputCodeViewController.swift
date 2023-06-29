
import UIKit
import RxSwift
import RxCocoa
import RxGesture
import SnapKit
import ProgressHUD
import Localize_Swift
import SGCodeTextField

class InputCodeViewController: UIViewController {
    
    private let _disposeBag = DisposeBag()
    lazy var basicInfo: [String: String] = [:]
    private var usedFor: UsedFor!
    
    init(usedFor: UsedFor = .register) {
        super.init(nibName: nil, bundle: nil)
        self.usedFor = usedFor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
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
        label.text = "输入手机号验证吗".localized()
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textColor = .systemBlue
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalTo(backButton)
            make.top.equalTo(backButton.snp.bottom).offset(42)
        }
        
        let phone = basicInfo["phone"]!
        let areaCode = basicInfo["areaCode"]!
        
        let countDownButton = CountDownTimerButton()
        countDownButton.useLeftTitle = true
        countDownButton.tipsPrefix = "后重新获取验证码".localized()
        countDownButton.useBorder = false
        countDownButton.isCounting = true
        countDownButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        countDownButton.setTitleColor(DemoUI.color_8E9AB0, for: .normal)

        countDownButton.clickedBlock = { [weak self] sender in
                        
            guard let `self` = self else { return }
            AccountViewModel.requestCode(phone: phone, areaCode: areaCode, useFor: self.usedFor) { (errCode, errMsg) in
                if errCode != 0 {
                    ProgressHUD.showError(errMsg)
                } else {
                    ProgressHUD.showSuccess("验证码发送成功".localized())
                    countDownButton.isCounting = true
                }
            }
        }
      
        let accountLabel = UILabel()
        accountLabel.textColor = DemoUI.color_8E9AB0
        accountLabel.font = .preferredFont(forTextStyle: .callout)
        accountLabel.text = areaCode + " " + phone
        
        let tipsLabel = UILabel()
        tipsLabel.textColor = .red
        tipsLabel.text = "请输入验证码(若收不到,填666666)"
        
        let codeTextField = SGCodeTextField()
        codeTextField.count = 6
        codeTextField.textColorFocused = UIColor.systemGray6
        codeTextField.refreshUI()
        codeTextField.becomeFirstResponder()
        
        codeTextField.textChangeHandler = { [weak self] text, completed in

            print(text ?? "")
            if let t = text, completed, let `self` = self {
                AccountViewModel.verifyCode(phone: phone, areaCode: areaCode, useFor: self.usedFor, verificationCode: t) { [weak self] errCode, errMsg in
                    if errCode != 0 {
                        ProgressHUD.showError(errMsg)
                    } else {
                        guard let sself = self else { return }
                        sself.basicInfo["verCode"] = t
                        let vc = InputPasswordViewController(usedFor: sself.usedFor)
                        vc.basicInfo = sself.basicInfo
                        sself.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
        }

        let verSV = UIStackView.init(arrangedSubviews: [accountLabel, tipsLabel, codeTextField, countDownButton])
        verSV.spacing = 24
        verSV.axis = .vertical
        view.addSubview(verSV)
        
        verSV.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.top.equalTo(label.snp.bottom).offset(48)
        }
        
        codeTextField.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
    }
    
    deinit {
        #if DEBUG
        print("dealloc \(type(of: self))")
        #endif
    }
}
