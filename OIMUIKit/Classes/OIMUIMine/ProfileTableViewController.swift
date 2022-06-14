





import UIKit
import SVProgressHUD
import RxSwift
import Photos

class ProfileTableViewController: UITableViewController {
    
    private let rowItems: [RowType] = RowType.allCases
    
    private let _viewModel = MineViewModel()
    private let _disposeBag = DisposeBag()
    
    private lazy var _photoHelper: PhotoHelper = {
        let v = PhotoHelper()
        v.setConfigToPickAvatar()
        v.didPhotoSelected = { [weak self] (images: [UIImage], assets: [PHAsset], isOriginPhoto: Bool) in
            guard let first = images.first else { return }
            let result = FileHelper.shared.saveImage(image: first)
            if result.isSuccess {
                self?._viewModel.uploadFile(fullPath: result.fullPath, onProgress: { (progress: Int) in
                    SVProgressHUD.showProgress(Float(progress))
                }, onComplete: {
                    SVProgressHUD.showSuccess(withStatus: "头像上传成功".innerLocalized())
                })
            }
        }
        
        v.didCameraFinished = { [weak self] (photo: UIImage?, videoPath: URL?) in
            guard let sself = self else { return }
            if let photo = photo {
                let result = FileHelper.shared.saveImage(image: photo)
                if result.isSuccess {
                    self?._viewModel.uploadFile(fullPath: result.fullPath, onProgress: { (progress: Int) in
                        SVProgressHUD.showProgress(Float(progress))
                    }, onComplete: {
                        SVProgressHUD.showSuccess(withStatus: "头像上传成功".innerLocalized())
                    })
                }
            }
        }
        return v
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "我的信息".innerLocalized()
        configureTableView()
        bindData()
    }
    
    private func configureTableView() {
        tableView.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        tableView.register(OptionImageTableViewCell.self, forCellReuseIdentifier: OptionImageTableViewCell.className)
        tableView.rowHeight = 60
    }
    
    private func bindData() {
        _viewModel.currentUserRelay.subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: _disposeBag)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType: RowType = rowItems[indexPath.row]
        let user = _viewModel.currentUserRelay.value
        switch rowType {
        case .avatar:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionImageTableViewCell.className) as! OptionImageTableViewCell
            cell.titleLabel.text = rowType.title
            cell.iconImageView.setImage(with: user?.faceURL, placeHolder: "contact_my_friend_icon")
            cell.iconImageView.layer.cornerRadius = 4
            return cell
        case .qrcode:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionImageTableViewCell.className) as! OptionImageTableViewCell
            cell.iconImageView.image = UIImage.init(nameInBundle: "common_qrcode_icon")
            cell.titleLabel.text = rowType.title
            return cell
        case .nickname:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            cell.subtitleLabel.text = user?.nickname
            return cell
        case .gender:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            cell.subtitleLabel.text = user?.gender?.description
            return cell
        case .birthday:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            cell.subtitleLabel.text = FormatUtil.getFormatDate(of: user?.birth ?? 0)
            return cell
        case .phone:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            cell.subtitleLabel.text = user?.phoneNumber
            cell.accessoryType = .none
            return cell
        case .identifier:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            cell.subtitleLabel.text = user?.userID
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType: RowType = rowItems[indexPath.row]
        switch rowType {
        case .avatar:
            _photoHelper.presentPhotoLibrary(byController: self)
        case .nickname:
            let user = _viewModel.currentUserRelay.value
            let vc = ModifyNicknameViewController.init()
            vc.titleLabel.text = "修改昵称".innerLocalized()
            vc.subtitleLabel.text = nil
            vc.avatarImageView.setImage(with: user?.faceURL, placeHolder: "contact_my_friend_icon")
            vc.nameTextField.text = user?.nickname
            vc.completeBtn.rx.tap.subscribe(onNext: { [weak self, weak vc] in
                guard let text = vc?.nameTextField.text, text.isEmpty == false else { return }
                self?._viewModel.updateNickname(text)
                vc?.navigationController?.popViewController(animated: true)
            }).disposed(by: vc.disposeBag)
            self.navigationController?.pushViewController(vc, animated: true)
        case .gender:
            let sheet = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
            let maleAction: UIAlertAction = {
                let v = UIAlertAction.init(title: "男".innerLocalized(), style: .default) { [weak self] _ in
                    self?._viewModel.updateGender(.male)
                }
                return v
            }()
            
            let femaleAction: UIAlertAction = {
                let v = UIAlertAction.init(title: "女".innerLocalized(), style: .default) { [weak self] _ in
                    self?._viewModel.updateGender(.female)
                }
                return v
            }()
            let cancelAction = UIAlertAction.init(title: "取消".innerLocalized(), style: UIAlertAction.Style.cancel, handler: nil)
            sheet.addAction(maleAction)
            sheet.addAction(femaleAction)
            sheet.addAction(cancelAction)
            self.present(sheet, animated: true, completion: nil)
        case .birthday:
            JNDatePickerView.show(onWindowOfView: self.view) { (pickerView: JNDatePickerView) in
                pickerView.datePicker.maximumDate = Date()
                pickerView.datePicker.minimumDate = Date.init(timeIntervalSince1970: 0)
            } confirmAction: { [weak self] (selectedDate: Date) in
                let timeStamp = selectedDate.timeIntervalSince1970
                self?._viewModel.updateBirthday(timeStampSeconds: Int(timeStamp))
            }
        case .phone:
            break
        case .qrcode:
            guard let user = _viewModel.currentUserRelay.value else { return }
            let vc = QRCodeViewController.init(idString: IMController.addFriendPrefix.append(string: user.userID))
            vc.nameLabel.text = user.nickname
            vc.avatarImageView.setImage(with: user.faceURL, placeHolder: "contact_my_friend_icon")
            vc.tipLabel.text = "扫一扫下面的二维码，添加我为好友"
            self.navigationController?.pushViewController(vc, animated: true)
        case .identifier:
            UIPasteboard.general.string = _viewModel.currentUserRelay.value?.userID
            SVProgressHUD.showSuccess(withStatus: "ID复制成功")
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
