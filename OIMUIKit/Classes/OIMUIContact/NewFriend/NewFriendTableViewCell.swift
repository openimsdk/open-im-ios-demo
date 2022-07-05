
import RxSwift
import UIKit

class NewFriendTableViewCell: UITableViewCell {
    var disposeBag = DisposeBag()

    let avatarImageView: UIImageView = {
        let v = UIImageView()
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        return v
    }()

    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 16)
        v.textColor = StandardUI.color_333333
        return v
    }()

    let subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 12)
        v.textColor = StandardUI.color_666666
        return v
    }()

    let helloBtn: UIButton = {
        let v = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 44, height: 22)))
        v.setTitle("打招呼".innerLocalized(), for: .normal)
        v.titleLabel?.font = .systemFont(ofSize: 12)
        v.setTitleColor(StandardUI.color_1B72EC, for: .normal)
        return v
    }()

    let acceptBtn: UIButton = {
        let v = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 44, height: 22)))
        v.setTitle("接受".innerLocalized(), for: .normal)
        v.titleLabel?.font = .systemFont(ofSize: 12)
        v.setTitleColor(StandardUI.color_1B72EC, for: .normal)
        v.layer.cornerRadius = 3
        v.layer.borderColor = StandardUI.color_1B72EC.cgColor
        v.layer.borderWidth = 1
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(StandardUI.margin_22)
            make.size.equalTo(StandardUI.avatar_42)
            make.top.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().inset(15).priority(.medium)
        }

        let textStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
            v.axis = .vertical
            v.spacing = 4
            v.alignment = .leading
            return v
        }()

        contentView.addSubview(textStack)
        textStack.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(StandardUI.margin_22)
            make.centerY.equalToSuperview()
        }

        let buttonStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [helloBtn, acceptBtn])
            v.axis = .horizontal
            return v
        }()
        contentView.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-StandardUI.margin_22)
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    func setApplyState(_ state: ApplyState) {
        switch state {
        case .uncertain:
            helloBtn.isHidden = true
            acceptBtn.isHidden = false
        case .agreed:
            helloBtn.isHidden = false
            acceptBtn.isHidden = true
        }
    }

    enum ApplyState: Int {
        case uncertain
        case agreed
    }
}
