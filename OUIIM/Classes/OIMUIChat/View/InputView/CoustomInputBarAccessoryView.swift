
import InputBarAccessoryView
import UIKit
import OUICore
import Photos
import MobileCoreServices

enum CustomAttachment {
    case image(String, String)
    case video(String, String, String, Int)
}

// MARK: - CameraInputBarAccessoryViewDelegate
protocol CoustomInputBarAccessoryViewDelegate: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith attachments: [CustomAttachment])
    func inputBar(_ inputBar: InputBarAccessoryView, didPressPadItemWith type: PadItemType)
}

extension CoustomInputBarAccessoryViewDelegate {
    func inputBar(_: InputBarAccessoryView, didPressSendButtonWith _: [CustomAttachment]) { }
    func inputBar(_: InputBarAccessoryView, didPressPadItemWith _: PadItemType) {}
}

// MARK: - CameraInputBarAccessoryView
let buttonSize = 35.0

class CoustomInputBarAccessoryView: InputBarAccessoryView {
        
    private lazy var _photoHelper: PhotoHelper = {
        let v = PhotoHelper()
        v.didPhotoSelected = { [weak self, weak v] (images: [UIImage], assets: [PHAsset], _: Bool) in
            guard let self else { return }
            sendButton.startAnimating()
            
            for (index, asset) in assets.enumerated() {
                switch asset.mediaType {
                case .video:
                    PhotoHelper.compressVideoToMp4(asset: asset, thumbnail: images[index]) { main, thumb, duration in
                        self.sendAttachments(attachments: [.video(thumb.relativeFilePath,
                                                                  thumb.fullPath,
                                                                  main.relativeFilePath,
                                                                  duration)])
                    }
                case .image:
                    let r = FileHelper.shared.saveImage(image: images[index])
                    self.sendAttachments(attachments: [.image(r.relativeFilePath,
                                                              r.fullPath)])
                default:
                    break
                }
            }
        }

        v.didCameraFinished = { [weak self] (photo: UIImage?, videoPath: URL?) in
            guard let self else { return }
            sendButton.startAnimating()
            
            if let photo {
                let r = FileHelper.shared.saveImage(image: photo)
                self.sendAttachments(attachments: [.image(r.relativeFilePath,
                                                          r.fullPath)])
            }

            if let videoPath {
                PhotoHelper.getVideoAt(url: videoPath) { main, thumb, duration in
                    self.sendAttachments(attachments: [.video(thumb.relativeFilePath,
                                                              thumb.fullPath,
                                                              main.relativeFilePath,
                                                              duration)])
                }
            }
        }
        return v
    }()
        
    lazy var moreButton: InputBarButtonItem = {
        let v = InputBarButtonItem()
            .configure {
                $0.spacing = .fixed(8)
                $0.image = UIImage(nameInBundle: "inputbar_more_normal_icon")
                $0.setImage(UIImage(nameInBundle: "inputbar_keyboard_btn_icon"), for: .selected)
                $0.setImage(UIImage(nameInBundle: "inputbar_more_disable_icon"), for: .disabled)
                $0.setSize(CGSize(width: buttonSize, height: buttonSize), animated: false)
            }.onTouchUpInside { [weak self] item in
                print("Item Tapped:\(item.isSelected)")
                guard let self else { return }
                item.isSelected = !item.isSelected
                self.showPadView(item.isSelected)
            }
        
        return v
    }()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews()
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    lazy var attachmentManager: AttachmentManager = { [unowned self] in
        let manager = AttachmentManager()
        manager.delegate = self
        
        return manager
    }()
    
    private func setupSubViews() {
        backgroundView.backgroundColor = .secondarySystemBackground
        inputTextView.backgroundColor = .systemBackground
        inputTextView.textColor = .c0C1C33
        inputTextView.font = .preferredFont(forTextStyle: .body)
        leftStackView.alignment = .center
        rightStackView.alignment = .center
        configRightButton()
        
        inputPlugins.append(attachmentManager)
    }
    
        
    private func configRightButton() {
        sendButton.configure {
            $0.title = nil
            $0.image = UIImage(nameInBundle: "inputbar_pad_send_normal_icon")
            $0.setImage(UIImage(nameInBundle: "inputbar_pad_send_disable_icon"), for: .disabled)
        }
        setRightStackViewWidthConstant(to: 2 * (buttonSize + 10), animated: false)
        setStackViewItems([moreButton, sendButton], forStack: .right, animated: false)
    }
    
        
    private func configBottomButtons(_ show: Bool) {
        if show {
            let pad = InputPadView()
            pad.delegate = self
            setStackViewItems([pad], forStack: .bottom, animated: false)
        } else {
            setStackViewItems([], forStack: .bottom, animated: false)
        }
    }
        
    private func showPadView(_ show: Bool) {
        print("点击按钮：\(show)")
        
        if show {
            inputTextView.resignFirstResponder()
        } else {
            inputTextView.becomeFirstResponder()
            moreButton.isSelected = false
        }
        configBottomButtons(show)
    }
    
        
    private func sendAttachments(attachments: [CustomAttachment]) {
        DispatchQueue.main.async { [self] in
            if attachments.count > 0 {
                (self.delegate as? CoustomInputBarAccessoryViewDelegate)?
                    .inputBar(self, didPressSendButtonWith: attachments)
            }
        }
    }
    
    private func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
        if case .camera = sourceType {
            _photoHelper.presentCamera(byController: currentViewController())
        } else {
            _photoHelper.presentPhotoLibrary(byController: currentViewController())
        }
    }
    
    private func currentViewController() -> UIViewController {
        var rootViewController: UIViewController?
        for window in UIApplication.shared.windows {
            if window.rootViewController != nil {
                rootViewController = window.rootViewController
                break
            }
        }
        var viewController = rootViewController
        if viewController?.presentedViewController != nil {
            viewController = viewController!.presentedViewController
        }
        return viewController!
    }
    
    
        
    override func inputTextViewDidBeginEditing() {
        moreButton.isSelected = false
        configBottomButtons(false)
    }
}

// MARK: AttachmentManagerDelegate

extension CoustomInputBarAccessoryView: AttachmentManagerDelegate {
    func attachmentManager(_ manager: AttachmentManager, shouldBecomeVisible: Bool) {
        
    }
}

// MARK: UIAdaptivePresentationControllerDelegate

extension CoustomInputBarAccessoryView: UIAdaptivePresentationControllerDelegate {
    // Swipe to dismiss image modal
    public func presentationControllerWillDismiss(_: UIPresentationController) {
        isHidden = false
    }
}

extension CoustomInputBarAccessoryView: InputPadViewDelegate {
    func didSelect(type: PadItemType) {
        print("chat plugin did select: \(type)")
        (self.delegate as? CoustomInputBarAccessoryViewDelegate)?
            .inputBar(self, didPressPadItemWith: type)
        switch type {
        case .album:
            showImagePickerController(sourceType: .photoLibrary)
        case .camera:
            showImagePickerController(sourceType: .camera)
        default:
            break
        }
    }
}
