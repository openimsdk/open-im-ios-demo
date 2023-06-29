
import Foundation
import UIKit

final class AvatarViewController {
    var name: String?
    var faceURL: String?
    
    weak var delegate: ReloadDelegate?
    
    private let user: User

    private let bubble: Cell.BubbleType

    weak var view: ChatAvatarView? {
        didSet {
            view?.reloadData()
        }
    }

    init(user: User, bubble: Cell.BubbleType) {
        self.user = user
        self.bubble = bubble
        self.name = user.name
        self.faceURL = user.faceURL
    }
    
    func action() {
        delegate?.didTapAvatar(with: user.id)
    }
}
