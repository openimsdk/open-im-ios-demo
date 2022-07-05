
import RxSwift
import UIKit

class GroupChatNameTableViewCell: UITableViewCell {
    var disposeBag = DisposeBag()
    let avatarImageView: UIImageView = {
        let v = UIImageView()
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        return v
    }()

    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        v.textColor = StandardUI.color_333333
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(48)
            make.left.equalToSuperview().offset(StandardUI.margin_22)
            make.top.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(20).priority(.low)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(20)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
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
}
