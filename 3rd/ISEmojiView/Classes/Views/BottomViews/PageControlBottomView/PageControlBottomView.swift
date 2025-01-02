






import Foundation
import UIKit

internal protocol PageControlBottomViewDelegate: AnyObject {
    
    func pageControlBottomViewDidPressDeleteBackwardButton(_ bottomView: PageControlBottomView)
    func pageControlBottomViewDidPressDismissKeyboardButton(_ bottomView: PageControlBottomView)
    
}

final internal class PageControlBottomView: UIView {

    
    internal weak var delegate: PageControlBottomViewDelegate?

    
    @IBOutlet private weak var pageControl: UIPageControl!

    @IBOutlet private weak var deleteButton: UIButton!

    
    static func loadFromNib(categoriesCount: Int, needToShowDeleteButton: Bool) -> PageControlBottomView {
        let nibName = String(describing: PageControlBottomView.self)
        
        guard let nib = Bundle.podBundle.loadNibNamed(nibName, owner: nil, options: nil) as? [PageControlBottomView] else {
            fatalError()
        }
        
        guard let bottomView = nib.first else {
            fatalError()
        }
        
        bottomView.pageControl.numberOfPages = categoriesCount
        bottomView.deleteButton.isHidden = !needToShowDeleteButton
        return bottomView
    }

    
    internal func updatePageControlPage(_ page: Int) {
        pageControl.currentPage = page
    }

    
    @IBAction private func deleteBackward() {
        delegate?.pageControlBottomViewDidPressDeleteBackwardButton(self)
    }
    
    @IBAction private func dismissKeyboard() {
        delegate?.pageControlBottomViewDidPressDismissKeyboardButton(self)
    }
    
}
