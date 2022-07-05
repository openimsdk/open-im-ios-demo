
import UIKit

class MessageTimeOrTipsTableViewCell: UITableViewCell, MessageCellAble {
    weak var delegate: MessageDelegate?
    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 12)
        v.textColor = StandardUI.color_999999
        v.textAlignment = .center
        v.numberOfLines = 0
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(22)
            make.top.equalToSuperview().offset(5)
            make.bottom.equalToSuperview().offset(-5).priority(.low)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setMessage(model: MessageInfo, extraInfo: ExtraInfo?) {
        var isSingleChat = false
        if let info = extraInfo {
            isSingleChat = info.isC2C
        }
        let tips = MessageHelper.getSystemNotificationOf(message: model, isSingleChat: isSingleChat)
        titleLabel.attributedText = tips
    }
}
