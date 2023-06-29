
import ChatLayout
import Foundation
import UIKit
import OUICore

enum VideoViewState {
    case loading
    case image(UIImage)
}

final class VideoView: UIView, ContainerCollectionViewCellDelegate {
    
    private lazy var stackView = UIStackView(frame: bounds)
    
    private lazy var loadingIndicator = UIActivityIndicatorView(style: .gray)
    
    private lazy var imageView = UIImageView(frame: bounds)
    
    private lazy var playImageView = UIImageView(image: UIImage(systemName: "play.circle")?.withRenderingMode(.alwaysTemplate))
    
    private var controller: VideoController!
    
    private var imageWidthConstraint: NSLayoutConstraint?
    
    private var imageHeightConstraint: NSLayoutConstraint?
    
    private var viewPortWidth: CGFloat = 300
    
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
        imageView.image = nil
    }
    
    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        viewPortWidth = layoutAttributes.layoutFrame.width
        setupSize()
    }
    
    func setup(with controller: VideoController) {
        self.controller = controller
    }
    
    func reloadData() {
        UIView.performWithoutAnimation {
            durationLabel.text = controller.duration
            switch controller.state {
            case .loading:
                loadingIndicator.isHidden = false
                imageView.isHidden = true
                imageView.image = nil
                stackView.removeArrangedSubview(imageView)
                stackView.addArrangedSubview(loadingIndicator)
                if !loadingIndicator.isAnimating {
                    loadingIndicator.startAnimating()
                }
                if #available(iOS 13.0, *) {
                    backgroundColor = .systemGray5
                } else {
                    backgroundColor = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)
                }
                setupSize()
            case let .image(image):
                loadingIndicator.isHidden = true
                loadingIndicator.stopAnimating()
                imageView.isHidden = false
                imageView.image = image
                stackView.removeArrangedSubview(loadingIndicator)
                stackView.addArrangedSubview(imageView)
                setupSize()
                backgroundColor = .clear
            }
        }
    }
    
    private func setupSubviews() {
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ])
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tap)
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.isHidden = true
        
        imageView.addSubview(playImageView)
        playImageView.translatesAutoresizingMaskIntoConstraints = false
        playImageView.tintColor = .white
        
        imageView.addSubview(durationLabel)
        NSLayoutConstraint.activate([
            playImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            playImageView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            playImageView.widthAnchor.constraint(equalToConstant: 44),
            playImageView.heightAnchor.constraint(equalToConstant: 44),
            
            durationLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
            durationLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -8)
        ])
        
        let loadingWidthConstraint = loadingIndicator.widthAnchor.constraint(equalToConstant: 100)
        loadingWidthConstraint.priority = UILayoutPriority(999)
        loadingWidthConstraint.isActive = true
        
        let loadingHeightConstraint = loadingIndicator.heightAnchor.constraint(equalToConstant: 100)
        loadingHeightConstraint.priority = UILayoutPriority(999)
        loadingHeightConstraint.isActive = true
        
        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 310)
        imageWidthConstraint?.priority = UILayoutPriority(999)
        
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 40)
        imageHeightConstraint?.priority = UILayoutPriority(999)
    }
    
    @objc
    private func tap() {
        controller?.action()
    }
    
    private func setupSize() {
        UIView.performWithoutAnimation {
            switch controller.state {
            case .loading:
                imageWidthConstraint?.isActive = false
                imageHeightConstraint?.isActive = false
                setNeedsLayout()
            case let .image(image):
                imageWidthConstraint?.isActive = true
                imageHeightConstraint?.isActive = true
                let maxWidth = min(viewPortWidth * StandardUI.maxWidth / 2, image.size.width)
                imageWidthConstraint?.constant = maxWidth
                imageHeightConstraint?.constant = image.size.height * maxWidth / image.size.width
                setNeedsLayout()
            }
        }
    }
    
}
