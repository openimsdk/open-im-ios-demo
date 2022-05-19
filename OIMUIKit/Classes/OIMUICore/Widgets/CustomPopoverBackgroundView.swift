

    

    

import UIKit

class CustomPopoverBackgroundView: UIPopoverBackgroundView {

    private var _arrowOffSet: CGFloat = 0
    private var _arrowDirection: UIPopoverArrowDirection = .any
    private let _arrowImageView: UIImageView
    private lazy var backgroundView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.init(hex: 0x666666)
        v.layer.cornerRadius = self.cornerRadius
        return v
    }()

    let cornerRadius: CGFloat = 4

    override class func arrowBase() -> CGFloat {
        return 28
    }

    override class func arrowHeight() -> CGFloat {
        return 14
    }

    override class func contentViewInsets() -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 10, left: 16, bottom: 10, right: 16)
    }

    override var arrowOffset: CGFloat {
        set {
            _arrowOffSet = newValue
            setNeedsLayout()
        }
        get {
            return _arrowOffSet
        }
    }

    override var arrowDirection: UIPopoverArrowDirection {
        set {
            _arrowDirection = newValue
            setNeedsLayout()
        }

        get {
            return _arrowDirection
        }
    }

    override init(frame: CGRect) {
        guard let arrow = UIImage.init(nameInBundle: "popover_arrow_icon") else {
            fatalError("请替换图片资源")
        }
        _arrowImageView = UIImageView.init(image: arrow)
        super.init(frame: frame)
        self.addSubview(backgroundView)
        self.addSubview(_arrowImageView)
        
        self.layer.shadowColor = UIColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var popoverImageOriginX: CGFloat = 0
        var popoverImageOriginY: CGFloat = 0

        var popoverImageWidth: CGFloat = self.bounds.size.width
        var popoverImageHeight: CGFloat = self.bounds.size.height

        var arrowImageOriginX: CGFloat = 0
        var arrowImageOriginY: CGFloat = 0

        var arrowImageWidth: CGFloat = Self.arrowBase()
        var arrowImageHeight: CGFloat = Self.arrowHeight()

        let cornerRadius: CGFloat = self.cornerRadius
        let ARROW_HEIGHT = Self.arrowHeight()
        let ARROW_WIDTH = Self.arrowBase()

        switch (self.arrowDirection) {
        case .up:
            popoverImageOriginY = ARROW_HEIGHT - 2
            popoverImageHeight = self.bounds.size.height - ARROW_HEIGHT

            arrowImageOriginX = round((self.bounds.size.width - ARROW_WIDTH)/2.0 + self.arrowOffset)

            arrowImageOriginX = min(arrowImageOriginX, self.bounds.size.width - ARROW_WIDTH - cornerRadius)
            arrowImageOriginX = max(arrowImageOriginX, cornerRadius)
            _arrowImageView.transform = CGAffineTransform.init(rotationAngle: CGFloat.pi)
        case .down:

            popoverImageHeight = self.bounds.size.height - ARROW_HEIGHT + 2

            arrowImageOriginX = round((self.bounds.size.width - ARROW_WIDTH) / 2 + self.arrowOffset)

            arrowImageOriginX = min(arrowImageOriginX, self.bounds.size.width - ARROW_WIDTH - cornerRadius)
            arrowImageOriginX = max(arrowImageOriginX, cornerRadius)

            arrowImageOriginY = popoverImageHeight - 2
        case .left:

            popoverImageOriginX = ARROW_HEIGHT - 2
            popoverImageWidth = self.bounds.size.width - ARROW_HEIGHT

            arrowImageOriginY = round((self.bounds.size.height - ARROW_WIDTH) / 2 + self.arrowOffset)

            arrowImageOriginY = min(arrowImageOriginY, self.bounds.size.height - ARROW_WIDTH - cornerRadius)
            arrowImageOriginY = max(arrowImageOriginY, cornerRadius)

            arrowImageWidth = ARROW_HEIGHT
            arrowImageHeight = ARROW_WIDTH
            _arrowImageView.transform = CGAffineTransform.init(rotationAngle: CGFloat.pi/2)
        case .right:

            popoverImageWidth = self.bounds.size.width - ARROW_HEIGHT + 2

            arrowImageOriginX = popoverImageWidth - 2
            arrowImageOriginY = round((self.bounds.size.height - ARROW_WIDTH) / 2 + self.arrowOffset)

            arrowImageOriginY = min(arrowImageOriginY, self.bounds.size.height - ARROW_WIDTH - cornerRadius)
            arrowImageOriginY = max(arrowImageOriginY, cornerRadius)

            arrowImageWidth = ARROW_HEIGHT
            arrowImageHeight = ARROW_WIDTH
            _arrowImageView.transform = CGAffineTransform.init(rotationAngle: -CGFloat.pi/2)
        default:
            popoverImageHeight = self.bounds.size.height - ARROW_HEIGHT + 2
        }

        self.backgroundView.frame = CGRect.init(x: popoverImageOriginX, y: popoverImageOriginY, width: popoverImageWidth, height: popoverImageHeight)
        self._arrowImageView.frame = CGRect.init(x: arrowImageOriginX, y: arrowImageOriginY, width: arrowImageWidth, height: arrowImageHeight)
    }
}
