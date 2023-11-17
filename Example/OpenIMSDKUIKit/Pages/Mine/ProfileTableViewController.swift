
import Photos
import RxSwift
import ProgressHUD
import UIKit
import OUICore
import OUIIM

class ProfileTableViewController: OUIIM.ProfileTableViewController {
    private var rowItems: [RowType] = RowType.allCases

    private let _viewModel = MineViewModel()
    private let _disposeBag = DisposeBag()

    private lazy var _photoHelper: PhotoHelper = {
        let v = PhotoHelper()
        v.setConfigToPickAvatar()
        v.didPhotoSelected = { [weak self] (images: [UIImage], _: [PHAsset], _: Bool) in
            guard var first = images.first else { return }
            ProgressHUD.animate()
            first = first.compress(to: 42)
            let result = FileHelper.shared.saveImage(image: first)
                        
            if result.isSuccess {
                self?._viewModel.uploadFile(fullPath: result.fullPath, onProgress: { [weak self] progress in
                    ProgressHUD.progress(progress)
                }, onComplete: {
                    ProgressHUD.success("头像上传成功".innerLocalized())
                    self?.getUserOrMemberInfo()
                })
            } else {
                ProgressHUD.dismiss()
            }
        }

        v.didCameraFinished = { [weak self] (photo: UIImage?, _: URL?) in
            guard let sself = self else { return }
            if let photo = photo {
                let result = FileHelper.shared.saveImage(image: photo)
                if result.isSuccess {
                    self?._viewModel.uploadFile(fullPath: result.fullPath, onProgress: { [weak self] progress in
                        ProgressHUD.progress(progress)
                    }, onComplete: {
                        ProgressHUD.success("头像上传成功".innerLocalized())
                        self?.getUserOrMemberInfo()
                    })
                }
            }
        }
        return v
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getUserOrMemberInfo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "我的信息".innerLocalized()
    }
    
    private func callPhoneTel(phone : String){
        let  phoneUrlStr = "tel://" + phone
        if let url = URL(string: phoneUrlStr), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType: RowType = rowItems[indexPath.row]
        
        switch rowType {
        case .avatar:
            presentActionSheet(action1Title: "从相册中选取".innerLocalized(), action1Handler: { [weak self] in
                guard let self else { return }
                _photoHelper.presentPhotoLibrary(byController: self)
            }, action2Title: "照相".innerLocalized()) { [weak self] in
                guard let self else { return }
                _photoHelper.presentCamera(byController: self)
            }
            
        case .nickname:
            let vc = ModifyNicknameViewController()
            vc.titleLabel.text = "修改昵称".innerLocalized()
            vc.subtitleLabel.text = nil
            vc.avatarView.setAvatar(url: user?.faceURL, text: user?.nickname)
            vc.nameTextField.text = user?.nickname
            vc.completeBtn.rx.tap.subscribe(onNext: { [weak self, weak vc] in
                guard let text = vc?.nameTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                      !text.isEmpty else { return }
                self?._viewModel.updateNickname(text) {
                    vc?.navigationController?.popViewController(animated: true)
                }
            }).disposed(by: vc.disposeBag)
            navigationController?.pushViewController(vc, animated: true)
        case .gender:
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let maleAction: UIAlertAction = {
                let v = UIAlertAction(title: "男".innerLocalized(), style: .default) { [weak self] _ in
                    self?._viewModel.updateGender(.male) { [weak self] in
                        self?.getUserOrMemberInfo()
                    }
                }
                return v
            }()

            let femaleAction: UIAlertAction = {
                let v = UIAlertAction(title: "女".innerLocalized(), style: .default) { [weak self] _ in
                    self?._viewModel.updateGender(.female) { [weak self] in
                        self?.getUserOrMemberInfo()
                    }
                }
                return v
            }()
            let cancelAction = UIAlertAction(title: "取消".innerLocalized(), style: UIAlertAction.Style.cancel, handler: nil)
            sheet.addAction(maleAction)
            sheet.addAction(femaleAction)
            sheet.addAction(cancelAction)
            present(sheet, animated: true, completion: nil)
            
        case .birthday:
            JNDatePickerView.show(onWindowOfView: view) { (pickerView: JNDatePickerView) in
                pickerView.datePicker.maximumDate = Date()
                pickerView.datePicker.minimumDate = Date(timeIntervalSince1970: 0)
            } confirmAction: { [weak self] (selectedDate: Date) in
                let timeStamp = selectedDate.timeIntervalSince1970
                self?._viewModel.updateBirthday(timeStampSeconds: Int(timeStamp)) { [weak self] in
                    self?.getUserOrMemberInfo()
                }
            }
        case .phone:
            callPhoneTel(phone: user?.phoneNumber ?? "")
            break
        case .qrcode:
            guard let user = _viewModel.currentUserRelay.value else { return }
            let vc = QRCodeViewController(idString: IMController.addFriendPrefix.append(string: user.userID))
            vc.nameLabel.text = user.nickname
            vc.avatarView.setAvatar(url: user.faceURL, text: user.nickname)
            vc.tipLabel.text = "扫一扫下面的二维码，添加我为好友"
            navigationController?.pushViewController(vc, animated: true)
        case .identifier:
            UIPasteboard.general.string = _viewModel.currentUserRelay.value?.userID
            ProgressHUD.success("ID复制成功")
        case .email:
            if let email = user?.email, !email.isEmpty {
                UIPasteboard.general.string = email
                ProgressHUD.success("邮箱复制成功")
            }
            break
        }
    }

    deinit {
        #if DEBUG
            print("dealloc \(type(of: self))")
        #endif
    }

    enum RowType: CaseIterable {
        case avatar
        case nickname
        case gender
        case birthday
        case phone
        case email
        case qrcode
        case identifier

        var title: String {
            switch self {
            case .avatar:
                return "头像".innerLocalized()
            case .nickname:
                return "昵称".innerLocalized()
            case .gender:
                return "性别".innerLocalized()
            case .phone:
                return "手机号码".innerLocalized()
            case .email:
                return "邮箱".innerLocalized()
            case .qrcode:
                return "二维码名片".innerLocalized()
            case .identifier:
                return "ID号".innerLocalized()
            case .birthday:
                return "生日".innerLocalized()
            }
        }
    }
}
