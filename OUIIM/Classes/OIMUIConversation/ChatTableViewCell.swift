
import OUICore

class ChatTableViewCell: UITableViewCell {
    let avatarImageView: AvatarView = {
        let v = AvatarView()
        
        return v
    }()

    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .f17
        v.textColor = .c0C1C33
        
        return v
    }()

    let subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 13)
        v.textColor = .c8E9AB0
        v.font = .f14
        
        return v
    }()

    let timeLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 12)
        v.textColor = .c8E9AB0
        v.font = .f12
        v.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        
        return v
    }()

    let unreadLabel: RoundCornerLayoutLabel = {
        let v = RoundCornerLayoutLabel(roundCorners: .allCorners, radius: nil)
        v.font = .f12
        v.backgroundColor = .cFF381F
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
        contentView.backgroundColor = .quaternarySystemFill
        
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
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
