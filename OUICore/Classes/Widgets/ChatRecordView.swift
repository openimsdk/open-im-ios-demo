
import Lottie
import RxSwift
import UIKit

class ChatRecordView: UIView {
    let recordBtn: UIButton = {
        let v = UIButton()
        v.isSelected = true
        v.setBackgroundImage(UIImage(nameInBundle: "inputbar_record_background_selected"), for: .selected)
        v.setBackgroundImage(UIImage(nameInBundle: "inputbar_record_background_unselected"), for: .normal)
        return v
    }()

    private lazy var recordingImageView: AnimationView = {
        let bundle = ViewControllerFactory.getBundle() ?? Bundle.main
        let v = AnimationView(name: "voice_record", bundle: bundle)
        v.loopMode = .autoReverse
        return v
    }()

    private lazy var recordingBackgroundImageView: UIImageView = {
        let v = UIImageView(image: UIImage(nameInBundle: "chattool_voice_background_white_image")?.resizableImage(withCapInsets: UIEdgeInsets(top: 8, left: 8, bottom: 10, right: 8), resizingMode: UIImage.ResizingMode.stretch))
        v.addSubview(recordingImageView)
        recordingImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 140, height: 35))
            make.center.equalToSuperview()
        }
        return v
    }()

    private lazy var cancelRecordingImageView: AnimationView = {
        let bundle = ViewControllerFactory.getBundle() ?? Bundle.main
        let v = AnimationView(name: "voice_record", bundle: bundle)
        v.loopMode = .autoReverse
        return v
    }()

    private lazy var cancelRecordingBackgroundImageView: UIImageView = {
        let v = UIImageView(image: UIImage(nameInBundle: "chattool_voice_background_red_image")?.resizableImage(withCapInsets: UIEdgeInsets(top: 8, left: 8, bottom: 10, right: 8), resizingMode: UIImage.ResizingMode.stretch))
        v.addSubview(cancelRecordingImageView)
        cancelRecordingImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 41, height: 10))
            make.center.equalToSuperview()
        }
        v.isHidden = true
        return v
    }()

    lazy var convertRecordingImageView: AnimationView = {
        let bundle = ViewControllerFactory.getBundle() ?? Bundle.main
        let v = AnimationView(name: "voice_record", bundle: bundle)
        v.loopMode = .autoReverse
        v.isHidden = true
        return v
    }()

    lazy var cancelLabel: UILabel = {
        let v = UILabel()
        v.text = "松开取消".innerLocalized()
        v.font = .systemFont(ofSize: 14, weight: .medium)
        v.textColor = StandardUI.color_BEBEBE
        v.isHidden = true
        return v
    }()

    lazy var cancelBtn: UIButton = {
        let v = UIButton()
        v.setImage(UIImage(nameInBundle: "inputbar_record_cancel_btn_icon_selected"), for: .selected)
        v.setImage(UIImage(nameInBundle: "inputbar_record_cancel_btn_icon_unselected"), for: .normal)
        v.rx.controlEvent(.touchDragInside)
            .subscribe(onNext: {
                print("cancelBtn touchDragInside")
            }).disposed(by: _disposeBag)

        v.rx.controlEvent(.touchDragEnter)
            .subscribe(onNext: {
                print("cancelBtn touchDragEnter")
            }).disposed(by: _disposeBag)
        return v
    }()

    lazy var convertLabel: UILabel = {
        let v = UILabel()
        v.text = "转文字".innerLocalized()
        v.font = .systemFont(ofSize: 14, weight: .medium)
        v.textColor = StandardUI.color_BEBEBE
        v.isHidden = true
        return v
    }()

    lazy var convertBtn: UIButton = {
        let v = UIButton()
        v.setImage(UIImage(nameInBundle: "inputbar_record_convert_btn_icon_selected"), for: .selected)
        v.setImage(UIImage(nameInBundle: "inputbar_record_convert_btn_icon_unselected"), for: .normal)
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let recordIcon = UIImageView(image: UIImage(nameInBundle: "inputbar_record_voice_icon"))
        recordBtn.addSubview(recordIcon)
        recordIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(36)
        }

        addSubview(recordBtn)
        recordBtn.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
        }

        addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(0.5)
            make.bottom.equalTo(recordBtn.snp.top).offset(-25)
        }

        addSubview(cancelLabel)
        cancelLabel.snp.makeConstraints { make in
            make.centerX.equalTo(cancelBtn)
            make.bottom.equalTo(cancelBtn.snp.top).offset(-2)
        }

        addSubview(convertBtn)
        convertBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(1.5)
            make.bottom.equalTo(recordBtn.snp.top).offset(-25)
        }

        addSubview(convertLabel)
        convertLabel.snp.makeConstraints { make in
            make.centerX.equalTo(convertBtn)
            make.bottom.equalTo(convertBtn.snp.top).offset(-2)
        }

        addSubview(recordingBackgroundImageView)
        recordingBackgroundImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 194, height: 95))
        }

        addSubview(cancelRecordingBackgroundImageView)
        cancelRecordingBackgroundImageView.snp.makeConstraints { make in
            make.centerX.equalTo(cancelBtn)
            make.size.equalTo(CGSize(width: 104, height: 95))
            make.centerY.equalToSuperview()
        }

        addSubview(convertRecordingImageView)
        convertRecordingImageView.snp.makeConstraints { make in
            make.centerX.equalTo(convertBtn)
            make.size.equalTo(CGSize(width: 104, height: 95))
            make.centerY.equalToSuperview()
        }
        bindData()
    }

    private func bindData() {
        _cancelBtnSelectedObservable.distinctUntilChanged()
            .bind(to: cancelBtn.rx.isSelected)
            .disposed(by: _disposeBag)
        _cancelBtnSelectedObservable.distinctUntilChanged()
            .map { !$0 }
            .bind(to: cancelLabel.rx.isHidden)
            .disposed(by: _disposeBag)
        _cancelBtnSelectedObservable.distinctUntilChanged()
            .map { !$0 }
            .bind(to: cancelRecordingBackgroundImageView.rx.isHidden)
            .disposed(by: _disposeBag)
        _cancelBtnSelectedObservable.distinctUntilChanged()
            .map { !$0 }
            .bind(to: _recordBtnSelectedObservable)
            .disposed(by: _disposeBag)
        _cancelBtnSelectedObservable.subscribe(onNext: { [weak self] (selected: Bool) in
            if selected {
                self?.cancelRecordingImageView.play()
            } else {
                self?.cancelRecordingImageView.stop()
            }
        }).disposed(by: _disposeBag)

        _convertBtnSelectedObservable.distinctUntilChanged()
            .bind(to: convertBtn.rx.isSelected)
            .disposed(by: _disposeBag)
        _convertBtnSelectedObservable.distinctUntilChanged()
            .map { !$0 }
            .bind(to: convertLabel.rx.isHidden)
            .disposed(by: _disposeBag)
        _convertBtnSelectedObservable.distinctUntilChanged()
            .map { !$0 }
            .bind(to: _recordBtnSelectedObservable)
            .disposed(by: _disposeBag)
        _convertBtnSelectedObservable.distinctUntilChanged()
            .map { !$0 }
            .bind(to: convertRecordingImageView.rx.isHidden)
            .disposed(by: _disposeBag)

        _recordBtnSelectedObservable.bind(to: recordBtn.rx.isSelected).disposed(by: _disposeBag)
        _recordBtnSelectedObservable
            .map { !$0 }
            .bind(to: recordingBackgroundImageView.rx.isHidden)
            .disposed(by: _disposeBag)
        _recordBtnSelectedObservable.subscribe(onNext: { [weak self] (selected: Bool) in
            if selected {
                self?.recordingImageView.play()
            } else {
                self?.recordingImageView.stop()
            }
        }).disposed(by: _disposeBag)
        _recordBtnSelectedObservable.onNext(true)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        #if DEBUG
            print("dealloc \(type(of: self))")
        #endif
    }

    override func removeFromSuperview() {
        super.removeFromSuperview()
        _cancelBtnSelectedObservable.onNext(false)
        _convertBtnSelectedObservable.onNext(false)
        recordBtn.isSelected = true
        cancelLabel.isHidden = true
        convertLabel.isHidden = true
        recordingImageView.stop()
        cancelRecordingImageView.stop()
        convertRecordingImageView.stop()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        recordingImageView.play()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
            _cancelBtnSelectedObservable.onNext(cancelBtn.frame.contains(point))
            _convertBtnSelectedObservable.onNext(convertBtn.frame.contains(point))
        }
    }

    private let _disposeBag = DisposeBag()
    private let _cancelBtnSelectedObservable = PublishSubject<Bool>.init()
    private let _convertBtnSelectedObservable = PublishSubject<Bool>.init()
    private let _recordBtnSelectedObservable = PublishSubject<Bool>.init()
}
