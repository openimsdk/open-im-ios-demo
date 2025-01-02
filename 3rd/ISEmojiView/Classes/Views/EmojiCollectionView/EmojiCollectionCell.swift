






import Foundation
import UIKit

internal class EmojiCollectionCell: UICollectionViewCell {

    
    private lazy var emojiLabel: UILabel = {
        let label = UILabel()
        label.font = EmojiFont
        label.textAlignment = .center
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return label
    }()

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    
    internal func setEmoji(_ emoji: String) {
        emojiLabel.text = emoji
    }

    
    private func setupView() {
        emojiLabel.frame = bounds
        addSubview(emojiLabel)
    }
    
}
