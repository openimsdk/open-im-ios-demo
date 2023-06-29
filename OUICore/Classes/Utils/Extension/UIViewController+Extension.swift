
extension UIViewController {
    public func presentAlert(title: String? = nil, confirmHandler: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "确定".innerLocalized(), style: .default, handler: { _ in
            confirmHandler?()
        }))
        
        alertController.addAction(UIAlertAction(title: "取消".innerLocalized(), style: .cancel))
        
        present(alertController, animated: true)
    }
    
    public func presentActionSheet(title: String? = nil,
                            action1Title: String,
                            action1Handler: (() -> Void)?,
                            action2Title: String? = nil,
                            action2Handler: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        
        let action1 = UIAlertAction(title: action1Title, style: .default, handler: { _ in
            action1Handler?()
        })
        
        alertController.addAction(action1)
        
        if let action2Title {
            let action2 = UIAlertAction(title: action2Title, style: .default, handler: { _ in
                action2Handler?()
            })
            
            alertController.addAction(action2)
        }
        
        let cancelAction = UIAlertAction(title: "取消".innerLocalized(), style: .default, handler: nil)
        
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
}
