
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
    // 如有版权问题，请联系删除
    let avatars = [
        "http://e.hiphotos.baidu.com/image/pic/item/a1ec08fa513d2697e542494057fbb2fb4316d81e.jpg",
        "http://c.hiphotos.baidu.com/image/pic/item/30adcbef76094b36de8a2fe5a1cc7cd98d109d99.jpg",
        "http://h.hiphotos.baidu.com/image/pic/item/7c1ed21b0ef41bd5f2c2a9e953da81cb39db3d1d.jpg",
        "http://g.hiphotos.baidu.com/image/pic/item/55e736d12f2eb938d5277fd5d0628535e5dd6f4a.jpg",
        "http://e.hiphotos.baidu.com/image/pic/item/4e4a20a4462309f7e41f5cfe760e0cf3d6cad6ee.jpg",
        "http://b.hiphotos.baidu.com/image/pic/item/9d82d158ccbf6c81b94575cfb93eb13533fa40a2.jpg",
        "http://e.hiphotos.baidu.com/image/pic/item/4bed2e738bd4b31c1badd5a685d6277f9e2ff81e.jpg",
        "http://g.hiphotos.baidu.com/image/pic/item/0d338744ebf81a4c87a3add4d52a6059252da61e.jpg",
        "http://a.hiphotos.baidu.com/image/pic/item/f2deb48f8c5494ee5080c8142ff5e0fe99257e19.jpg",
        "http://f.hiphotos.baidu.com/image/pic/item/4034970a304e251f503521f5a586c9177e3e53f9.jpg",
        "http://b.hiphotos.baidu.com/image/pic/item/279759ee3d6d55fbb3586c0168224f4a20a4dd7e.jpg",
        "http://a.hiphotos.baidu.com/image/pic/item/e824b899a9014c087eb617650e7b02087af4f464.jpg",
        "http://c.hiphotos.baidu.com/image/pic/item/9c16fdfaaf51f3de1e296fa390eef01f3b29795a.jpg",
        "http://d.hiphotos.baidu.com/image/pic/item/b58f8c5494eef01f119945cbe2fe9925bc317d2a.jpg",
        "http://h.hiphotos.baidu.com/image/pic/item/902397dda144ad340668b847d4a20cf430ad851e.jpg",
        "http://b.hiphotos.baidu.com/image/pic/item/359b033b5bb5c9ea5c0e3c23d139b6003bf3b374.jpg",
        "http://a.hiphotos.baidu.com/image/pic/item/8d5494eef01f3a292d2472199d25bc315d607c7c.jpg",
        "http://b.hiphotos.baidu.com/image/pic/item/e824b899a9014c08878b2c4c0e7b02087af4f4a3.jpg",
        "http://g.hiphotos.baidu.com/image/pic/item/6d81800a19d8bc3e770bd00d868ba61ea9d345f2.jpg",
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        avatarImageView.layer.cornerRadius = 50
        avatarImageView.layer.borderColor = UIColor.systemBlue.cgColor
        avatarImageView.layer.borderWidth = 2
        avatarImageView.contentMode = .scaleAspectFill
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(didTapAvatar))
        avatarImageView.addGestureRecognizer(tap)
        
        didTapAvatar()
    }
    
    func randAvatarURL() -> URL {
        avatarURL = avatars[Int(arc4random()) % 19]
        
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
