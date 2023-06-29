
import DifferenceKit
import Foundation
import UIKit

struct User: Hashable {

    var id: String

    var name: String

    var faceURL: String?
}

extension User: Differentiable {}
