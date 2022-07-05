
import UIKit

class MessageQuoteRightTableViewCell: MessageTextRightTableViewCell {
    let quoteTextLabel: UILabel = {
        let v = UILabel()
        v.numberOfLines = 2
        v.font = .systemFont(ofSize: 12)
        v.textColor = StandardUI.color_666666
        return v
    }()

    let quoteMediaImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        return v
    }()

    let quotePlayIconImageView: UIImageView = {
        let v = UIImageView(image: UIImage(nameInBundle: "msg_quote_play_icon"))
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        quoteMediaImageView.addSubview(quotePlayIconImageView)
        quotePlayIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        let hStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [quoteTextLabel, quoteMediaImageView])
            quoteTextLabel.snp.makeConstraints { make in
                make.width.lessThanOrEqualTo(165)
            }
            quoteMediaImageView.snp.makeConstraints { make in
                make.width.equalTo(StandardUI.avatar_42)
                make.height.lessThanOrEqualTo(StandardUI.avatar_42)
            }
            v.axis = .horizontal
            v.distribution = .equalSpacing
            v.spacing = 3
            return v
        }()
        let container: UIView = {
            let v = UIView()
            v.backgroundColor = StandardUI.color_F0F0F0
            return v
        }()
        container.addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(6)
        }
        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(messageStack.snp.bottom).offset(4)
            make.right.equalTo(avatarImageView.snp.left).offset(-12)
            make.bottom.equalToSuperview().offset(-MessageUI.topBottomPadding)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setMessage(model: MessageInfo, extraInfo: ExtraInfo?) {
        super.setMessage(model: model, extraInfo: extraInfo)
        if let elem = model.quoteElem {
            contentLabel.text = elem.text
        }

        if let quoteMsg = model.quoteElem?.quoteMessage {
            let senderName = (quoteMsg.senderNickname ?? "") + ":"
            switch quoteMsg.contentType {
            case .text:
                quoteMediaImageView.isHidden = true
                quoteTextLabel.text = senderName.append(string: quoteMsg.content)
            case .video:
                if let video = quoteMsg.videoElem {
                    quoteMediaImageView.setImage(with: video.snapshotUrl, placeHolder: nil)
                }
                quoteMediaImageView.isHidden = false
                quotePlayIconImageView.isHidden = false
                quoteTextLabel.text = senderName
            case .image:
                if let image = quoteMsg.pictureElem?.snapshotPicture {
                    quoteMediaImageView.setImage(with: image.url, placeHolder: nil)
                }
                quoteMediaImageView.isHidden = false
                quotePlayIconImageView.isHidden = true
                quoteTextLabel.text = senderName
            default:
                quoteMediaImageView.isHidden = true
                quoteTextLabel.text = senderName
            }
        }
    }
}
