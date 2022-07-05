
import UIKit

class NoIntrinsicSizeButton: UIButton {
    weak var delegate: UIResponder?
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.touchesMoved(touches, with: event)
    }
}
