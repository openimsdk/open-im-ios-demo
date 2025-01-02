






import Foundation
import UIKit
import Kingfisher

internal protocol FaceCollectionViewDelegate: AnyObject {






    func faceViewDidSelectEmoji(faceView: FaceCollectionView, emoji: FaceEmoji)
    
    func faceViewDidSelectAdd(faceView: FaceCollectionView)

}

internal class FaceCollectionView: UIView {


    internal weak var delegate: FaceCollectionViewDelegate?

    internal var isShowPopPreview = false
    
    var emojis: [EmojiCategory]! {
        didSet {
            collectionView.reloadData()
        }
    }

    
    private var scrollViewWillBeginDragging = false
    private var scrollViewWillBeginDecelerating = false
    private let faceCellReuseIdentifier = "FaceCell"
    private let addButtonIdentifer = "addIdentifer"
    
    private lazy var emojiPopView: EmojiPopView = {
        let emojiPopView = EmojiPopView()
        emojiPopView.delegate = self
        emojiPopView.isHidden = true
        return emojiPopView
    }()

    
    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(FaceCollectionCell.self, forCellWithReuseIdentifier: faceCellReuseIdentifier)
        }
    }

    
    internal override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: frame.size.height)
    }

    
    public func popPreviewShowing() -> Bool {
        return !self.emojiPopView.isHidden;
    }

    
    static func loadFromNib(emojis: [EmojiCategory]) -> FaceCollectionView {
        let nibName = String(describing: FaceCollectionView.self)
    
        guard let nib = Bundle.podBundle.loadNibNamed(nibName, owner: nil, options: nil) as? [FaceCollectionView] else {
            fatalError()
        }
        
        guard let view = nib.first else {
            fatalError()
        }
        
        view.emojis = emojis
        view.setupView()
        
        return view
    }

    
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard point.y < 0 else {
            return super.point(inside: point, with: event)
        }
        
        return point.y >= -TopPartSize.height
    }

    
    internal func updateRecentsEmojis(_ emojis: [EmojiCategory]) {
        self.emojis = emojis
        collectionView.reloadSections(IndexSet(integer: 0))
    }
    
}


extension FaceCollectionView: UICollectionViewDataSource {
    
    internal func numberOfSections(in collectionView: UICollectionView) -> Int {
        return emojis.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojis[section].faceEmoji.count + 1
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let emojiCategory = emojis[indexPath.section]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: faceCellReuseIdentifier, for: indexPath) as! FaceCollectionCell
        
        if indexPath.item == 0 {
            cell.imageView.image = UIImage(named: "ic_add_face", in: Bundle.podBundle,compatibleWith: nil)
        } else {
            let emoji = emojiCategory.faceEmoji[indexPath.item - 1]
            
            if let path = emoji.localImagePath, FaceManager.faceExists(path: path) {
                cell.imageView.image = UIImage(contentsOfFile: path)
            } else {
                cell.imageView.kf.setImage(with: emoji.imageURL)
            }
        }
        return cell
    }

    
}


extension FaceCollectionView: UICollectionViewDelegate {
    
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard emojiPopView.isHidden else {
            dismissPopView(false)
            return
        }
                
        if indexPath.item == 0 {
            delegate?.faceViewDidSelectAdd(faceView: self)
        } else {
            let emoji = emojis[indexPath.section].faceEmoji[indexPath.item - 1]

            delegate?.faceViewDidSelectEmoji(faceView: self, emoji: emoji)
        }
    }
}


extension FaceCollectionView {

    internal func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewWillBeginDragging = true
    }
    
    internal func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollViewWillBeginDecelerating = true
    }
    
    internal func scrollViewDidScroll(_ scrollView: UIScrollView) {
        dismissPopView(false)
    }
    
    internal func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollViewWillBeginDragging = false
    }
    
    internal func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewWillBeginDecelerating = false
    }

}


extension FaceCollectionView: EmojiPopViewDelegate {
    
    internal func emojiPopViewShouldDismiss(emojiPopView: EmojiPopView) {
        dismissPopView(true)
    }
    
}


extension FaceCollectionView {
    
    private func setupView() {
        let emojiLongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(emojiLongPressHandle))
        addGestureRecognizer(emojiLongPressGestureRecognizer)
        
        addSubview(emojiPopView)
    }
    
    @objc private func emojiLongPressHandle(sender: UILongPressGestureRecognizer) {
        func longPressLocationInEdge(_ location: CGPoint) -> Bool {
            let edgeRect = collectionView.bounds.inset(by: collectionView.contentInset)
            return edgeRect.contains(location)
        }
        
        guard isShowPopPreview else { return }
        
        let location = sender.location(in: collectionView)
        
        guard longPressLocationInEdge(location) else {
            dismissPopView(true)
            return
        }
        
        guard let indexPath = collectionView.indexPathForItem(at: location) else {
            return
        }
        
        guard let attr = collectionView.layoutAttributesForItem(at: indexPath) else {
            return
        }
        
        let emoji = emojis[indexPath.section].emojis[indexPath.item]
        
        if sender.state == .ended {
            dismissPopView(true)
            return
        }
        
        emojiPopView.setEmoji(emoji)
        
        let cellRect = attr.frame
        let cellFrameInSuperView = collectionView.convert(cellRect, to: self)
        let emojiPopLocation = CGPoint(
            x: cellFrameInSuperView.origin.x - ((TopPartSize.width - BottomPartSize.width) / 2.0) + 5,
            y: cellFrameInSuperView.origin.y - TopPartSize.height - 10
        )
        emojiPopView.move(location: emojiPopLocation, animation: sender.state != .began)
    }
    
    private func dismissPopView(_ usePopViewEmoji: Bool) {
        emojiPopView.dismiss()
        
        let currentEmoji = emojiPopView.currentEmoji
        if !currentEmoji.isEmpty && usePopViewEmoji {

        }
        
        emojiPopView.currentEmoji = ""
    }
    
}
