//






import UIKit
import RxSwift

class ScanViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        defer {
            view.addSubview(_popBtn)
            _popBtn.snp.makeConstraints { (make) in
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.left.equalToSuperview().offset(20)
                make.size.equalTo(40)
            }
        }
        
        _popBtn.rx.tap.subscribe { [weak self] (_) in
            self?.dismiss(animated: true, completion: nil)
        }.disposed(by: _disposeBag)

        view.addSubview(_scanView)
        _scanView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        _scanView.startScanning().subscribe { (result: ScanResult?) in
            guard let str = result?.strScanned else { return }
            print(str)
        }.disposed(by: _disposeBag)
    }
    
    private let _scanView: DefaultScannerView = {
        let aniView = DefaultLineScanAnimationView.init()
        let v = DefaultScannerView.init(animationView: aniView)
        return v
    }()
    
    private let _popBtn: UIButton = {
        let v = UIButton()
        v.setImage(UIImage.init(nameInBundle: "common_back_icon"), for: .normal)
        return v
    }()
    
    private let _disposeBag = DisposeBag()
}
