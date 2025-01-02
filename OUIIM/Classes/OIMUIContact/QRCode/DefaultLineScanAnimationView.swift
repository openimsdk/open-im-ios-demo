
import OUICore

class DefaultLineScanAnimationView: UIView, ScanAnimationViewProtocol {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        
        addSubview(_focusView)
        _focusView.snp.makeConstraints { make in
            make.size.equalTo(250.h)
            make.center.equalToSuperview()
        }

        addSubview(_lineImageView)
        _lineImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()
        let frame = _focusView.convert(_focusView.bounds, to: window)
        context?.clear(frame)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimation() {
        _allowAnimate = true
        _lineImageView.isHidden = false
        _animate()
    }

    private func _animate(reverse: Bool = false) {
        if reverse {
            let imageY = _focusView.frame.minY
            
            UIView.animate(withDuration: 2) { [self] in
                self._lineImageView.frame.origin.y = imageY
            } completion: { [self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self._animate()
                }
            }
        } else {
            if !_allowAnimate {
                _lineImageView.isHidden = true
                return
            }
            let imageY = _focusView.frame.maxY
            
            UIView.animate(withDuration: 2) { [self] in
                self._lineImageView.frame.origin.y = imageY - 15.h
            } completion: { [self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self._animate(reverse: true)
                }
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
    private lazy var _lineImageView: UIImageView = .init(image: UIImage(nameInBundle: "common_qrcode_scan_line_image"))
    private let _focusView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0)
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        v.layer.borderWidth = 1.0
        v.layer.cornerRadius = 4
        
        return v
    }()
}
