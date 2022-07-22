
import Foundation
import UIKit
import RxSwift
import SVProgressHUD

class CompleteUserInfoViewController: UIViewController {
    
    var basicInfo: Dictionary<String, String>?
    
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var nickNameTextField: UITextField!
    @IBOutlet var compeleteButton: UIButton!

    private var avatarURL: String = ""
    
    private let _disposeBag: DisposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        avatarImageView.layer.cornerRadius = 50
        avatarImageView.layer.borderColor = UIColor.systemBlue.cgColor
        avatarImageView.layer.borderWidth = 2
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(didTapAvatar))
        avatarImageView.addGestureRecognizer(tap)
        
        didTapAvatar()
    }
    
    func randAvatarURL() -> URL {
        avatarURL = String.init(format: "https://picsum.photos/id/%d/200/200", arc4random() % 999)
        
        return URL(string:avatarURL)!
    }
    
    @IBAction func didTapCompelete() {
        view.endEditing(true)
        
        guard let info = basicInfo,
              let nickName = nickNameTextField.text,
              !nickName.isEmpty else {
                
            SVProgressHUD.showError(withStatus: "填入昵称...")
            return
        }
        SVProgressHUD.show(withStatus: "注册中...")
        
        LoginViewModel.registerAccount(phone: info["phone"]!,
                                       code: info["code"]!,
                                       password: info["password"]!,
                                       faceURL: avatarURL,
                                       nickName: nickName) { errMsg in
            
            if errMsg != nil {
                SVProgressHUD.showError(withStatus: errMsg)
            } else {
                SVProgressHUD.dismiss()
                self.dismiss(animated: true)
            }
        }
    }
    
    @objc func didTapAvatar() {
        avatarImageView.isUserInteractionEnabled = false
        
        DispatchQueue.global().async {

            do {
                let data = try Data(contentsOf: self.randAvatarURL())
                let image = UIImage(data: data)
                
                DispatchQueue.main.async {
                    
                    if image != nil {
                        self.avatarImageView.image = image
                    }
                    self.avatarImageView.isUserInteractionEnabled = true
                }
                
            } catch let error {
                print(error)
            }
        }
    }
}
