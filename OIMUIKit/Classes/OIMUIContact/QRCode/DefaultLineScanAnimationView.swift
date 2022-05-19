//






import UIKit

class DefaultLineScanAnimationView: UIView, ScanAnimationViewProtocol {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.init(white: 0, alpha: 0.4)
        self.addSubview(_focusView)
        _focusView.snp.makeConstraints { (make) in
            make.size.equalTo(250)
            make.center.equalToSuperview()
        }

        self.addSubview(_lineImageView)
        _lineImageView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()
        let frame = self._focusView.convert(self._focusView.bounds, to: self.window)
        context?.clear(frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimation() {
        _allowAnimate = true
        self._lineImageView.isHidden = false
        _animate()
    }

    private func _animate() {
        if !_allowAnimate {
            self._lineImageView.isHidden = true
            return
        }
        let imageY = _focusView.frame.origin.y
        self._lineImageView.frame.origin.y = imageY
        UIView.animate(withDuration: 1.4) {
            let targetY = imageY + self._focusView.frame.size.height - 15
            self._lineImageView.frame.origin.y = targetY
        } completion: { (_) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self._animate()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func stopAnimation() {
        _allowAnimate = false
    }

    private var _allowAnimate: Bool = false
    private lazy var _lineImageView: UIImageView = UIImageView.init(image: UIImage.init(nameInBundle: "common_qrcode_scan_line_image"))
    private let _focusView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.init(white: 1, alpha: 0)
        return v
    }()
}
