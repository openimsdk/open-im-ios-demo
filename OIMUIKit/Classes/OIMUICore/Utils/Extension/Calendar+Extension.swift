





import Foundation

extension Calendar {
    func isDateInMonth(_ date: Date) -> Bool {
        let current = Date()
        return self.isDate(current, equalTo: date, toGranularity: Component.month)
    }
    
    func isDateInWeek(_ date: Date) -> Bool {
        return self.isDate(Date(), equalTo: date, toGranularity: Component.weekday)
    }
}
