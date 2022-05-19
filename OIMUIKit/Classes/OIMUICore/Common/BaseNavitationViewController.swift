//


//




import UIKit
import RxSwift

class BaseNavitationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.backgroundColor = .white
        self.navigationBar.shadowImage = UIImage()
    }
}
