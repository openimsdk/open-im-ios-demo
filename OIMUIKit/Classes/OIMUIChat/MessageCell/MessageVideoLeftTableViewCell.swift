//






import UIKit
import SnapKit

class MessageVideoLeftTableViewCell: MessageBaseLeftTableViewCell {

    let videoContentView: MessageVideoContentView = MessageVideoContentView()
    
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func setMessage(model: MessageInfo, extraInfo: ExtraInfo?) {
        super.setMessage(model: model, extraInfo: extraInfo)
        if let elem = model.videoElem {
            videoContentView.timeLabel.text = FormatUtil.getMediaFormat(of: elem.duration)
            videoContentView.imageView.setImage(with: elem.snapshotUrl, placeHolder: nil)
        }
    }
}
