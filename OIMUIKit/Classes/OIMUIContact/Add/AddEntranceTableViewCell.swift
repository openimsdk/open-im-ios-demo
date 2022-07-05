
import UIKit

class AddEntranceTableViewCell: UITableViewCell {
    let avatarImageView: UIImageView = {
        let v = UIImageView()
        return v
    }()

    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        v.textColor = StandardUI.color_333333
        return v
    }()

    let subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 12)
        v.textColor = StandardUI.color_999999
        return v
    }()

    let arrowImageView: UIImageView = {
        let v = UIImageView()
        v.image = UIImage(nameInBundle: "contact_more_arrow")
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(30)
            make.left.equalTo(StandardUI.margin_22)
            make.centerY.equalToSuperview()
        }
        let vStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
            v.axis = .vertical
            v.spacing = 4
            return v
        }()

        contentView.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.centerY.equalTo(avatarImageView)
            make.left.equalTo(avatarImageView.snp.right).offset(18)
        }

        contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-18)
            make.centerY.equalTo(avatarImageView)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
