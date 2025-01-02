
import ChatLayout
import Foundation
import UIKit
import OUICore

final class VideoView: UIView, ContainerCollectionViewCellDelegate {
    
    private lazy var stackView = UIStackView(frame: bounds)
        
    private lazy var imageView = UIImageView(frame: bounds)
    
    private lazy var playImageView = UIImageView(image: UIImage(systemName: "play.circle")?.withRenderingMode(.alwaysTemplate))
    
    var controller: VideoController!
    
    private var imageWidthConstraint: NSLayoutConstraint?
    
    private var imageHeightConstraint: NSLayoutConstraint?
    
    private var viewPortWidth: CGFloat = 300.w
    
    private var imageMaxWidth = 120.0.w
    
    private lazy var durationLabel: UILabel = {
        let v = UILabel()
        v.backgroundColor = .clear
        v.textColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        v.font = .f12
        
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
    
    func prepareForReuse() {
        imageView.cancelDownload()
    }
    
    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        viewPortWidth = layoutAttributes.layoutFrame.width
        setupSize()
    }
    
    func setup(with controller: VideoController) {
        self.controller = controller
        imageView.tag = controller.messageID.hash
    }
    
    func reloadData() {
        durationLabel.text = controller.duration
        
        if controller.image != nil {
            imageView.image = controller.image
        } else {
            if let thumbURL = controller.source.thumb?.url {
                imageView.setImage(url: thumbURL, thumbURL: thumbURL)
            }
        }
    }
    
    private func setupSubviews() {
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        
        stackView.addArrangedSubview(imageView)
        
        imageView.addSubview(playImageView)
        playImageView.translatesAutoresizingMaskIntoConstraints = false
        playImageView.tintColor = .white
        
        imageView.addSubview(durationLabel)
    
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

            playImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            playImageView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            playImageView.widthAnchor.constraint(equalToConstant: 44),
            playImageView.heightAnchor.constraint(equalToConstant: 44),
            
            durationLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -4),
            durationLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -4)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tap)
        
        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: imageMaxWidth)
        imageWidthConstraint?.priority = UILayoutPriority(999)
        
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: imageMaxWidth)
        imageHeightConstraint?.priority = UILayoutPriority(999)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.3
        imageView.addGestureRecognizer(longPressGesture)
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
        var width = 0.0
        var height = 0.0
        
        if (imageMaxWidth > controller.size.width) {
            width = controller.size.width
            height = controller.size.height
        } else {
            width = imageMaxWidth;
            height = width * controller.size.height / controller.size.width;
        }
        
        imageWidthConstraint?.constant = width
        imageHeightConstraint?.constant = height
        imageWidthConstraint?.isActive = true
        imageHeightConstraint?.isActive = true

        setNeedsLayout()
    }
}
