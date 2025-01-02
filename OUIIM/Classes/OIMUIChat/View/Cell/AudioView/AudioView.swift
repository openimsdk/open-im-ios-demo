
import ChatLayout
import Foundation
import UIKit
import OUICore

enum AudioViewState {
    case idle
    case loading
    case play
}

final class AudioView: UIView, ContainerCollectionViewCellDelegate {

    private lazy var stackView: UIStackView = {
        let v = UIStackView(arrangedSubviews: [iconImageView])
        v.translatesAutoresizingMaskIntoConstraints = false
        v.spacing = 4
        v.alignment = .center
        
        return v
    }()

    private lazy var loadingIndicator = UIActivityIndicatorView(style: .gray)
    
    private lazy var playImageView = UIImageView(image: UIImage(systemName: "play.circle")?.withRenderingMode(.alwaysTemplate))

    var controller: AudioController!

    private var contentWidthConstraint: NSLayoutConstraint?

    private var viewPortWidth: CGFloat = 300.w
    
    private lazy var durationLabel: UILabel = {
        let v = UILabel()
        v.text = #"\#(0)``"#
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    lazy var iconImageView: UIImageView = {
        let v = UIImageView()
        v.highlightedImage = UIImage(nameInBundle: "chat_msg_audio_record_normal")?.withTintColor(.c0089FF)
        v.loadGif(name: "chat_msg_audio_record_play")
        v.isHighlighted = true
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        viewPortWidth = layoutAttributes.layoutFrame.width
        setupSize()
    }

    func setup(with controller: AudioController) {
        self.controller = controller
    }

    func reloadData() {
        DispatchQueue.main.async { [self] in
            durationLabel.text = #"\#(self.controller.duration)``"#
            
            stackView.removeArrangedSubview(durationLabel)
            stackView.removeArrangedSubview(iconImageView)
            
            if controller.messageType == .outgoing {
                stackView.addArrangedSubview(durationLabel)
                stackView.addArrangedSubview(iconImageView)
                iconImageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                durationLabel.textColor = nil
            } else {
                stackView.addArrangedSubview(iconImageView)
                stackView.addArrangedSubview(durationLabel)
                iconImageView.transform = .identity
                durationLabel.textColor = .c0089FF
            }
            
            switch controller.state {
            case .loading, .idle:
                self.iconImageView.isHighlighted = true
            case .play:
                self.iconImageView.isHighlighted = false
            }
        }
    }

    private func setupSubviews() {
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        contentWidthConstraint = stackView.widthAnchor.constraint(equalToConstant: viewPortWidth)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        stackView.isUserInteractionEnabled = true
        stackView.addGestureRecognizer(tap)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        stackView.addGestureRecognizer(longPressGesture)
    }
    
    @objc
    private func tap() {
        controller?.action()
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            controller?.longPress?(gesture.view!, gesture.location(in: gesture.view))
        }
    }

    private func setupSize() {
        UIView.performWithoutAnimation { [self] in
            self.contentWidthConstraint?.constant = self.viewPortWidth * StandardUI.maxWidthRate
            self.setNeedsLayout()
        }
    }
}
