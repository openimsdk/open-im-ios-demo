import UIKit

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
    
    var useLeftTitle = false {
        willSet {
            contentHorizontalAlignment = newValue ? .left : .center
        }
    }
    
    var useBorder = true {
        willSet {
            self.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    var tipsPrefix: String = "s" {
        willSet {
            
        }
    }
    
    /// 剩余多少秒
    var remainingSeconds: Int = 300 {
        
        willSet {
            self.setTitle("\(newValue)\(tipsPrefix)", for: .normal)
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
        self.setTitle(" 发送验证码 ", for:.normal)
        self.setTitleColor(.systemBlue, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        self.addTarget(self, action: #selector(sendButtonClick(_:)), for: .touchUpInside)
    }
    
    // MARK: 点击获取验证码
    // 按钮点击事件(在外面也可以再次定义点击事件,对这个不影响,会并为一个执行)
    @objc func sendButtonClick(_ btn:UIButton) {
        
        // 开启计时器
        self.isCounting = true
        // 设置重新获取秒数
        self.remainingSeconds = 300
        
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
