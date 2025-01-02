
import ChatLayout
import Foundation
import UIKit
import OUICore

final class OANoticeView: UIView, ContainerCollectionViewCellDelegate {
    
    private lazy var stackView: UIStackView = {
        let v = UIStackView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.axis = .vertical
        v.spacing = 2
        
        return v
    }()
    
    private lazy var contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .cellBackgroundColor
        v.layer.borderColor = UIColor.cE8EAEF.cgColor
        v.layer.borderWidth = 1
        v.layer.masksToBounds = true
        v.layer.cornerRadius = 4
        
        return v
    }()

    private lazy var imageView: UIImageView = {
        let v = UIImageView()
        v.layer.cornerRadius = 4
        v.layer.masksToBounds = true
        
        return v
    }()
    
    private var controller: OANoticeViewController!

    private var imageWidthConstraint: NSLayoutConstraint?

    private var imageHeightConstraint: NSLayoutConstraint?

    private var viewPortWidth: CGFloat = 300.w
    
    private var imageMaxWidth = 300.0.w
    
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .f17
        v.textColor = .c0C1C33

        return v
    }()

    private let textLabel: UILabel = {
        let v = UILabel()
        v.numberOfLines = 0
        v.font = .f14
        v.textColor = .c0C1C33
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .vertical)

        return v
    }()
    
    private let separateLine: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .cE8EAEF
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .vertical)
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
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
        imageView.cancelDownload()
    }

    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        viewPortWidth = layoutAttributes.layoutFrame.width
        setupSize()
    }

    func setup(with controller: OANoticeViewController) {
        self.controller = controller
    }

    func reloadData() {
        titleLabel.text = controller.source.title
        textLabel.text = controller.source.text
        
        if let url = controller.source.snapshotUrl, let thumbURL = URL(string: url) {
            imageView.isHidden = false
            imageView.setImage(url: thumbURL, thumbURL: thumbURL)
        }
    }

    private func setupSubviews() {
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false

        addSubview(contentView)
        
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 1),
            contentView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -1),
            contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 1),
            contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -1),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
        ])
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(textLabel)
        stackView.addArrangedSubview(separateLine)
        stackView.addArrangedSubview(imageView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isHidden = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        isUserInteractionEnabled = true
        addGestureRecognizer(tap)

        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: imageMaxWidth)
        imageWidthConstraint?.priority = UILayoutPriority(999)
        
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: 40)
        imageHeightConstraint?.priority = UILayoutPriority(999)
    }
    
    @objc
    private func tap() {
        controller?.action()
    }

    private func setupSize() {
        guard let imageWidth = controller.source.width, let imageHeight = controller.source.height else {
            setNeedsLayout()
            return
        }
        var width = 0.0
        var height = 0.0
        
        if (imageMaxWidth > imageWidth) {
            width = imageWidth
            height = imageHeight
        } else {
            width = imageMaxWidth
            height = width * imageHeight / imageWidth
        }
        
        imageWidthConstraint?.constant = width
        imageHeightConstraint?.constant = height

        imageWidthConstraint?.isActive = true
        imageHeightConstraint?.isActive = true
        setNeedsLayout()
    }
}
