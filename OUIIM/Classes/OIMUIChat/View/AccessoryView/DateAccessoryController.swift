
import Foundation

final class DateAccessoryController {

    private let date: Date

    let accessoryText: String

    init(date: Date) {
        self.date = date
        accessoryText = MessageDateFormatter.shared.string(from: date)
    }

}
