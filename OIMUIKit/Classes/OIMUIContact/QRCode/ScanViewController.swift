
import RxSwift
import UIKit

class ScanViewController: UIViewController {
    var scanDidComplete: ((String) -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        defer {
            view.addSubview(_popBtn)
            _popBtn.snp.makeConstraints { make in
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.left.equalToSuperview().offset(20)
                make.size.equalTo(40)
            }
        }

        _popBtn.rx.tap.subscribe { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }.disposed(by: _disposeBag)

        view.addSubview(_scanView)
        _scanView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        _scanView.startScanning().subscribe { [weak self] (result: ScanResult?) in
            guard let str = result?.strScanned else { return }
            self?.scanDidComplete?(str)
        }.disposed(by: _disposeBag)
    }

    private let _scanView: DefaultScannerView = {
        let aniView = DefaultLineScanAnimationView()
        let v = DefaultScannerView(animationView: aniView)
        return v
    }()

    private let _popBtn: UIButton = {
        let v = UIButton()
        v.setImage(UIImage(nameInBundle: "common_back_icon"), for: .normal)
        return v
    }()

    private let _disposeBag = DisposeBag()
}
