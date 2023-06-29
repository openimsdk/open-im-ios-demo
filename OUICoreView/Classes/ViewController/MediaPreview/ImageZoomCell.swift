
import Lantern

class ImageZoomCell: LanternImageCell {
    
    var frameChangedHandler: ((CGRect) -> Void)?
    var dismissHandler: (() -> Void)?
    
    override func onPan(_ pan: UIPanGestureRecognizer) {
        super.onPan(pan)
        
        switch pan.state {
        case .changed:
            frameChangedHandler?(imageView.frame)
            
        case .ended, .cancelled:
            frameChangedHandler?(imageView.frame)
            let isDown = pan.velocity(in: self).y > 0
            if isDown {
                dismissHandler?()
            }
        default:
            break
        }
    }
}
