
import UIKit

class LayoutButton: UIButton {
    enum Position {
        case top
        case bottom
        case left
        case right
    }

    private var position: Position?
    private var space: CGFloat = 0

    private var _originBounds: CGRect = .zero

    convenience init(imagePosition position: Position, atSpace space: CGFloat = 0) {
        self.init(type: .custom)
        self.position = position
        self.space = space
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        if let p = position {
            switch p {
            case .left, .right:
                size.width += space
            case .top, .bottom:
                let titleHeight = titleLabel?.bounds.height ?? 0
                let imageHeight = imageView?.bounds.height ?? 0
                size.height = space + titleHeight + imageHeight
            }
        } else {
            size.width += space
        }
        return size
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if _originBounds == bounds {
            return
        }
        _originBounds = bounds

        if let position = position {
            switch position {
            case .top:
                let titleHeight = titleLabel?.bounds.height ?? 0
                let imageHeight = imageView?.bounds.height ?? 0
                let imageWidth = imageView?.bounds.width ?? 0
                let titleWidth = titleLabel?.bounds.width ?? 0
                titleEdgeInsets = UIEdgeInsets(top: (titleHeight + space) * 0.5, left: -imageWidth * 0.5, bottom: -space, right: imageWidth * 0.5)
                imageEdgeInsets = UIEdgeInsets(top: 0, left: titleWidth * 0.5, bottom: imageHeight + space, right: -titleWidth * 0.5)

            case .bottom:
                let titleHeight = titleLabel?.bounds.height ?? 0
                let imageHeight = imageView?.bounds.height ?? 0
                let imageWidth = imageView?.bounds.width ?? 0
                let titleWidth = titleLabel?.bounds.width ?? 0
                titleEdgeInsets = UIEdgeInsets(top: -(titleHeight + space) * 0.5, left: -imageWidth * 0.5, bottom: space, right: imageWidth * 0.5)
                imageEdgeInsets = UIEdgeInsets(top: imageHeight + space, left: titleWidth * 0.5, bottom: 0, right: -titleWidth * 0.5)

            case .left:
                titleEdgeInsets = UIEdgeInsets(top: 0, left: space, bottom: 0, right: 0)
                imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: space)
            case .right:

                let imageWidth = (imageView?.bounds.width ?? 0) + space * 0.5
                let titleWidth = (titleLabel?.bounds.width ?? 0) + space * 0.5
                titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth, bottom: 0, right: imageWidth)
                imageEdgeInsets = UIEdgeInsets(top: 0, left: titleWidth, bottom: 0, right: -titleWidth)
            }
        }
    }
}
