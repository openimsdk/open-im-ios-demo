
import OUICore
import RxSwift

open class ModifyNicknameViewController: UIViewController {
    public let disposeBag = DisposeBag()
    public let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .f20
        v.textColor = .c0C1C33
        v.text = "我在群里的昵称".innerLocalized()
        return v
    }()

    public let subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = .f14
        v.textColor = .c0C1C33
        v.text = "昵称修改后，只会在此群内显示，群内成员都可以看见".innerLocalized()
        v.textAlignment = .center
        v.numberOfLines = 0
        return v
    }()

    public let avatarView = AvatarView()

    public lazy var nameTextField: UITextField = {
        let v = UITextField()
        v.clearButtonMode = .always
        v.textColor = .c0C1C33
        v.font = .f17
        v.text = "昵称".innerLocalized()
        
        v.rx.text.orEmpty.asDriver().map({ $0.count > 0}).drive(completeBtn.rx.isEnabled).disposed(by: disposeBag)
        
        return v
    }()
    
    public lazy var completeBtn: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("完成".innerLocalized(), for: .normal)
        
        return v
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBackgroundColor

        let rightButton = UIBarButtonItem(customView: completeBtn)
        navigationItem.rightBarButtonItem = rightButton
        
        let topLine: UIView = {
            let v = UIView()
            v.backgroundColor = .sepratorColor
            return v
        }()

        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(67 + kStatusBarHeight + 44)
            make.centerX.equalToSuperview()
        }

        view.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(42)
        }

        let container = UIView()
        container.backgroundColor = .cellBackgroundColor
        
        container.addSubview(topLine)
        topLine.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(1)
        }

        container.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.top.equalTo(topLine.snp.bottom).offset(8)
            make.left.equalToSuperview()
        }

        let bottomLine: UIView = {
            let v = UIView()
            v.backgroundColor = .sepratorColor
            return v
        }()

        container.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(avatarView.snp.bottom).offset(8)
            make.height.equalTo(1)
        }

        container.addSubview(nameTextField)
        nameTextField.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(avatarView)
            make.right.equalToSuperview()
        }

        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(36)
            make.left.right.equalToSuperview().inset(42)
        }
    }
}
