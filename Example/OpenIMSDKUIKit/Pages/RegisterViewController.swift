
import Foundation
import UIKit
import SVProgressHUD

class RegisterViewController: UIViewController {
    
    @IBOutlet var phoneTextField: UITextField!
    @IBOutlet var codeTextField: UITextField!
    @IBOutlet var pswTextField: UITextField!
    @IBOutlet var pswAgainTextField: UITextField!
    @IBOutlet var nextButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    @IBAction func didTapNext() {
        view.endEditing(true)
        
        guard let phone = phoneTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let code = codeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let password = pswTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !phone.isEmpty, !code.isEmpty, !password.isEmpty, phone.count == 11  else {
            SVProgressHUD.showError(withStatus: "参数还是需要填完...")
            
            return
        }
        
        performSegue(withIdentifier: "toCompleteUserInfo", sender: ["phone": phone, "code": code, "password": password])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc:CompleteUserInfoViewController = segue.destination as! CompleteUserInfoViewController
        vc.basicInfo = sender as? Dictionary<String, String>
    }
}
