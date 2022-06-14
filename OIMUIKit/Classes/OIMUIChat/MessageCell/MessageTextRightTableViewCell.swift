





import UIKit

class MessageTextRightTableViewCell: MessageBaseRightTableViewCell {

    let contentLabel: UILabel = {
        let v = UILabel()
        v.numberOfLines = 0
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        containerView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func setMessage(model: MessageInfo, extraInfo: ExtraInfo?) {
        super.setMessage(model: model, extraInfo: extraInfo)
        if let content = model.content {
            contentLabel.attributedText = EmojiHelper.shared.replaceTextWithEmojiIn(attributedString: NSAttributedString.init(string: content))
        }
    }
}
