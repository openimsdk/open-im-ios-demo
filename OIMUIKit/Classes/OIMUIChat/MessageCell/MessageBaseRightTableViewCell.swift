
import RxSwift
import UIKit

class MessageBaseRightTableViewCell: UITableViewCell, MessageCellAble {
    weak var delegate: MessageDelegate?
    let disposeBag = DisposeBag()
    var model: MessageInfo?
    /// 头像
    lazy var avatarImageView: UIImageView = {
        let v = UIImageView()
        v.backgroundColor = .brown
        v.layer.cornerRadius = 6
        v.clipsToBounds = true
        v.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            guard let sself = self, let message = self?.model else { return }
            self?.delegate?.didTapAvatar(with: message)
        }).disposed(by: self.disposeBag)
        v.addGestureRecognizer(tap)
        return v
    }()

    /// 昵称
    let nameLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 12)
        v.textColor = StandardUI.color_666666
        return v
    }()

    /// 气泡背景
    lazy var bubbleImageView: UIImageView = {
        let v = UIImageView()
        v.isUserInteractionEnabled = true
        v.image = UIImage(nameInBundle: "msg_bubble_right_image")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 5, bottom: 5, right: 15))
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            guard let sself = self, let message = self?.model else { return }
            self?.delegate?.didTapMessageCell(cell: sself, with: message)
        }).disposed(by: self.disposeBag)
        v.addGestureRecognizer(tap)
        let longPress = UILongPressGestureRecognizer()
        longPress.rx.event.filter { (gesture: UILongPressGestureRecognizer) -> Bool in
            gesture.state == .began
        }.subscribe(onNext: { [weak self] _ in
            guard let sself = self, let message = self?.model else { return }
            self?.delegate?.didLongPressBubbleView(bubbleView: sself.bubbleImageView, with: message)
        }).disposed(by: self.disposeBag)
        v.addGestureRecognizer(longPress)
        return v
    }()

    /// 包裹消息体的容器视图
    let containerView: UIView = {
        let v = UIView()
        return v
    }()

    lazy var resendBtn: UIButton = {
        let v = UIButton()
        v.setImage(UIImage(nameInBundle: "msg_send_fail_icon"), for: .normal)
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let sself = self, let message = sself.model else { return }
            self?.delegate?.didTapResendBtn(with: message)
        }).disposed(by: self.disposeBag)
        return v
    }()

    lazy var indicatorView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView()
        v.style = .gray
        v.tintColor = StandardUI.color_999999
        return v
    }()

    lazy var readLabel: UILabel = {
        let v = UILabel()
        v.text = "已读".innerLocalized()
        return v
    }()

    lazy var messageStack: UIStackView = {
        bubbleImageView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview().inset(8)
            make.right.equalToSuperview().inset(16)
        }
        let v = UIStackView(arrangedSubviews: [nameLabel, bubbleImageView])
        bubbleImageView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(MessageUI.atLeasetHeight)
            make.width.greaterThanOrEqualTo(16)
        }
        v.axis = .vertical
        v.distribution = .equalSpacing
        v.spacing = 4
        return v
    }()

    lazy var stateStack: UIStackView = {
        let v = UIStackView(arrangedSubviews: [resendBtn, indicatorView, readLabel])
        v.axis = .horizontal
        v.distribution = .equalSpacing
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(MessageUI.topBottomPadding)
            make.right.equalToSuperview().offset(-MessageUI.padding)
            make.size.equalTo(42)
        }
        contentView.addSubview(messageStack)
        messageStack.snp.makeConstraints { make in
            make.right.equalTo(avatarImageView.snp.left).offset(-4)
            make.top.equalTo(avatarImageView)
            make.left.greaterThanOrEqualToSuperview().offset(MessageUI.maxTrailingPadding)
            make.bottom.equalToSuperview().offset(-MessageUI.topBottomPadding).priority(.low)
        }
        contentView.addSubview(stateStack)
        stateStack.snp.makeConstraints { make in
            make.right.equalTo(messageStack.snp.left).offset(-8)
            make.centerY.equalTo(bubbleImageView)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setMessage(model: MessageInfo, extraInfo _: ExtraInfo?) {
        self.model = model
        avatarImageView.setImage(with: model.senderFaceUrl, placeHolder: StandardUI.avatar_placeholder)
        nameLabel.text = model.senderNickname
        nameLabel.isHidden = true
        readLabel.isHidden = false
        switch model.status {
        case .sendSuccess:
            resendBtn.isHidden = true
            readLabel.isHidden = false
            indicatorView.stopAnimating()
        case .sendFailure:
            resendBtn.isHidden = false
            readLabel.isHidden = true
            indicatorView.stopAnimating()
        case .sending:
            resendBtn.isHidden = true
            indicatorView.startAnimating()
            readLabel.isHidden = true
        default:
            resendBtn.isHidden = true
            indicatorView.stopAnimating()
            readLabel.isHidden = true
        }
        readLabel.attributedText = model.isRead ?
            NSAttributedString(string: "已读".innerLocalized(), attributes: [
                NSAttributedString.Key.foregroundColor: StandardUI.color_999999,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
            ]) :
            NSAttributedString(string: "未读".innerLocalized(), attributes: [
                NSAttributedString.Key.foregroundColor: StandardUI.color_1B72EC,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
            ])
    }
}
