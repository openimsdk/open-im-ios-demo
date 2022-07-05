
import UIKit

class MessageBusinessCardRightTableViewCell: MessageBaseRightTableViewCell {
    let cardView: MessageBusinessCardView = {
        let v = MessageBusinessCardView()
        v.layer.cornerRadius = 6
        v.layer.borderColor = StandardUI.color_E9E9E9.cgColor
        v.layer.borderWidth = 1
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        bubbleImageView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.bottom.left.equalToSuperview()
            make.right.equalToSuperview().offset(-8)
            make.size.equalTo(CGSize(width: 222, height: 88))
        }

        bubbleImageView.image = nil
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setMessage(model: MessageInfo, extraInfo: ExtraInfo?) {
        super.setMessage(model: model, extraInfo: extraInfo)
        guard let json = model.content else { return }
        guard let cardModel = JsonTool.fromJson(json, toClass: BusinessCard.self) else { return }
        cardView.nameLabel.text = cardModel.nickname
        cardView.avatarImageView.setImage(with: cardModel.faceURL, placeHolder: StandardUI.avatar_placeholder)
    }
}
