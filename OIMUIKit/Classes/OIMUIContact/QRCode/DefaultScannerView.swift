
import RxSwift
import SnapKit
import UIKit

protocol ScanAnimationViewProtocol: UIView {
    func startAnimation()
    func stopAnimation()
}

class DefaultScannerView: UIView {
    init(animationView: ScanAnimationViewProtocol) {
        _animationView = animationView
        super.init(frame: .zero)
        layer.addSublayer(_scanner.cameraLayer)
        addSubview(_animationView)
        _animationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func startScanning() -> Observable<ScanResult?> {
        _animationView.startAnimation()
        _scanner.start()
        return Observable<ScanResult?>.create { [weak self] observer -> Disposable in
            self?._scanner.scanSuccessBlock = { results in
                self?._animationView.stopAnimation()
                observer.onNext(results.first)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    func stopScanning() {
        _animationView.stopAnimation()
        _scanner.stop()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        _scanner.cameraLayer.frame = bounds
    }

    private let _animationView: ScanAnimationViewProtocol
    private let _scanner = JNScanner()

    deinit {
        #if DEBUG
            print("dealloc \(type(of: self))")
        #endif
    }
}
