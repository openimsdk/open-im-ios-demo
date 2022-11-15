
import Foundation
import UIKit
import SVProgressHUD

class RegisterViewController: UIViewController {
    
    @IBOutlet var phoneTextField: UITextField!
    @IBOutlet var codeTextField: UITextField!
    @IBOutlet var pswTextField: UITextField!
    @IBOutlet var pswAgainTextField: UITextField!
    @IBOutlet var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let countDownButton = CountDownTimerButton()
        countDownButton.clickedBlock = { [weak self] sender in
            
            guard let sself = self, let phone = sself.phoneTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            
            AccountViewModel.requestCode(phone: phone, areaCode: "+86", useFor: 1) { (errCode, errMsg) in
                if errMsg != nil {
                    SVProgressHUD.showError(withStatus: String(errCode!).localized())
                } else {
                    SVProgressHUD.showSuccess(withStatus: "验证码发送成功")
                }
            }
        }
        codeTextField.rightView = countDownButton
        codeTextField.rightViewMode = .always
    }
    
    @IBAction func didTapNext() {
        view.endEditing(true)
        
        guard let phone = phoneTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let code = codeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let password = pswTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !phone.isEmpty, !code.isEmpty, !password.isEmpty, phone.count == 11  else {
            SVProgressHUD.showError(withStatus: "参数还是需要填完...")
            
            return
        }
        
        AccountViewModel.verifyCode(phone: phone, areaCode: "+86", useFor: 1, verificationCode: code) { [weak self] (errCode, errMsg) in
            if errMsg == nil {
                let vc =  CompleteUserInfoViewController()
                vc.basicInfo = ["phone": phone,
                                "areaCode": "+86",
                                "password": password,
                                "verCode": code]
                self?.navigationController?.pushViewController(vc, animated: true)
            } else {
                SVProgressHUD.showError(withStatus: String(errCode!).localized())
            }
        }
    }
}

// 封装倒计时button
class CountDownTimerButton: UIButton {
    
    // 向外部提供可点击接口
    // 声明闭包,在外面使用时监听按钮的点击事件
    typealias ClickedClosure = (_ sender: UIButton) -> Void
    // 作为此类的属性
    var clickedBlock: ClickedClosure?
    
    
    /// 计时器
    private var countdownTimer: Timer?
    /// 计时器是否开启(定时器开启的时机)
    var isCounting = false {
        
        willSet {
            // newValue 为true表示可以计时
            if newValue {
                countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime(_:)), userInfo: nil, repeats: true)
                
            } else {
                // 定时器停止时，定时器关闭时(销毁定时器)
                countdownTimer?.invalidate()
                countdownTimer = nil
            }
            
            // 判断按钮的禁用状态 有新值 按钮禁用 无新值按钮不禁用
            self.isEnabled = !newValue
            
        }
    }
    
    /// 剩余多少秒
    var remainingSeconds: Int = 5 {
        
        willSet {
            self.setTitle("\(newValue) s", for: .normal)
            if newValue <= 0 {
                self.setTitle("重新获取", for: .normal)
                isCounting = false
            }
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // 初始化
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 配置UI
    func setupUI() -> Void {
        
        self.setTitle(" 获取验证码 ", for:.normal)
        self.setTitleColor(.init(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        self.backgroundColor = UIColor.white
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.black.cgColor
        self.addTarget(self, action: #selector(sendButtonClick(_:)), for: .touchUpInside)
    }
    
    // MARK: 点击获取验证码
    // 按钮点击事件(在外面也可以再次定义点击事件,对这个不影响,会并为一个执行)
    @objc func sendButtonClick(_ btn:UIButton) {
        
        // 开启计时器
        self.isCounting = true
        // 设置重新获取秒数
        self.remainingSeconds = 10
        
        // 调用闭包
        if clickedBlock != nil {
            self.clickedBlock!(btn)
        }
        
    }
    
    // 开启定时器走的方法
    @objc func updateTime(_ btn:UIButton) {
        remainingSeconds -= 1
    }
    
    
}
