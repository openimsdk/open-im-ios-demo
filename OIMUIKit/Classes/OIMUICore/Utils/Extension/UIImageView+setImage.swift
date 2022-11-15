
import Kingfisher
import UIKit

extension UIImageView {
    public func setImage(with string: String?, placeHolder: String?) {
        guard let string = string, !string.isEmpty, let url = URL(string: string) else {
            if let placeHolder = placeHolder {
                image = UIImage(named: placeHolder, in: ViewControllerFactory.getBundle(), compatibleWith: nil)
            } else {
                image = nil
            }
            return
        }
        let placeImage: UIImage?
        if let placeHolder = placeHolder {
            placeImage = UIImage(named: placeHolder, in: ViewControllerFactory.getBundle(), compatibleWith: nil)
        } else {
            placeImage = nil
        }
        kf.setImage(with: url, placeholder: placeImage)
    }

    func setImagePath(_ path: String, placeHolder _: String?) {
        if !FileManager.default.fileExists(atPath: path) {
            return
        }
        let url = URL(fileURLWithPath: path)
        image = UIImage(contentsOfFile: url.path)
    }
}

extension UIImage {
    public convenience init?(nameInBundle: String) {
        self.init(named: nameInBundle, in: ViewControllerFactory.getBundle(), compatibleWith: nil)
    }

    convenience init?(nameInEmoji: String) {
        self.init(named: nameInEmoji, in: ViewControllerFactory.getEmojiBundle(), compatibleWith: nil)
    }
}
