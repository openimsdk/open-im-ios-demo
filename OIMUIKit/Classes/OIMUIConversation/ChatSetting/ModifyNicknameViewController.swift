
import RxSwift
import UIKit

public class ModifyNicknameViewController: UIViewController {
    public let disposeBag = DisposeBag()
    public let titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        v.textColor = StandardUI.color_333333
        v.text = "我在群里的昵称"
        return v
    }()

    public let subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 15)
        v.textColor = StandardUI.color_333333
        v.text = "昵称修改后，只会在此群内显示，群内成员都可以看见"
        v.textAlignment = .center
        v.numberOfLines = 0
        return v
    }()

    public let avatarImageView: UIImageView = {
        let v = UIImageView()
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        return v
    }()

    public lazy var nameTextField: UITextField = {
        let v = UITextField()
        v.clearButtonMode = .always
        v.textColor = StandardUI.color_333333
        v.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        v.text = "昵称"
        return v
    }()

    public lazy var completeBtn: UIButton = {
        let v = UIButton()
        v.backgroundColor = StandardUI.color_1B72EC
        v.layer.cornerRadius = 4
        v.setTitle("完成".innerLocalized(), for: .normal)
        v.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return v
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let topLine: UIView = {
            let v = UIView()
            v.backgroundColor = StandardUI.color_333333
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
        container.addSubview(topLine)
        topLine.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(1)
        }

        container.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(StandardUI.avatar_42)
            make.top.equalTo(topLine.snp.bottom).offset(8)
            make.left.equalToSuperview()
        }

        let bottomLine: UIView = {
            let v = UIView()
            v.backgroundColor = StandardUI.color_333333
            return v
        }()

        container.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(avatarImageView.snp.bottom).offset(8)
            make.height.equalTo(1)
        }

        container.addSubview(nameTextField)
        nameTextField.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(avatarImageView)
            make.right.equalToSuperview()
        }

        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(36)
            make.left.right.equalToSuperview().inset(42)
        }

        view.addSubview(completeBtn)
        completeBtn.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-176)
            make.height.equalTo(40)
            make.width.equalTo(150)
            make.centerX.equalToSuperview()
        }
    }
}
