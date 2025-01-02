






import Foundation
import UIKit

internal protocol EmojiPopViewDelegate: AnyObject {

    func emojiPopViewShouldDismiss(emojiPopView: EmojiPopView)
    
}

internal class EmojiPopView: UIView {


    internal weak var delegate: EmojiPopViewDelegate?
    
    internal var currentEmoji: String = ""
    internal var emojiArray: [String] = []

    
    private var locationX: CGFloat = 0.0
    
    private var emojiButtons: [UIButton] = []
    private var emojisView: UIView = UIView()
    
    private var emojisX: CGFloat = 0.0
    private var emojisWidth: CGFloat = 0.0

    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: EmojiPopViewSize.width, height: EmojiPopViewSize.height))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let result = point.x >= emojisX && point.x <= emojisX + emojisWidth && point.y >= 0 && point.y <= TopPartSize.height
        
        if !result {
            dismiss()
        }
        
        return result
    }

    
    internal func move(location: CGPoint, animation: Bool = true) {
        locationX = location.x
        setupUI()
        
        UIView.animate(withDuration: animation ? 0.08 : 0, animations: {
            self.alpha = 1
            self.frame = CGRect(x: location.x, y: location.y, width: self.frame.width, height: self.frame.height)
        }, completion: { complate in
            self.isHidden = false
        })
    }
    
    internal func dismiss() {
        UIView.animate(withDuration: 0.08, animations: {
            self.alpha = 0
        }, completion: { complate in
            self.isHidden = true
        })
    }
    
    internal func setEmoji(_ emoji: Emoji) {
        self.currentEmoji = emoji.emoji
        self.emojiArray = emoji.emojis
    }
    
}


extension EmojiPopView {
    
    private func createEmojiButton(_ emoji: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = EmojiFont
        button.setTitle(emoji, for: .normal)
        button.frame = CGRect(x: CGFloat(emojiButtons.count) * EmojiSize.width, y: 0, width: EmojiSize.width, height: EmojiSize.height)
        button.addTarget(self, action: #selector(selectEmojiType(_:)), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }
    
    @objc private func selectEmojiType(_ sender: UIButton) {
        if let selectedEmoji = sender.titleLabel?.text {
            currentEmoji = selectedEmoji
            delegate?.emojiPopViewShouldDismiss(emojiPopView: self)
        }
    }
    
    private func setupUI() {
        isHidden = true
        
        self.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        emojisWidth = TopPartSize.width + EmojiSize.width * CGFloat(emojiArray.count - 1)
        emojisX = 0.0 // the x adjustment within the popView to account for the shift in location
        let screenWidth = UIScreen.main.bounds.width
        if emojisWidth + locationX > screenWidth {
            emojisX = -CGFloat(emojisWidth + locationX - screenWidth + 8) // 8 for padding to border
        }

        let halfWidth = TopPartSize.width / 2.0 - BottomPartSize.width / 2.0
        if emojisX + emojisWidth < halfWidth + BottomPartSize.width {
            emojisX += (halfWidth + BottomPartSize.width) - (emojisX + emojisWidth)
        }

        let path = maskPath()

        let borderLayer = CAShapeLayer()
        borderLayer.path = path
        borderLayer.strokeColor = UIColor(white: 0.8, alpha: 1).cgColor
        borderLayer.fillColor = UIColor.white.cgColor
        borderLayer.lineWidth = 1
        layer.addSublayer(borderLayer)

        let maskLayer = CAShapeLayer()
        maskLayer.path = path

        let contentLayer = CALayer()
        contentLayer.frame = bounds
        contentLayer.backgroundColor = UIColor.white.cgColor
        contentLayer.mask = maskLayer
        layer.addSublayer(contentLayer)
        
        emojisView.removeFromSuperview()
        emojisView = UIView(frame: CGRect(x: emojisX + 8, y: 10, width: CGFloat(emojiArray.count) * EmojiSize.width, height: EmojiSize.height))

        emojiButtons = []
        for emoji in emojiArray {
            let button = createEmojiButton(emoji)
            emojiButtons.append(button)
            emojisView.addSubview(button)
        }
        
        addSubview(emojisView)
    }
    
    func maskPath() -> CGMutablePath {
        let path = CGMutablePath()
        
        path.addRoundedRect(
                 in: CGRect(
                     x: emojisX,
                     y: 0.0,
                     width: emojisWidth,
                     height: TopPartSize.height
                 ),
                 cornerWidth: 10,
                 cornerHeight: 10
             )

        path.addRoundedRect(
            in: CGRect(
                x: TopPartSize.width / 2.0 - BottomPartSize.width / 2.0,
                y: TopPartSize.height - 10,
                width: BottomPartSize.width,
                height: BottomPartSize.height + 10
            ),
            cornerWidth: 5,
            cornerHeight: 5
        )
        
        return path
    }
}
