
import RxSwift
import OUICore
import AVFoundation
import ProgressHUD

class ScanViewController: UIViewController {
    var scanDidComplete: ((String) -> Void)?
    
    private let disposeBag = DisposeBag()

    private let _scanView: DefaultScannerView = {
        let aniView = DefaultLineScanAnimationView()
        let v = DefaultScannerView(animationView: aniView)
        return v
    }()

    private lazy var _popBtn: UIButton = {
        let v = UIButton(type: .custom)
        v.tintColor = .white
        v.setImage(UIImage(systemName: "chevron.left")?.withRenderingMode(.alwaysTemplate), for: .normal)
        v.rx.tap.subscribe { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }.disposed(by: disposeBag)
        
        return v
    }()
    
    private lazy var flashButton: UIButton = {
        let v = UIButton(type: .custom)
        v.setImage(UIImage(nameInBundle: "scan_flashlight_close_icon")?.withTintColor(.white), for: .normal)
        v.setImage(UIImage(nameInBundle: "scan_flashlight_open_icon")?.withTintColor(.white), for: .selected)
        v.imageEdgeInsets = UIEdgeInsets(top: 16.h, left: 16.w, bottom: 20.h, right: 16.w)
        v.tintColor = .white
        v.layer.cornerRadius = 40.h
        v.layer.borderWidth = 12.w
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            v.isSelected = !v.isSelected
            self?.toggleFlashlight()
        }).disposed(by: disposeBag)
        
        return v
    }()
    
    private func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if device.torchMode == .off {
                    try device.setTorchModeOn(level: 1.0)
                } else {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Error toggling flashlight: \(error.localizedDescription)")
            }
        } else {
            print("Torch is not available on this device.")
        }
    }

    private lazy var _photoHelper: PhotoHelper = {
        let v = PhotoHelper()
        v.setConfigToPickImageForScanQrcode()
        v.didPhotoSelected = { [weak self, weak v] (images: [UIImage], _) in
            guard let self, let image = images.first else { return }
            
            ProgressHUD.animate()
            _scanView.scanQrcodeImage(image: image).subscribe { [self] result in
                self.scanResult(result: result?.strScanned)
            }.disposed(by: disposeBag)
        }
        
        return v
    }()
    
    private lazy var pickImageButton: UIButton = {
        let v = UIButton(type: .system)
        v.setImage(UIImage(nameInBundle: "scan_img_icon"), for: .normal)
        v.tintColor = .white.withAlphaComponent(0.54)
        
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            
            _photoHelper.presentPhotoLibrary(byController: self)
        }).disposed(by: disposeBag)
        
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        defer {
            view.addSubview(_popBtn)
            _popBtn.snp.makeConstraints { make in
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.left.equalToSuperview().offset(20)
                make.size.equalTo(44.h)
            }
        }

        view.addSubview(_scanView)
        _scanView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(flashButton)
        flashButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(40.h)
            make.size.equalTo(80.h)
        }
        
        view.addSubview(pickImageButton)
        pickImageButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(60.w)
            make.centerY.equalTo(flashButton)
            make.size.equalTo(40.h)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        _scanView.startScanning().subscribe { [weak self] (result: ScanResult?) in
            self?.scanResult(result: result?.strScanned)
        }.disposed(by: disposeBag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func scanResult(result: String?) {
        DispatchQueue.main.async {
            if let result {
                ProgressHUD.dismiss()
                self.scanDidComplete?(result)
            } else {
                ProgressHUD.error("unrecognized".innerLocalized())
            }
        }
    }
}
