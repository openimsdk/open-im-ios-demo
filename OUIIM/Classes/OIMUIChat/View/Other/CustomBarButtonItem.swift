
import UIKit

fileprivate var actionKey: Void?

extension UIBarButtonItem {
    
    var action: (() -> Void)? {
        get {
            return objc_getAssociatedObject(self, &actionKey) as? () -> Void
        }
        set {
            objc_setAssociatedObject(self, &actionKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    convenience init(title: String?, image: UIImage? = nil, action: @escaping () -> Void) {
        
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setImage(image ?? UIImage(systemName: "chevron.left"), for: .normal)
        
        self.init(customView: button)
        
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.action = action
    }
    
    @objc
    private func buttonAction() {
        self.action?()
    }
}
