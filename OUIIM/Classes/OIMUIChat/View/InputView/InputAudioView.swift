
import Foundation
import OUICore



class InputAudioView: UIView {
    
    public func toggleStatus() {
        let status = statusImageView.isHighlighted
        statusImageView.contentMode = status ? .scaleToFill : .center
        statusImageView.isHighlighted = !status
        statusLabel.text = statusImageView.isHighlighted ? "liftFingerToCancelSend".innerLocalized() : "releaseToSendSwipeUpToCancel".innerLocalized()
        contentView.backgroundColor = statusImageView.isHighlighted ? .red : .clear
    }

    public var isIdel: Bool {
        return statusImageView.isHighlighted
    }
    
    public lazy var durationLabel: UILabel = {
        let v = UILabel()
        v.font = .f12
        v.textColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    private lazy var statusImageView: UIImageView = {
        let v = UIImageView()
        v.highlightedImage = UIImage(nameInBundle: "inputbar_record_voice_cancel_icon")
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()

    private lazy var statusLabel: UILabel = {
        let v = UILabel()
        v.textColor = .white
        v.text = "releaseToSendSwipeUpToCancel".innerLocalized()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .vertical)
        
        return v
    }()
    
    private lazy var contentView: UIView = {
        let v = UIView()
        v.alpha = 0.7
        v.layer.cornerRadius = 5
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    init() {
        super.init(frame: .zero)
        setupSubViews()
        statusImageView.loadGif(name: "inputbar_record_voice_input_icon")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubViews() {
        addSubview(contentView)
        
        contentView.addSubview(statusImageView)
        contentView.addSubview(statusLabel)
        contentView.addSubview(durationLabel)
        
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            
            durationLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            durationLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            
            statusImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            statusImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            statusImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            statusImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            statusLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])
    }
}



