





import UIKit
import SnapKit
import Lottie

class MessageAudioRightTableViewCell: MessageBaseRightTableViewCell {

    private lazy var audioStack: UIStackView = {
        let v = UIStackView.init(arrangedSubviews: [timeLabel, audioIconImageView])
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
        let v = AnimationView.init(name: "voice_blue", bundle: bundle)
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        audioIconImageView.currentProgress = 1
        audioIconImageView.stop()
    }
    
    override func setMessage(model: MessageInfo, extraInfo: ExtraInfo?) {
        super.setMessage(model: model, extraInfo: extraInfo)
        if let elem = model.soundElem {
            timeLabel.text = #"\#(elem.duration)""#
        }
        
        if model.isPlaying {
            audioIconImageView.play()
        } else {
            audioIconImageView.stop()
            audioIconImageView.currentProgress = 1
        }
    }
}
