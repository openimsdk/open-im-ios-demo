import ChatLayout
import Foundation
import OUICore

class CardView: UIView, ContainerCollectionViewCellDelegate {
    
    private var viewPortWidth = 260.w
    private var contentWidthConstraint: NSLayoutConstraint?
    private var contentHeightConstraint: NSLayoutConstraint?
    
    private lazy var avatarView: AvatarView = {
        let v = AvatarView()
        
        return v
    }()
    
    private lazy var nameLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 17)
        v.textColor = .c0C1C33
        
        return v
    }()
    
    var controller: CardController!
    
    func reloadData() {
        guard let controller else {
            return
        }
        nameLabel.text = controller.name
        avatarView.setAvatar(url: controller.faceURL, text: controller.name)
    }
    
    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        setupSize()
    }

    func setup(with controller: CardController) {
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
        contentView.backgroundColor = .cellBackgroundColor
        contentView.isUserInteractionEnabled = true
        
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        let infoStack = UIStackView(arrangedSubviews: [avatarView, nameLabel])
        infoStack.spacing = 8
        infoStack.alignment = .center
        
        let line = UIView()
        line.backgroundColor = .cE8EAEF
        
        let label = UILabel()
        label.text = "carte".innerLocalized()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.c8E9AB0
        
        let columStack = UIStackView(arrangedSubviews: [infoStack, line, label])
        columStack.spacing = 8
        columStack.axis = .vertical
        columStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(columStack)
        NSLayoutConstraint.activate([
            line.heightAnchor.constraint(equalToConstant: 1),
            columStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            columStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            columStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            columStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
        
        contentWidthConstraint = columStack.widthAnchor.constraint(equalToConstant: viewPortWidth)
        contentWidthConstraint?.priority = UILayoutPriority(999)
        contentWidthConstraint?.isActive = true
        
        contentHeightConstraint = columStack.heightAnchor.constraint(equalToConstant: viewPortWidth)
        contentHeightConstraint?.priority = UILayoutPriority(999)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        contentView.isUserInteractionEnabled = true
        contentView.addGestureRecognizer(tap)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.3
        contentView.addGestureRecognizer(longPressGesture)
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
            self.contentHeightConstraint?.constant = 80
            self.contentHeightConstraint?.isActive = true
            self.setNeedsLayout()
        }
    }
}
