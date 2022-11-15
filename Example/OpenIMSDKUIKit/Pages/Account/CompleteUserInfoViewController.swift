
import Photos
import RxSwift
import SVProgressHUD
import UIKit
import OIMUIKit

class CompleteUserInfoViewController: UITableViewController {
    private var rowItems: [RowType: Any] = [.avatar : "", .nickname : "", .gender : Gender.female, .birthday : Int(NSDate().timeIntervalSince1970), .invitationCode : ""]
    
    private let _disposeBag = DisposeBag()
    public var basicInfo: [String: Any] = [:]
    
    private lazy var _photoHelper: PhotoHelper = {
        let v = PhotoHelper()
        v.setConfigToPickAvatar()
        v.didPhotoSelected = { [weak self] (images: [UIImage], _: [PHAsset], _: Bool) in
            guard var first = images.first else { return }
            SVProgressHUD.show()
            let result = FileHelper.shared.saveImage(image: first)
            
            if result.isSuccess {
                self?.rowItems[.avatar] = result.fullPath
                self?.tableView.reloadData()
            }
            
            SVProgressHUD.dismiss()
        }
        
        v.didCameraFinished = { [weak self] (photo: UIImage?, _: URL?) in
            guard let sself = self else { return }
            
            if let photo = photo {
                let result = FileHelper.shared.saveImage(image: photo)
                if result.isSuccess {
                    sself.rowItems[.avatar] = result.fullPath
                    self?.tableView.reloadData()
                }
                SVProgressHUD.dismiss()
            }
        }
        return v
    }()
    
    public lazy var completeBtn: UIButton = {
        let v = UIButton()
        v.backgroundColor = DemoUI.color_1B72EC
        v.layer.cornerRadius = 4
        v.setTitle("进入App".localized(), for: .normal)
        v.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "完善个人信息"
        configureTableView()
        bindData()
    }
    
    private func configureTableView() {
        tableView.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        tableView.register(OptionImageTableViewCell.self, forCellReuseIdentifier: OptionImageTableViewCell.className)
        tableView.rowHeight = 60
        
        let view = UIView.init(frame: .init(x: 0, y: 0, width: tableView.bounds.width, height: 60))
        
        view.addSubview(completeBtn)
        completeBtn.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(40)
            make.width.equalTo(200)
            make.centerX.equalToSuperview()
        }
        
        // 注册
        completeBtn.rx.tap.subscribe(onNext: { [weak self] in
            
            guard let sself = self else { return }
            
            SVProgressHUD.show()
            AccountViewModel.registerAccount(phone: sself.basicInfo["phone"] as! String,
                                             areaCode: sself.basicInfo["areaCode"] as! String,
                                             verificationCode: sself.basicInfo["verCode"] as! String,
                                             password: sself.basicInfo["password"] as! String,
                                             faceURL: "",
                                             nickName: sself.rowItems[.nickname] as! String,
                                             birth: sself.rowItems[.birthday] as! Int,
                                             gender: sself.rowItems[.gender] as! Gender == Gender.male ? 1 : 2) { (errCode, errMsg) in
                if errMsg != nil {
                    SVProgressHUD.showError(withStatus: String(errCode).localized())
                } else {
                    
                    AccountViewModel.loginIM(uid: AccountViewModel.baseUser.userID,
                                             imToken: AccountViewModel.baseUser.imToken,
                                             chatToken: AccountViewModel.baseUser.chatToken) { errCode, errMsg in
                        IMController.shared.uploadFile(fullPath: (sself.rowItems[.avatar] as! String)) { progress in
                            SVProgressHUD.showProgress(Float(progress))
                        } onSuccess: { res in
                            AccountViewModel.updateUserInfo(userID: AccountViewModel.userID!, faceURL: res) { errMsg in
                                SVProgressHUD.dismiss()
                                sself.dismiss(animated: true)
                            }
                        }
                    }
                }
            }
        }).disposed(by: _disposeBag)
        
