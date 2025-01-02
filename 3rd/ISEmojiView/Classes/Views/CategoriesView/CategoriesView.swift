






import Foundation
import UIKit

private let MinCellSize = CGFloat(35)

internal protocol CategoriesViewDelegate: AnyObject {
    
    func categoriesViewDidSelecteCategory(_ category: Category, bottomView: CategoriesView)
    func categoriesViewDidPressChangeKeyboardButton(_ bottomView: CategoriesView)
    func categoriesViewDidPressDeleteBackwardButton(_ bottomView: CategoriesView)
    
}

final internal class CategoriesView: UIView {

    
    internal weak var delegate: CategoriesViewDelegate?
    internal var needToShowAbcButton: Bool? {
        didSet {
            guard let showAbcButton = needToShowAbcButton else {
                return
            }
            
            changeKeyboardButton.isHidden = !showAbcButton
            collectionViewToSuperViewLeadingConstraint.priority = showAbcButton ? .defaultHigh : .defaultLow
        }
    }
    
    internal var categories: [Category]! {
        didSet {
            collectionView.reloadData()
            
            if let selectedItems = collectionView.indexPathsForSelectedItems, selectedItems.isEmpty {
                selectFirstCell()
            }
        }
    }

    
    @IBOutlet private weak var changeKeyboardButton: UIButton!
    @IBOutlet private weak var deleteButton: UIButton! {
        didSet {
            let image = UIImage(named: "ic_emojiDelete", in: Bundle.podBundle,compatibleWith: nil)
            deleteButton.setImage(image, for: .normal)
        }
    }
    
    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: "CategoryCell")
        }
    }
    
    @IBOutlet private var collectionViewToSuperViewLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var collecitonViewToSuperViewTrailingConstraint: NSLayoutConstraint!

    
    static internal func loadFromNib(with categories: [Category], needToShowAbcButton: Bool, needToShowDeleteButton: Bool) -> CategoriesView {
        let nibName = String(describing: CategoriesView.self)
        
        guard let nib = Bundle.podBundle.loadNibNamed(nibName, owner: nil, options: nil) as? [CategoriesView] else {
            fatalError()
        }
        
        guard let bottomView = nib.first else {
            fatalError()
        }
        
        bottomView.categories = categories
        bottomView.changeKeyboardButton.isHidden = !needToShowAbcButton
        bottomView.deleteButton.isHidden = !needToShowDeleteButton
        
        if needToShowAbcButton {
            bottomView.collectionViewToSuperViewLeadingConstraint.priority = .defaultHigh
        }

        if !needToShowDeleteButton {
          bottomView.collecitonViewToSuperViewTrailingConstraint.priority = .defaultHigh
        }

        bottomView.selectFirstCell()
        
        return bottomView
    }

    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            var size = collectionView.bounds.size
            
            if categories.count < Category.count - 2 {
                size.width = MinCellSize
            } else {
                size.width = collectionView.bounds.width/CGFloat(categories.count)
            }
            
            layout.itemSize = size
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    
    internal func updateCurrentCategory(_ category: Category) {
        guard let item = categories.firstIndex(where: { $0 == category }) else {
            return
        }
        
        guard let selectedItem = collectionView.indexPathsForSelectedItems?.first?.item else {
            return
        }
        
        guard selectedItem != item else {
            return
        }
        
        (0..<categories.count).forEach {
            let indexPath = IndexPath(item: $0, section: 0)
            collectionView.deselectItem(at: indexPath, animated: false)
        }
        
        let indexPath = IndexPath(item: item, section: 0)
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
    }

    
    @IBAction private func changeKeyboard() {
        delegate?.categoriesViewDidPressChangeKeyboardButton(self)
    }
    
    @IBAction private func deleteBackward() {
        delegate?.categoriesViewDidPressDeleteBackwardButton(self)
    }
    
}


extension CategoriesView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        cell.setEmojiCategory(categories[indexPath.item])
        return cell
    }
    
}


extension CategoriesView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.categoriesViewDidSelecteCategory(categories[indexPath.item], bottomView: self)
    }
    
}


extension CategoriesView {
 
    private func selectFirstCell() {
        let indexPath = IndexPath(item: 0, section: 0)
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
    }
    
}
