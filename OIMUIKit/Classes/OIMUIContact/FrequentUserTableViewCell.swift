
import UIKit

class FrequentUserTableViewCell: UITableViewCell {
    let avatarImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(StandardUI.margin_22)
            make.size.equalTo(StandardUI.avatar_42)
            make.top.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().offset(-15).priority(.medium)
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
            make.centerY.equalTo(avatarImageView)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
