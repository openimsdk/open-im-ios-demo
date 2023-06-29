
import ChatLayout
import Foundation
import UIKit
import OUICore

final class MainContainerView<LeadingAccessory: StaticViewFactory, CustomView: UIView, TrailingAccessory: StaticViewFactory>: UIView, SwipeNotifierDelegate {

    private var timer: DispatchSourceTimer?
    private var countdownTime: Int = 0
    
    private var didTapRead: (() -> Void)?
    
    var swipeCompletionRate: CGFloat = 0 {
        didSet {
            updateOffsets()
        }
    }
    
    var avatarView: LeadingAccessory.View? {
        containerView.leadingView
    }

    var customView: BezierMaskedView<CustomView> {
        containerView.customView
    }
    
    // 阅后即焚 倒计时
    lazy var leadingCountdownLabel: UILabel = {
        let v = UILabel()
        v.textColor = .systemBlue
        v.font = .preferredFont(forTextStyle: .footnote)
        
        return v
    }()
    
    lazy var trailingCountdownLabel: UILabel = {
        let v = UILabel()
        v.textColor = .systemBlue
        v.font = .preferredFont(forTextStyle: .footnote)
        
        return v
    }()
    
    @objc
    private func tapAction() {
        didTapRead?()
    }
    // 这里调整下右侧头像
//    var statusView: TrailingAccessory.View? {
//        containerView.trailingView
//    }
    
    var rightAvatarView: TrailingAccessory.View? {
        containerView.trailingView
    }

    weak var accessoryConnectingView: UIView? {
        didSet {
            guard accessoryConnectingView != oldValue else {
                return
            }
            updateAccessoryView()
        }
    }

    var accessoryView = DateAccessoryView()

    var accessorySafeAreaInsets: UIEdgeInsets = .zero {
        didSet {
            guard accessorySafeAreaInsets != oldValue else {
                return
            }
            accessoryOffsetConstraint?.constant = accessorySafeAreaInsets.right
            setNeedsLayout()
            updateOffsets()
        }
    }

    private(set) lazy var containerView = CellLayoutContainerView<LeadingAccessory, BezierMaskedView<CustomView>, TrailingAccessory>()

    private weak var accessoryOffsetConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }
    
    deinit {
        timer = nil
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        clipsToBounds = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let containerStack = UIStackView(arrangedSubviews: [leadingCountdownLabel, containerView, trailingCountdownLabel])
        containerStack.spacing = 8
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(containerStack)
        
        NSLayoutConstraint.activate([
            containerStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            containerStack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            containerStack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
        ])
        
        accessoryView.translatesAutoresizingMaskIntoConstraints = false

        updateOffsets()
    }

    private func updateAccessoryView() {
        accessoryView.removeFromSuperview()
        guard let avatarConnectingView = accessoryConnectingView,
              let avatarConnectingSuperview = avatarConnectingView.superview else {
            return
        }
        avatarConnectingSuperview.addSubview(accessoryView)
        accessoryOffsetConstraint = accessoryView.leadingAnchor.constraint(equalTo: avatarConnectingView.trailingAnchor, constant: accessorySafeAreaInsets.right)
        accessoryOffsetConstraint?.isActive = true
        accessoryView.centerYAnchor.constraint(equalTo: avatarConnectingView.centerYAnchor).isActive = true
    }

    private func updateOffsets() {
        if let avatarView,
           !avatarView.isHidden {
            avatarView.transform = CGAffineTransform(translationX: -((avatarView.bounds.width + accessorySafeAreaInsets.left) * swipeCompletionRate), y: 0)
        }
        switch containerView.customView.messageType {
        case .incoming:
            customView.transform = .identity
            customView.transform = CGAffineTransform(translationX: -(customView.frame.origin.x * swipeCompletionRate), y: 0)
        case .outgoing:
            let maxOffset = min(frame.origin.x, accessoryView.frame.width)
            customView.transform = .identity
            customView.transform = CGAffineTransform(translationX: -(maxOffset * swipeCompletionRate), y: 0)
            // 调整成头像
//            if let statusView,
//               !statusView.isHidden {
//                statusView.transform = CGAffineTransform(translationX: -(maxOffset * swipeCompletionRate), y: 0)
//            }
            if let rightAvatarView,
               !rightAvatarView.isHidden {
                rightAvatarView.transform = CGAffineTransform(translationX: -(maxOffset * swipeCompletionRate), y: 0)
            }
        }

        accessoryView.transform = CGAffineTransform(translationX: -((accessoryView.bounds.width + accessorySafeAreaInsets.right) * swipeCompletionRate), y: 0)
    }
}