        tableView.tableFooterView = view
    }
    
    private func bindData() {
        
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return rowItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.row {
            
        case RowType.avatar.rawValue:
            let rowType = RowType.avatar
            let value = rowItems[rowType]
            
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionImageTableViewCell.className, for: indexPath) as! OptionImageTableViewCell
            cell.titleLabel.text = rowType.title
            cell.iconImageView.setImage(with: (value as? String) ?? "", placeHolder: "contact_my_friend_icon")
            if let path = value as? String, !path.isEmpty {
                let url = URL.init(fileURLWithPath: path)
                let data = try! Data.init(contentsOf: url)
                cell.iconImageView.image = .init(data: data)
            }
            cell.iconImageView.layer.cornerRadius = 4
            return cell
            
        case RowType.nickname.rawValue:
            let rowType = RowType.nickname
            let value = rowItems[rowType]
            
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className, for: indexPath) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            cell.subtitleLabel.text = value as? String
            return cell
        case RowType.gender.rawValue:
            
            let rowType = RowType.gender
            let value = rowItems[rowType]
            
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className, for: indexPath) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            cell.subtitleLabel.text = value as? Gender == Gender.female ? "女" :"男";
            return cell
        case  RowType.birthday.rawValue:
            let rowType = RowType.birthday
            let value = rowItems[rowType]
            
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className, for: indexPath) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            cell.subtitleLabel.text = FormatUtil.getFormatDate(of: (value as? Int) ?? 0)
            return cell
            
        case  RowType.invitationCode.rawValue:
            let rowType = RowType.invitationCode
            let value = rowItems[rowType]
            
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className, for: indexPath) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            cell.subtitleLabel.text = value as? String
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case RowType.avatar.rawValue:
            
            
            let alertController = UIAlertController(title: "选择照片", message: "", preferredStyle: .actionSheet)
            
            let photoAction = UIAlertAction(title: "从相册选取", style: .default, handler: { [weak self] (alert) -> Void in
                guard let sself = self else {
                    return
                }
                sself._photoHelper.presentPhotoLibrary(byController: sself)
            })
            
            let cameraAction = UIAlertAction(title: "照相", style: .default, handler: { [weak self] (alert) -> Void in
                
                guard let sself = self else {
                    return
                }
                sself._photoHelper.presentCamera(byController: sself)
            })
            
            let cancelAction = UIAlertAction(title: "取消", style: .default, handler: nil )
            
            alertController.addAction(photoAction)
            alertController.addAction(cameraAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        case RowType.nickname.rawValue:
            let rowType = RowType.nickname
            let value = rowItems[rowType]
            
            let user = value as? String ?? "请输入昵称"
            let alertController = UIAlertController(title: "请输入昵称", message: "", preferredStyle: .alert)
            
            alertController.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = user
            }
            
            let saveAction = UIAlertAction(title: "保存", style: .default, handler: { [weak self] (alert) -> Void in
                let firstTextField = alertController.textFields![0] as UITextField
                self?.rowItems[rowType] = firstTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                self?.tableView.reloadData()
            })
            
            let cancelAction = UIAlertAction(title: "取消", style: .default, handler: nil )
            
            alertController.addAction(cancelAction)
            alertController.addAction(saveAction)
            
            self.present(alertController, animated: true, completion: nil)
        case RowType.gender.rawValue:
            let rowType = RowType.gender
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let maleAction: UIAlertAction = {
                let v = UIAlertAction(title: "男", style: .default) { [weak self] _ in
                    self?.rowItems[rowType] = Gender.male
                    self?.tableView.reloadData()
                }
                return v
            }()
            
            let femaleAction: UIAlertAction = {
                let v = UIAlertAction(title: "女", style: .default) { [weak self] _ in
                    self?.rowItems[rowType] = Gender.female
                    self?.tableView.reloadData()
                }
                return v
            }()
            let cancelAction = UIAlertAction(title: "取消", style: UIAlertAction.Style.cancel, handler: nil)
            sheet.addAction(maleAction)
            sheet.addAction(femaleAction)
            sheet.addAction(cancelAction)
            present(sheet, animated: true, completion: nil)
        case RowType.birthday.rawValue:
            let rowType = RowType.birthday
            JNDatePickerView.show(onWindowOfView: view) { (pickerView: JNDatePickerView) in
                pickerView.datePicker.maximumDate = Date()
                pickerView.datePicker.minimumDate = Date(timeIntervalSince1970: 0)
            } confirmAction: { [weak self] (selectedDate: Date) in
                let timeStamp = selectedDate.timeIntervalSince1970
                self?.rowItems[rowType] = Int(timeStamp)
                
                self?.tableView.reloadData()
            }
        case RowType.invitationCode.rawValue:
            
            let rowType = RowType.invitationCode
            let value = rowItems[rowType]
            
            let invitationCode = value as? String ?? "请填写邀请码"
            let alertController = UIAlertController(title: nil, message: "请填写邀请码", preferredStyle: .alert)
            
            alertController.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = invitationCode
            }
            
            let saveAction = UIAlertAction(title: "保存", style: .default, handler: { [weak self] (alert) -> Void in
                let firstTextField = alertController.textFields![0] as UITextField
                self?.rowItems[rowType] = firstTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                self?.tableView.reloadData()
            })
            
            let cancelAction = UIAlertAction(title: "取消", style: .default, handler: nil )
            
            alertController.addAction(cancelAction)
            alertController.addAction(saveAction)
            
            self.present(alertController, animated: true, completion: nil)
        default:
            break
        }
    }
    
    deinit {
#if DEBUG
        print("dealloc \(type(of: self))")
#endif
    }
    
    enum RowType: Int, CaseIterable {
        case avatar = 0
        case nickname = 1
        case gender = 2
        case birthday = 3
        case invitationCode = 4
        
        var title: String {
            switch self {
            case .avatar:
                return "头像"
            case .nickname:
                return "昵称"
            case .gender:
                return "性别"
            case .invitationCode:
                return "邀请码"
            case .birthday:
                return "生日"
            }
        }
    }
}
