
import UIKit

class ChatTableViewCell: UITableViewCell {
    let avatarImageView: UIImageView = {
        let v = UIImageView()
        v.layer.cornerRadius = 6
        v.clipsToBounds = true
        return v
    }()

    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 16, weight: .medium)
        v.textColor = StandardUI.color_333333
        return v
    }()

    let subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 13)
        v.textColor = StandardUI.color_666666
        return v
    }()

    let timeLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 12)
        v.textColor = StandardUI.color_999999
        v.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        return v
    }()

    let unreadLabel: RoundCornerLayoutLabel = {
        let v = RoundCornerLayoutLabel(roundCorners: .allCorners, radius: nil)
        v.font = .systemFont(ofSize: 12)
        v.backgroundColor = StandardUI.color_F44038
        v.textColor = .white
        v.textAlignment = .center
        v.contentInset = UIEdgeInsets(top: 1, left: 4, bottom: 1, right: 4)
        return v
    }()

    let muteImageView: UIImageView = {
        let v = UIImageView(image: UIImage(nameInBundle: "chat_status_muted_icon"))
        v.isHidden = true
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(StandardUI.margin_22)
            make.size.equalTo(48)
            make.top.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().offset(-8).priority(.low)
        }

        let vStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
            v.axis = .vertical
            v.distribution = .equalSpacing
            v.spacing = 4
            return v
        }()

        contentView.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.centerY.equalTo(avatarImageView)
        }

        contentView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-StandardUI.margin_22)
            make.top.equalTo(avatarImageView).offset(5)
            make.left.greaterThanOrEqualTo(vStack.snp.right).offset(8)
        }

        contentView.addSubview(unreadLabel)
        unreadLabel.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(10)
            make.right.equalTo(timeLabel)
            make.width.greaterThanOrEqualTo(unreadLabel.snp.height)
        }

        contentView.addSubview(muteImageView)
        muteImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-StandardUI.margin_22)
            make.centerY.equalTo(unreadLabel)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
