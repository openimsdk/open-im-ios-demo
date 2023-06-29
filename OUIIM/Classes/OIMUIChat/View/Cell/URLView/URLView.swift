
import ChatLayout
import Foundation
import LinkPresentation
import UIKit
import OUICore

@available(iOS 13, *)
final class URLView: UIView, ContainerCollectionViewCellDelegate {

    private var linkView: LPLinkView?

    private var controller: URLController?

    private var viewPortWidth: CGFloat = 300

    private var linkWidthConstraint: NSLayoutConstraint?

    private var linkHeightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        translatesAutoresizingMaskIntoConstraints = false
    }

    func prepareForReuse() {
        linkView?.removeFromSuperview()
        linkView = nil
    }

    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        viewPortWidth = layoutAttributes.layoutFrame.width
        setupSize()
    }

    func reloadData() {
        setupLinkView()
    }

    func setup(with controller: URLController) {
        self.controller = controller
        reloadData()
    }

    private func setupLinkView() {
        UIView.performWithoutAnimation {
            linkView?.removeFromSuperview()
            guard let controller else {
                return
            }

            let newLinkView: LPLinkView
            switch controller.metadata {
            case let .some(metadata):
                newLinkView = LPLinkView(metadata: metadata)
            case .none:
                newLinkView = LPLinkView(url: controller.url)
            }
            addSubview(newLinkView)
            newLinkView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                newLinkView.topAnchor.constraint(equalTo: self.topAnchor),
                newLinkView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                newLinkView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                newLinkView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            ])

            linkWidthConstraint = newLinkView.widthAnchor.constraint(equalToConstant: 310)
            linkWidthConstraint?.priority = UILayoutPriority(999)
            linkWidthConstraint?.isActive = true

            linkHeightConstraint = newLinkView.heightAnchor.constraint(equalToConstant: 40)
            linkHeightConstraint?.priority = UILayoutPriority(999)
            linkHeightConstraint?.isActive = true

            self.linkView = newLinkView
        }

    }

    private func setupSize() {
        guard let linkView else {
            return
        }
        let contentSize = linkView.intrinsicContentSize
        let maxWidth = min(viewPortWidth * StandardUI.maxWidth, contentSize.width)

        let newContentRect = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: contentSize.height * maxWidth / contentSize.width))

        linkWidthConstraint?.constant = newContentRect.width
        linkHeightConstraint?.constant = newContentRect.height

        linkView.bounds = newContentRect
        // It is funny that since IOS 14 it can give slightly different values depending if it was drawn before or not.
        // Thank you Apple. Dont be surprised that the web preview may lightly jump and cause the small jumps
        // of the whole layout.
        linkView.sizeToFit()

        setNeedsLayout()
        layoutIfNeeded()
    }

}
