

    
    

import UIKit
import RxSwift
import RxCocoa
import RxKeyboard
import SnapKit
import AVFAudio

protocol ChatToolBarDelegate: AnyObject {
    func tb_didTouchSend(text: String)
    func tb_didAudioRecordEnd(url: String, duration: Int)
}

class ChatToolBar: UIView {
    
    weak var delegate: ChatToolBarDelegate?
    
    static let defaultHeight: CGFloat = 50
    
    weak var quoteMessage: MessageInfo? {
        didSet {
            if let message = quoteMessage {
                quoteLabel.text = message.senderNickname?.append(string: ":").append(string: message.getAbstruct())
                quoteContainerView.isHidden = false
            } else {
                quoteLabel.text = nil
                quoteContainerView.isHidden = true
            }
        }
    }
    
    lazy var voiceSwitchBtn: UIButton = {
        let v = UIButton()
        v.setImage(UIImage.init(nameInBundle: "inputbar_audio_btn_icon"), for: .normal)
        v.setImage(UIImage.init(nameInBundle: "inputbar_keyboard_btn_icon"), for: .selected)
        v.isSelected = false
        v.rx.controlEvent(.touchDown).subscribe(onNext: { [weak self] in
            guard let sself = self else { return }
            let state: ChatBarStatus = sself.barStatusRelay.value == .record ? .keyboard : .record
            sself.barStatusRelay.accept(state)
        }).disposed(by: _disposeBag)
        return v
    }()
    
    lazy var emojiBtn: UIButton = {
        let v = UIButton()
        v.setImage(UIImage.init(nameInBundle: "inputbar_emoji_btn_icon"), for: .normal)
        v.setImage(UIImage.init(nameInBundle: "inputbar_keyboard_btn_icon"), for: .selected)
        v.isSelected = false
        v.rx.controlEvent(.touchDown).subscribe(onNext: { [weak self] in
            guard let sself = self else { return }
            let state: ChatBarStatus = sself.barStatusRelay.value == .emoji ? .keyboard : .emoji
            sself.barStatusRelay.accept(state)
        }).disposed(by: _disposeBag)
        return v
    }()
    
    lazy var moreBtn: UIButton = {
        let v = UIButton()
        v.setImage(UIImage.init(nameInBundle: "inputbar_more_btn_icon"), for: .normal)
        v.rx.controlEvent(.touchDown).subscribe(onNext: { [weak self] in
            guard let sself = self else { return }
            let state: ChatBarStatus = sself.barStatusRelay.value == .pad ? .default : .pad
            sself.barStatusRelay.accept(state)
        }).disposed(by: _disposeBag)
        return v
    }()
        
    lazy var textInputView: UITextView = {
        let v = UITextView()
        v.layoutManager.allowsNonContiguousLayout = false
        v.isExclusiveTouch = true
        v.returnKeyType = .send
        v.backgroundColor = .white
        v.enablesReturnKeyAutomatically = true
        v.isUserInteractionEnabled = true
        v.layer.cornerRadius = 4
        v.layer.masksToBounds = true
        v.isScrollEnabled = false
        v.delegate = self
        v.font = .systemFont(ofSize: 14)
        v.textColor = StandardUI.color_333333
        return v
    }()
    
