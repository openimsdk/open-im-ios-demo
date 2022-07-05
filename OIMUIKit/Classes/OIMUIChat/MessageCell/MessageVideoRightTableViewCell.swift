
import SnapKit
import UIKit

class MessageVideoRightTableViewCell: MessageBaseRightTableViewCell {
    let videoContentView: MessageVideoContentView = .init()
    private var sizeConstraint: Constraint?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        bubbleImageView.addSubview(videoContentView)
        videoContentView.snp.makeConstraints { make in
            sizeConstraint = make.size.equalTo(185).constraint
            make.edges.equalToSuperview()
        }

        bubbleImageView.image = nil
        containerView.isHidden = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setMessage(model: MessageInfo, extraInfo: ExtraInfo?) {
        super.setMessage(model: model, extraInfo: extraInfo)
        if let elem = model.videoElem {
            videoContentView.timeLabel.text = FormatUtil.getMediaFormat(of: elem.duration)
            if let url = elem.snapshotUrl {
                videoContentView.imageView.setImage(with: elem.snapshotUrl, placeHolder: nil)
            } else if let path = elem.snapshotPath {
                videoContentView.imageView.setImagePath(path, placeHolder: nil)
            }
        }
    }
}

class MessageVideoContentView: UIView {
    private let playIconImageView: UIImageView = {
        let v = UIImageView(image: UIImage(nameInBundle: "msg_video_play_icon"))
        return v
    }()

    let timeLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 14)
        v.textColor = .white
        return v
    }()

    let imageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        v.backgroundColor = .black
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addSubview(playIconImageView)
        playIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview().inset(6)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
