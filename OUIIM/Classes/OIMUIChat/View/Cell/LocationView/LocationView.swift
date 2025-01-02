import ChatLayout
import Foundation
import OUICore

class LocationView: UIView, ContainerCollectionViewCellDelegate {
    
    private var imageWidthConstraint: NSLayoutConstraint?

    private var imageHeightConstraint: NSLayoutConstraint?
    
    private var viewPortWidth: CGFloat = 260.w

    
    private lazy var mapImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .center
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    private lazy var nameLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 14)
        v.textColor = .c0C1C33
        
        return v
    }()
    
    private lazy var addressLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 12)
        v.textColor = .c8E9AB0
        
        return v
    }()
    
    var controller: LocationController!
    
    func reloadData() {
        guard let controller else {
            return
        }
        
        mapImageView.setImage(with: controller.mapURL, placeHolder: nil)
        addressLabel.text = controller.address
        nameLabel.text = controller.name
    }
    
    func prepareForReuse() {
        mapImageView.image = nil
    }

    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        setupSize()
    }

    func setup(with controller: LocationController) {
        self.controller = controller
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
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
        contentView.isUserInteractionEnabled = true
        
        addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
        ])
        
        let line = UIView()
        line.backgroundColor = .cE8EAEF
        line.translatesAutoresizingMaskIntoConstraints = false
        
        let infoStack = UIStackView(arrangedSubviews: [nameLabel, addressLabel, line])
        infoStack.axis = .vertical
        infoStack.spacing = 4
        infoStack.translatesAutoresizingMaskIntoConstraints = false
                
        contentView.addSubview(infoStack)
        contentView.addSubview(mapImageView)
        
        NSLayoutConstraint.activate([
            line.heightAnchor.constraint(equalToConstant: 1),
            
            infoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            infoStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            infoStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            
            mapImageView.topAnchor.constraint(equalTo: infoStack.bottomAnchor),
            mapImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mapImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mapImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        mapImageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageWidthConstraint = mapImageView.widthAnchor.constraint(equalToConstant: viewPortWidth)
        imageWidthConstraint?.priority = UILayoutPriority(999)
        
        imageHeightConstraint = mapImageView.heightAnchor.constraint(equalToConstant: 79)
        imageHeightConstraint?.priority = UILayoutPriority(999)
        
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        addGestureRecognizer(tap)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.3
        contentView.addGestureRecognizer(longPressGesture)
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
    
    private func setupSize() {
        imageWidthConstraint?.constant = viewPortWidth * StandardUI.maxWidthRate
        imageHeightConstraint?.constant = 79.h
        imageWidthConstraint?.isActive = true
        imageHeightConstraint?.isActive = true
        setNeedsLayout()
    }
}
