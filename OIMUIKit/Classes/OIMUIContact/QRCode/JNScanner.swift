
import AVFoundation
import UIKit

class JNScanner: NSObject, AVCaptureMetadataOutputObjectsDelegate, AVCapturePhotoCaptureDelegate {
    lazy var cameraLayer: AVCaptureVideoPreviewLayer = {
        let v = AVCaptureVideoPreviewLayer(session: _session)
        v.videoGravity = .resizeAspectFill
        return v
    }()

    var scanSuccessBlock: (([ScanResult]) -> Void)?

    override init() {
        super.init()
        guard let device = _device else {
            return
        }

        do {
            _input = try AVCaptureDeviceInput(device: device)
        } catch {
            print("scan input error:\(error.localizedDescription)")
        }
        guard let input = _input else {
            return
        }

        if _session.canAddInput(input) {
            _session.addInput(input)
        }

        if _session.canAddOutput(_output) {
            _session.addOutput(_output)
        }

        if _session.canAddOutput(_stillImgOutput) {
            _session.addOutput(_stillImgOutput)
        }

        if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.continuousAutoFocus) {
            do {
                try input.device.lockForConfiguration()
                input.device.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
                input.device.unlockForConfiguration()
            } catch {
                print("lock configuration error:\(error.localizedDescription)")
            }
        }
    }

    func start() {
        _needScan = true
        // 只可以在调用时设置，在初始化时设置运行时会崩溃
        let types = [AVMetadataObject.ObjectType.qr as NSString,
                     AVMetadataObject.ObjectType.ean13 as NSString,
                     AVMetadataObject.ObjectType.code128 as NSString] as [AVMetadataObject.ObjectType]
        _output.metadataObjectTypes = types

        if !_session.isRunning {
            _session.startRunning()
        }
    }

    func stop() {
        _needScan = false
        if _session.isRunning {
            _session.stopRunning()
        }
    }

    func setTorch(on: Bool) -> Bool {
        guard checkIfTorchUsable() else {
            return false
        }
        do {
            try _input?.device.lockForConfiguration()
            _input?.device.torchMode = on ? .on : .off
            _input?.device.unlockForConfiguration()
            return true
        } catch {
            print("lock configuration error:\(error.localizedDescription)")
            return false
        }
    }

    func getTorchOn() -> Bool {
        guard let device = _device else {
            return false
        }

        return device.torchMode == .on
    }

    func checkIfTorchUsable() -> Bool {
        guard let device = _device else {
            return false
        }

        let existTorch = device.isFlashAvailable || device.isTorchAvailable
        return existTorch
    }

    func scanQRImage(image: UIImage) -> [ScanResult] {
        let det = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        guard let img = CIImage(image: image), let detector = det else {
            return []
        }
        let features = detector.features(in: img, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let results = features.filter { (feature: CIFeature) -> Bool in
            feature.isKind(of: CIQRCodeFeature.self)
        }.compactMap { feature -> CIQRCodeFeature? in
            feature as? CIQRCodeFeature
        }.compactMap { (feature: CIQRCodeFeature) -> ScanResult? in
            ScanResult(strScanned: feature.messageString, imgScanned: image, locations: nil)
        }

        return results
    }

    func metadataOutput(_: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from _: AVCaptureConnection) {
        // 只处理一个扫描结果
        if !_needScan {
            return
        }
        _needScan = false

        _scanResults.removeAll()
        for meta in metadataObjects {
            guard let code = meta as? AVMetadataMachineReadableCodeObject else {
                continue
            }
            let item = ScanResult(strScanned: code.stringValue, imgScanned: nil, locations: code.corners)
            _scanResults.append(item)
            _capture()
        }
    }

    func photoOutput(_: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        stop()
        if let err = error {
            print("scan output error:\(err.localizedDescription)")
            scanSuccessBlock?(_scanResults)
            return
        }

        if let data = photo.fileDataRepresentation() {
            var result: [ScanResult] = []
            let image = UIImage(data: data)
            for item in _scanResults {
                let nItem = ScanResult(strScanned: item.strScanned, imgScanned: image, locations: item.locations)
                result.append(nItem)
            }
            scanSuccessBlock?(result)
        }
    }

    func photoOutput(_: AVCapturePhotoOutput, willCapturePhotoFor _: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }

    deinit {
        #if DEBUG
            print("dealloc \(type(of: self))")
        #endif
    }

    private func _capture() {
        let settings = AVCapturePhotoSettings()
        _stillImgOutput.capturePhoto(with: settings, delegate: self)
    }

    private let _session: AVCaptureSession = {
        let v = AVCaptureSession()
        v.sessionPreset = AVCaptureSession.Preset.high
        return v
    }()

    private let _device = AVCaptureDevice.default(for: .video)
    private var _input: AVCaptureDeviceInput?
    private lazy var _output: AVCaptureMetadataOutput = {
        let v = AVCaptureMetadataOutput()
        v.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        return v
    }()

    private var _stillImgOutput = AVCapturePhotoOutput()
    private var _scanResults: [ScanResult] = []
    private var _needScan: Bool = false
}

struct ScanResult {
    let strScanned: String?
    let imgScanned: UIImage?
    let locations: [CGPoint]?
}
