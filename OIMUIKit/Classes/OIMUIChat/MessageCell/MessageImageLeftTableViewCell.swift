
import SnapKit
import UIKit

class MessageImageLeftTableViewCell: MessageBaseLeftTableViewCell {
    let imageContentView: UIImageView = {
        let v = UIImageView()
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        v.contentMode = .scaleAspectFill
        return v
    }()

    private var sizeConstraint: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        bubbleImageView.addSubview(imageContentView)
        imageContentView.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(185)
            make.width.greaterThanOrEqualTo(90)
            make.height.equalTo(185)
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
        if let elem = model.pictureElem {
            imageContentView.setImage(with: elem.snapshotPicture?.url, placeHolder: nil)
        }
    }
}
