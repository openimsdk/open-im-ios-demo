
import RxSwift
import UIKit

class AlertView: UIView {
    static let shared: AlertView = .init()
    static func show(onWindowOf view: UIView, alertTitle: String, confirmTitle: String, confirmAction: @escaping CallBack.VoidReturnVoid) {
        guard let window = view.window else { return }
        window.addSubview(AlertView.shared)
        AlertView.shared.confirmBtn.setTitle(confirmTitle, for: .normal)
        shared.titleLabel.text = alertTitle
        shared.disposeBag = DisposeBag()
        shared.confirmBtn.rx.tap.subscribe(onNext: { [weak shared] in
            confirmAction()
            shared?.removeFromSuperview()
            shared?.disposeBag = DisposeBag()
        }).disposed(by: shared.disposeBag)
        shared.cancelBtn.rx.tap.subscribe(onNext: { [weak shared] in
            shared?.removeFromSuperview()
            shared?.disposeBag = DisposeBag()
        }).disposed(by: shared.disposeBag)
        AlertView.shared.frame = window.bounds
    }

    private var disposeBag = DisposeBag()
    private lazy var cancelBtn: UIButton = {
        let v = UIButton()
        v.setTitle("取消".innerLocalized(), for: .normal)
        v.setTitleColor(StandardUI.color_333333, for: .normal)
        v.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        return v
    }()

    private lazy var confirmBtn: UIButton = {
        let v = UIButton()
        v.setTitle("发布".innerLocalized(), for: .normal)
        v.setTitleColor(StandardUI.color_1B72EC, for: .normal)
        v.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        v.backgroundColor = StandardUI.color_E8F2FF
        return v
    }()

    private let titleLabel: UILabel = {
        let v = UILabel()
        v.textAlignment = .center
        v.numberOfLines = 0
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0, alpha: 0.6)
        let container: UIView = {
            let v = UIView()
            v.backgroundColor = .white
            v.layer.cornerRadius = 6
            v.clipsToBounds = true
            return v
        }()

        container.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(22)
            make.left.right.equalToSuperview().inset(32)
        }

        let hStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [cancelBtn, confirmBtn])
            v.axis = .horizontal
            v.spacing = 1
            v.distribution = .fillEqually
            return v
        }()
        container.addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(46)
        }

        addSubview(container)
        container.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview().inset(50)
        }

        let hLine = UIView()
        let vLine = UIView()
        hLine.backgroundColor = StandardUI.color_F1F1F1
        vLine.backgroundColor = StandardUI.color_F1F1F1

        container.addSubview(hLine)
        hLine.snp.makeConstraints { make in
            make.top.equalTo(hStack)
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
        }

        container.addSubview(vLine)
        vLine.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(hStack)
            make.width.equalTo(1)
            make.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
