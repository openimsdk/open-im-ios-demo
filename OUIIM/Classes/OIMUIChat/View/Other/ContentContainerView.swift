
import Foundation
import OUICore

final class ContentContainerView<ContentView: UIView>: UIView {
    
    public lazy var contentView = ContentView(frame: bounds)
    
    var onTap: (() -> Void)? {
        didSet {
            tapGestureRecognizer.isEnabled = onTap != nil
        }
    }

    private var onTapStatus: (() -> Void)?
    
    private lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.textColor = .systemGray2
        v.font = .f12
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .vertical)
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .horizontal)
        
        return v
    }()

    private lazy var errorButton: UIButton = {
        let v = UIButton(type: .system)
        v.setImage(UIImage(systemName: "exclamationmark.circle.fill"), for: .normal)
        v.tintColor = .red
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        v.addTarget(self, action: #selector(errorButtonAction(_:)), for: .touchUpInside)
        
        return v
    }()
    
    @objc private func errorButtonAction(_ sender: UIButton) {
        onTapStatus?()
        sender.isHiddenSafe = true
        showStutusIndicator()
    }

    private lazy var statusIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
        
    private lazy var contentStack: UIStackView = {
        let v = UIStackView(arrangedSubviews: [errorButton, statusIndicator, contentView])
        v.spacing = 8
        v.alignment = .center
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapAction(_:)))
    
    @objc private func onTapAction(_ gesture: UIGestureRecognizer) {
        onTap?()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        
        addSubview(titleLabel)

        addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            
            contentStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            contentStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 8),
            contentStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -8),
            contentStack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
        
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ContentContainerView {
    
    public func showStutusIndicator(_ show: Bool = true) {
        if show {
            statusIndicator.isHiddenSafe = false
            statusIndicator.startAnimating()
        } else {
            statusIndicator.isHiddenSafe = true
        }
    }
    
    public func showErrorButton(_ show: Bool = false, onTapStatus: (() -> Void)? = nil) {
        errorButton.isHiddenSafe = !show
        self.onTapStatus = onTapStatus
    }
    
    func setTitle(title: String?, messageType: MessageType) {
        titleLabel.text = title
        titleLabel.textAlignment = messageType == .outgoing ? .right : .left
    }
}
