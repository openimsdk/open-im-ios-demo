
import Foundation
import OUICore
import ChatLayout

final class FileView: UIView, ContainerCollectionViewCellDelegate {
    
    private var viewPortWidth: CGFloat = 260.w
    private var contentWidthConstraint: NSLayoutConstraint?
    private var contentHeightConstraint: NSLayoutConstraint?

    private lazy var statusButton: UIButton = {
        let v = UIButton(type: .custom)
        v.setImage(UIImage(systemName: "arrow.down.circle"), for: .normal)
        v.setImage(UIImage(systemName: "pause.circle"), for: .selected)
        v.setImage(nil, for: .disabled)
        v.addTarget(self, action: #selector(toggleDownloadStatus), for: .touchUpInside)
        v.backgroundColor = .clear
        v.tintColor = .white
        
        return v
    }()
    
    private lazy var iconImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .center
        
        return v
    }()
    
    private lazy var progressView = CircleProgressView()

    private lazy var nameLabel: UILabel = {
        let v = UILabel()
        v.font = .f17
        v.textColor = .c0C1C33
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        v.lineBreakMode = .byTruncatingMiddle
        
        return v
    }()
    
    private lazy var lengthLabel: UILabel = {
        let v = UILabel()
        v.font = .f14
        v.textColor = .c8E9AB0
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .vertical)
        
        return v
    }()
    
    lazy var sendIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        
        return v
    }()
    
    var controller: FileController!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        setupSize()
    }
    
    func setup(with controller: FileController) {
        self.controller = controller
    }
    
    func prepareForReuse() {
        controller.prepareForReuse()
    }
    
    private func setupSubviews() {
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false

        let contentView = UIView()
        contentView.layer.cornerRadius = StandardUI.cornerRadius
        contentView.layer.borderColor = UIColor.cE8EAEF.cgColor
        contentView.layer.borderWidth = 1
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .cellBackgroundColor
        contentView.isUserInteractionEnabled = true 
        
        addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 64),
        ])
        
        let infoStack = UIStackView(arrangedSubviews: [nameLabel, lengthLabel])
        infoStack.spacing = 8
        infoStack.axis = .vertical
        
        let iconView = UIView()
        iconView.addSubview(iconImageView)
        iconView.addSubview(statusButton)
        iconView.addSubview(progressView)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        statusButton.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isUserInteractionEnabled = false
        
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 50),
            
            iconImageView.leadingAnchor.constraint(equalTo: iconView.leadingAnchor),
            iconImageView.topAnchor.constraint(equalTo: iconView.topAnchor),
            iconImageView.trailingAnchor.constraint(equalTo: iconView.trailingAnchor),
            iconImageView.bottomAnchor.constraint(equalTo: iconView.bottomAnchor),
            
            statusButton.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            statusButton.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            statusButton.widthAnchor.constraint(equalToConstant: 32),
            statusButton.heightAnchor.constraint(equalToConstant: 32),
            
            progressView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 20),
            progressView.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        let rowStack = UIStackView(arrangedSubviews: [infoStack, UIView(), iconView])
        rowStack.distribution = .fill
        rowStack.alignment = .center
        rowStack.backgroundColor = .clear
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            rowStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
        
        contentWidthConstraint = rowStack.widthAnchor.constraint(equalToConstant: viewPortWidth)
        contentWidthConstraint?.priority = UILayoutPriority(999)
        
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        addGestureRecognizer(tap)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        contentView.addGestureRecognizer(longPressGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func toggleDownloadStatus() {
        if controller.status == .normal {
            statusButton.isSelected = true
            controller.resume()
        } else if controller.status == .downloading {
            statusButton.isSelected = false
            controller.pause()
        } else if controller.status == .paused {
            controller.resume()
        }
    }
    
    func reloadData() {
        iconImageView.image = controller.image
        iconImageView.highlightedImage = controller.highlightedImage
        nameLabel.text = controller.displayName
        lengthLabel.text = controller.length
        
        if controller.status == .normal || controller.status == .paused {
            statusButton.isSelected = false
        } else if controller.status == .downloading {
            statusButton.isSelected = true
            progressView.progress = controller.progress
        } else if controller.status == .completion {
            progressView.isHidden = true
            statusButton.isHidden = true
            iconImageView.isHighlighted = true
        }
    }
    
    private func setupSize() {
        UIView.performWithoutAnimation { [self] in
            self.contentWidthConstraint?.constant = self.viewPortWidth * StandardUI.maxWidthRate
            contentWidthConstraint?.isActive = true
            self.setNeedsLayout()
        }
    }
    
    @objc
    private func tap() {
        controller.action()
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            controller?.longPress?(gesture.view!, gesture.location(in: gesture.view))
        }
    }
}

