
import Lottie
import SnapKit
import UIKit

class MessageAudioRightTableViewCell: MessageBaseRightTableViewCell {
    private lazy var audioStack: UIStackView = {
        let v = UIStackView(arrangedSubviews: [timeLabel, audioIconImageView])
        v.axis = .horizontal
        v.spacing = 5
        return v
    }()

    let timeLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 14)
        v.textColor = StandardUI.color_333333
        v.textAlignment = .right
        return v
    }()

    private let audioIconImageView: AnimationView = {
//        let v = UIImageView.init(image: UIImage.init(nameInBundle: "msg_audio_right_icon"))
        let bundle = ViewControllerFactory.getBundle() ?? Bundle.main
        let v = AnimationView(name: "voice_blue", bundle: bundle)
        v.loopMode = .loop
        v.currentProgress = 1
        v.setContentHuggingPriority(.required, for: .horizontal)
        v.setContentCompressionResistancePriority(.required, for: .horizontal)
        return v
    }()

    private var audioLengthConstraint: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        containerView.addSubview(audioStack)
        audioStack.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.top.bottom.left.equalToSuperview()
            audioLengthConstraint = make.width.equalTo(100).constraint
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        audioIconImageView.currentProgress = 1
        audioIconImageView.stop()
    }

    override func setMessage(model: MessageInfo, extraInfo: ExtraInfo?) {
        super.setMessage(model: model, extraInfo: extraInfo)
        guard let elem = model.soundElem else { return }
        timeLabel.text = #"\#(elem.duration)""#
        if model.isPlaying {
            audioIconImageView.play()
        } else {
            audioIconImageView.stop()
            audioIconImageView.currentProgress = 1
        }
        let width = MessageHelper.getAudioMessageDisplayWidth(duration: elem.duration)
        audioLengthConstraint?.update(offset: width)
    }
}
