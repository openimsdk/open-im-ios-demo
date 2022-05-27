





import UIKit

class MessageBusinessCardLeftTableViewCell: MessageBaseLeftTableViewCell {
    
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
            make.top.bottom.right.equalToSuperview()
            make.left.equalToSuperview().offset(8)
            make.size.equalTo(CGSize.init(width: 222, height: 88))
        }
        
        bubbleImageView.image = nil
    }
    
    required init?(coder: NSCoder) {
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

class MessageBusinessCardView: UIView {
    let avatarImageView: UIImageView = {
        let v = UIImageView()
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        return v
    }()
    
    let nameLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 16)
        v.textColor = StandardUI.color_333333
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(StandardUI.avatar_42)
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(16)
        }
        
        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(8)
            make.centerY.equalTo(avatarImageView)
            make.right.equalToSuperview().offset(-8)
        }
        
        let lineView: UIView = {
            let v = UIView()
            v.backgroundColor = StandardUI.color_E9E9E9
            return v
        }()
        
        self.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.left.right.equalToSuperview()
            make.top.equalTo(avatarImageView.snp.bottom).offset(10)
        }
        
        let iconLabel: UILabel = {
            let v = UILabel()
            v.text = "名片".innerLocalized()
            v.font = .systemFont(ofSize: 11)
            v.textColor = StandardUI.color_999999
            return v
        }()
        
        self.addSubview(iconLabel)
        iconLabel.snp.makeConstraints { make in
            make.centerX.equalTo(avatarImageView)
            make.top.equalTo(lineView.snp.bottom).offset(3)
            make.bottom.equalToSuperview().inset(4)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
