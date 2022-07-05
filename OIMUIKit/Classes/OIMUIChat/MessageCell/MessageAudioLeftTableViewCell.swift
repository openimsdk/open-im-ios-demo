
import Lottie
import SnapKit
import UIKit

class MessageAudioLeftTableViewCell: MessageBaseLeftTableViewCell {
    private lazy var audioStack: UIStackView = {
        let v = UIStackView(arrangedSubviews: [audioIconImageView, timeLabel])
        v.axis = .horizontal
        v.spacing = 5
        return v
    }()

    let timeLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 14)
        v.textColor = StandardUI.color_333333
        return v
    }()

    private let audioIconImageView: AnimationView = {
        let bundle = ViewControllerFactory.getBundle() ?? Bundle.main
        let v = AnimationView(name: "voice_black", bundle: bundle)
        v.loopMode = .loop
        v.setContentHuggingPriority(.required, for: .horizontal)
        v.setContentCompressionResistancePriority(.required, for: .horizontal)
        return v
    }()

    private var audioLengthConstraint: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        containerView.addSubview(audioStack)
        audioStack.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.bottom.right.equalToSuperview()
            audioLengthConstraint = make.width.equalTo(100).constraint
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        audioIconImageView.stop()
        audioIconImageView.currentProgress = 1
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
