import ChatLayout
import Foundation
import UIKit

protocol ChatCollectionDataSource: UICollectionViewDataSource, ChatLayoutDelegate {

    var sections: [Section] { get set }

    func prepare(with collectionView: UICollectionView)

    
}