    lazy var voiceInputBtn: NoIntrinsicSizeButton = {
        let v = NoIntrinsicSizeButton()
        v.setTitle("按住开始说话".innerLocalized(), for: .normal)
        v.setTitle("正在说话".innerLocalized(), for: .highlighted)
        v.titleLabel?.font = .systemFont(ofSize: 15)
        v.setTitleColor(.white, for: .normal)
        v.backgroundColor = StandardUI.color_1D6BED
        v.layer.cornerRadius = 4
        v.layer.masksToBounds = true
        v.isHidden = true
        v.rx.controlEvent(.touchDown)
            .subscribe(onNext: { [weak self] in
                guard let sself = self else { return }
                self?.parentView.addSubview(sself.recordView)
                sself.recordView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                self?.startRecord()
            }).disposed(by: _disposeBag)
        
        v.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                print("touchUpInside")
                self?.recordView.removeFromSuperview()
                print("录制完毕，发送语音消息")
                self?.stopRecord()
            }).disposed(by: _disposeBag)
        
        v.rx.controlEvent(.touchUpOutside)
            .subscribe(onNext: { [weak self] in
                guard let sself = self else { return }
                if sself.recordView.cancelBtn.isSelected {
                    self?.stopRecord()
                    self?.recordView.removeFromSuperview()
                    return
                }
                if sself.recordView.convertBtn.isSelected {
                    print("开始语音转换文字")
                    self?.recordView.removeFromSuperview()
                    return
                }
                self?.stopRecord()
                self?.recordView.removeFromSuperview()
            }).disposed(by: _disposeBag)
        v.delegate = self.recordView
        return v
    }()
    
    let recordView: ChatRecordView = {
        let v = ChatRecordView()
        v.backgroundColor = .brown
        return v
    }()
    
    lazy var quoteLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 12)
        v.textColor = StandardUI.color_666666
        v.numberOfLines = 2
        return v
    }()
    
    lazy var quoteDeleteBtn: UIButton = {
        let v = UIButton()
        v.setImage(UIImage.init(nameInBundle: "inputbar_delete_btn_icon"), for: .normal)
        return v
    }()
    
    lazy var padView: ChatPluginPadView = {
        let v = ChatPluginPadView.init(frame: CGRect.init(x: 0, y: 0, width: kScreenWidth, height: 220))
        return v
    }()
    
    init(moveTo superView: UIView, conversation: ConversationInfo) {
        self.conversation = conversation
        self.parentView = superView
        super.init(frame: .zero)
        initView()
        bindData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initView() {
        
        self.backgroundColor = StandardUI.color_999999
        self.addSubview(voiceSwitchBtn)
        voiceSwitchBtn.snp.makeConstraints { make in
            make.size.equalTo(30)
            make.left.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        
        let vStack: UIStackView = {
            let v = UIStackView.init(arrangedSubviews: [textInputView, quoteContainerView])
            textInputView.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(30)
                textHeightConstraint = make.height.equalTo(30).priority(.low).constraint
            }
            quoteContainerView.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(20)
            }
            v.axis = .vertical
            v.distribution = .equalSpacing
            v.spacing = 8
            return v
        }()
        
        self.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerY.equalTo(voiceSwitchBtn)
            make.left.equalTo(voiceSwitchBtn.snp.right).offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        self.addSubview(textInputCover)
        textInputCover.snp.makeConstraints { make in
            make.edges.equalTo(textInputView)
        }
        
        let hStack: UIStackView = {
            let v = UIStackView.init(arrangedSubviews: [emojiBtn, moreBtn, sendBtn])
            emojiBtn.snp.makeConstraints { make in
                make.size.equalTo(30)
            }
            moreBtn.snp.makeConstraints { make in
                make.size.equalTo(30)
            }
            sendBtn.snp.makeConstraints { make in
                make.size.equalTo(CGSize.init(width: 43, height: 30))
            }
            v.axis = .horizontal
            v.distribution = .fillProportionally
            v.spacing = 8
            v.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
            return v
        }()
        
        self.addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(8)
            make.left.equalTo(textInputView.snp.right).offset(8)
            make.centerY.equalTo(voiceSwitchBtn)
        }
        
        self.addSubview(voiceInputBtn)
        voiceInputBtn.snp.makeConstraints { make in
            make.left.equalTo(voiceSwitchBtn.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
            make.right.equalTo(hStack.snp.left).offset(-8)
        }
        
        parentView.addSubview(self)
        self.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            bottomConstraint = make.bottom.equalTo(parentView.safeAreaLayoutGuide.snp.bottom).constraint
            make.height.greaterThanOrEqualTo(ChatToolBar.defaultHeight)
        }
    }
    
    func bindData() {
        self.barStatusRelay.distinctUntilChanged().subscribe(onNext: { [weak self] (barStatus: ChatBarStatus) in
            switch barStatus {
            case .default:
                self?.setVoiceInput(visible: false)
                self?.setEmojiInput(visible: false)
                self?.setPadInput(visible: false)
                self?.setTextInput(visible: true)
                self?.textInputView.resignFirstResponder()
            case .keyboard:
                self?.setVoiceInput(visible: false)
                self?.setEmojiInput(visible: false)
                self?.setPadInput(visible: false)
                self?.setTextInput(visible: true)
            case .pad:
                self?.setVoiceInput(visible: false)
                self?.setEmojiInput(visible: false)
                self?.setPadInput(visible: true)
                self?.setTextInput(visible: false)
            case .emoji:
                self?.setVoiceInput(visible: false)
                self?.setEmojiInput(visible: true)
                self?.setPadInput(visible: false)
                self?.setTextInput(visible: false)
            case .record:
                self?.setVoiceInput(visible: true)
                self?.setEmojiInput(visible: false)
                self?.setPadInput(visible: false)
                self?.setTextInput(visible: false)
            }
        }).disposed(by: _disposeBag)
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                let offset = keyboardVisibleHeight > 0 ? (kSafeAreaBottomHeight - keyboardVisibleHeight) : (-keyboardVisibleHeight)
                self?.bottomConstraint?.update(offset: offset)
            }).disposed(by: _disposeBag)
        
        let textCoverTap: UITapGestureRecognizer = UITapGestureRecognizer()
        textInputCover.addGestureRecognizer(textCoverTap)
        textCoverTap.rx.event.subscribe(onNext: { [weak self] _ in
            self?.barStatusRelay.accept(.keyboard)
        }).disposed(by: _disposeBag)
        
        textInputView.rx.didChange.subscribe(onNext: { [weak self] in
            guard let sself = self else { return }
            let height = sself.textInputView.contentSize.height
            let maxHeight: CGFloat = 100
            let offset: CGFloat = height > maxHeight ? maxHeight : height
            self?.textInputView.isScrollEnabled = height > maxHeight
            self?.textHeightConstraint?.updateOffset(amount: offset)
            self?.textInputView.scrollRangeToVisible(NSRange.init(location: 0, length: sself.textInputView.attributedText.string.count))
            sself.sendBtn.isHidden = sself.textInputView.text.isEmpty
        }).disposed(by: _disposeBag)
        
        quoteDeleteBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.quoteMessage = nil
            self?.quoteLabel.text = nil
            self?.quoteContainerView.isHidden = true
        }).disposed(by: _disposeBag)
        
        emojiView.deleteBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.textInputView.deleteBackward()
        }).disposed(by: _disposeBag)
    }
    
    private func setVoiceInput(visible: Bool) {
        voiceSwitchBtn.isSelected = visible
        if visible {
            textInputView.isHidden = true
            textInputCover.isHidden = true
            voiceInputBtn.isHidden = false
            if textInputView.isFirstResponder {
                textInputView.resignFirstResponder()
            }
            quoteContainerView.isHidden = true
            sendBtn.isHidden = true
        } else {
            textInputView.isHidden = false
            if quoteMessage != nil {
                quoteContainerView.isHidden = false
            }
            voiceInputBtn.isHidden = true
            sendBtn.isHidden = textInputView.text.isEmpty
        }
    }
    
    private func setEmojiInput(visible: Bool) {
        emojiBtn.isSelected = visible
        if visible {
            textInputView.isHidden = false
            textInputCover.isHidden = true
            if quoteMessage != nil {
                quoteContainerView.isHidden = false
            }
            voiceInputBtn.isHidden = true
            textInputView.inputView = emojiView
            textInputView.tintColor = .systemBlue
            if !textInputView.isFirstResponder {
                textInputView.becomeFirstResponder()
            }
            textInputView.reloadInputViews()
        }
    }
    
    private func setPadInput(visible: Bool) {
        if visible {
            textInputView.isHidden = false
            textInputCover.isHidden = false
            voiceInputBtn.isHidden = true
            textInputView.inputView = padView
            if !textInputView.isFirstResponder {
                textInputView.becomeFirstResponder()
            }
            textInputView.tintColor = .clear
            textInputView.reloadInputViews()
            if quoteMessage != nil {
                quoteContainerView.isHidden = false
            }
        }
    }
    
    private func setTextInput(visible: Bool) {
        if visible {
            textInputView.isHidden = false
            textInputCover.isHidden = true
            if quoteMessage != nil {
                quoteContainerView.isHidden = false
            }
            voiceInputBtn.isHidden = true
            textInputView.inputView = nil
            textInputView.tintColor = .systemBlue
            if !textInputView.isFirstResponder && barStatusRelay.value == .keyboard {
                textInputView.becomeFirstResponder()
            }
            if barStatusRelay.value == .keyboard {
                textInputView.reloadInputViews()
            }
        }
    }
    
    private lazy var sendBtn: UIButton = {
        let v = UIButton()
        v.setTitle("发送".innerLocalized(), for: .normal)
        v.backgroundColor = StandardUI.color_1B72EC
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        v.setTitleColor(UIColor.white, for: .normal)
        v.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        v.isHidden = true
        v.rx.tap.map{ [weak self] _ -> Bool in
            guard let sself = self else { return false }
            return !sself.textInputView.text.isEmpty
        }.subscribe(onNext: { [weak self] (contentNotEmpty: Bool) in
            if contentNotEmpty {
                self?.sendAndClearText()
            }
        }).disposed(by: _disposeBag)
        return v
    }()
    
    private let _disposeBag = DisposeBag()
    private var barStatusRelay: BehaviorRelay<ChatBarStatus> = .init(value: ChatBarStatus.default)
    
    private lazy var quoteContainerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.addSubview(quoteLabel)
        quoteLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(2)
            make.left.equalToSuperview().offset(4)
        }
        v.addSubview(quoteDeleteBtn)
        quoteDeleteBtn.snp.makeConstraints { make in
            make.size.equalTo(20)
            make.left.equalTo(quoteLabel.snp.right).offset(5)
            make.right.equalToSuperview().offset(-4)
            make.centerY.equalToSuperview()
        }
        v.layer.cornerRadius = 2
        v.layer.masksToBounds = true
        v.isHidden = true
        return v
    }()
    
    private let textInputCover: UIView = {
        let v = UIView()
        return v
    }()
    
    private let conversation: ConversationInfo
    private weak var parentView: UIView!
    
    private lazy var emojiView: ChatEmojiView = {
        let v = ChatEmojiView.init(frame: CGRect.init(x: 0, y: 0, width: kScreenWidth, height: 200))
        v.backgroundColor = .white
        v.delegate = self
        return v
    }()
        
    private var bottomConstraint: Constraint?
    private var textHeightConstraint: Constraint?
    
    private lazy var _recorder: AVAudioRecorder = {
        let voicePath: String = NSHomeDirectory() + "/Documents/voice.wav"
        let fileUrl: URL = URL.init(fileURLWithPath: voicePath)
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 8000,
            AVNumberOfChannelsKey: 2
        ]
        do {
            let v = try AVAudioRecorder.init(url: fileUrl, settings: settings)
            v.delegate = self
    
            return v
        } catch {
            print("初始化Recorder失败：\(error.localizedDescription)")
        }
        return AVAudioRecorder.init()
    }()
    
    private var _recordingTimer: Timer?
    private var _seconds: Int = 0
    
    enum ChatBarStatus {
        case `default`
        case keyboard
        case pad
        case emoji
        case record
    }
    
    private func sendAndClearText() {
        delegate?.tb_didTouchSend(text: textInputView.textStorage.string)
        textInputView.text = nil
        quoteMessage = nil
        textInputView.resignFirstResponder()
    }
    
    private func startRecord() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let sself = self else { return }
            if !granted {
                
                return
            }
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(AVAudioSession.Category.record)
                try session.setActive(true)
            } catch {
                print("AudioSession初始化失败：", error.localizedDescription)
            }
            if !sself._recorder.prepareToRecord() {
                print("prepare record failed")
                return
            }
            if !sself._recorder.record() {
                print("start record failed")
                return
            }
            sself._seconds = 0
            sself._recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
                guard let sself = self else { return }
                self?._seconds += 1
                let countdown = 60 - sself._seconds
                if countdown <= 0 {
                    self?.recordView.removeFromSuperview()
                    self?.stopRecord()
                }
            })
        }
    }
    
    private func stopRecord() {
        if _recorder.isRecording {
            _recorder.stop()
            _recordingTimer?.invalidate()
            _recordingTimer = nil
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
    
    private func cancelRecord() {
        stopRecord()
    }
}

extension ChatToolBar: ChatEmojiViewDelegate {
    func emojiViewDidSelect(emojiStr: String) {
        let attr: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
            NSAttributedString.Key.foregroundColor: StandardUI.color_333333
        ]
        let attrStr = NSAttributedString.init(string: emojiStr, attributes: attr)
        
        var cursorPosition: Int = 0
        if textInputView.selectedTextRange != nil {
            cursorPosition = textInputView.selectedRange.location
        }
        
        if(cursorPosition > self.textInputView.textStorage.length) {
            cursorPosition = self.textInputView.textStorage.length;
        }
        self.textInputView.textStorage.insert(attrStr, at: cursorPosition)
        
        let range = NSRange.init(location: self.textInputView.selectedRange.location + emojiStr.count, length: 1)
        self.textInputView.selectedRange = range;
        self.sendBtn.isHidden = false
    }
}

extension ChatToolBar: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            sendAndClearText()
            return false
        }
        
        var needUpdateText = false
        if conversation.conversationType == .group {
            if text == "@" {
                print("弹出选择群成员窗口")
            }
            
            if text.isEmpty {
                print("执行删除@联系人的逻辑")
            }
        }
        return true
    }
}

extension ChatToolBar: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag { return }
        if _seconds < 1 {
            
            return
        }
        let path = NSHomeDirectory() + "/Documents/audio.m4a"
        AudioFileConverter.convertAudioToM4a(inputUrlString: _recorder.url.path, outputUrlString: path) { [weak self] (error: Error?) in
            print("语音路径：\(NSHomeDirectory())")
            if let error = error {
                print("转换格式错误：\(error.localizedDescription)")
            } else {
                self?.delegate?.tb_didAudioRecordEnd(url: path, duration: _seconds)
            }
        }
        try? FileManager.default.removeItem(at: _recorder.url)
    }
}
