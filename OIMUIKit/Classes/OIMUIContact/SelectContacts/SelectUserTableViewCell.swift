
import UIKit

class SelectUserTableViewCell: FriendListUserTableViewCell {
    var canBeSelected = true {
        didSet {
            stateImageView.image = canBeSelected ? UIImage(nameInBundle: "common_checkbox_unselected") : UIImage(nameInBundle: "common_checkbox_disable_selected")
        }
    }

    private let stateImageView: UIImageView = {
        let v = UIImageView()
        v.image = UIImage(nameInBundle: "common_checkbox_unselected")
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(stateImageView)
        stateImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(StandardUI.margin_22)
            make.centerY.equalToSuperview()
        }

        avatarImageView.snp.remakeConstraints { make in
            make.left.equalTo(stateImageView.snp.right).offset(12)
            make.size.equalTo(StandardUI.avatar_42)
            make.top.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().inset(15).priority(.medium)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if !canBeSelected { return }
        super.setSelected(selected, animated: animated)
        stateImageView.image = selected ? UIImage(nameInBundle: "common_checkbox_selected") : UIImage(nameInBundle: "common_checkbox_unselected")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        canBeSelected = true
    }
}
