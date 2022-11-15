
import UIKit

class CheckBoxTextTableViewCell: UITableViewCell {
    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 16)
        v.textColor = DemoUI.color_333333
        return v
    }()

    private let stateImageView: UIImageView = .init(image: UIImage(nameInBundle: "common_checkbox_unselected"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(DemoUI.margin_22)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(stateImageView)
        stateImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-DemoUI.margin_22)
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        stateImageView.image = selected ? UIImage(nameInBundle: "common_checkbox_selected") : UIImage(nameInBundle: "common_checkbox_unselected")
    }
}
