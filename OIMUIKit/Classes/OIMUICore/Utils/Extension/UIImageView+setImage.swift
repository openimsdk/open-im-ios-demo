







import UIKit
import Kingfisher

extension UIImageView {
    func setImage(with string: String?, placeHolder: String?) {
        guard let string = string, !string.isEmpty, let url = URL.init(string: string) else {
            if let placeHolder = placeHolder {
                self.image = UIImage.init(named: placeHolder, in: ViewControllerFactory.getBundle(), compatibleWith: nil)
            } else {
                self.image = nil
            }
            return
        }
        let placeImage: UIImage?
        if let placeHolder = placeHolder {
            placeImage = UIImage.init(named: placeHolder, in: ViewControllerFactory.getBundle(), compatibleWith: nil)
        } else {
            placeImage = nil
        }
        self.kf.setImage(with: url, placeholder: placeImage)
    }
    
    func setImagePath(_ path: String, placeHolder: String?) {
        if !FileManager.default.fileExists(atPath: path) {
            return
        }
        let url = URL.init(fileURLWithPath: path)
        self.image = UIImage.init(contentsOfFile: url.path)
    }
}

extension UIImage {
    convenience init?(nameInBundle: String) {
        self.init(named: nameInBundle, in: ViewControllerFactory.getBundle(), compatibleWith: nil)
    }
    
    convenience init?(nameInEmoji: String) {
        self.init(named: nameInEmoji, in: ViewControllerFactory.getEmojiBundle(), compatibleWith: nil)
    }
}
