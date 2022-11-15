
import Foundation

public struct FormatUtil {
    static func getMediaFormat(of seconds: Int) -> String {
        if seconds / 3600 > 24 {
            return "时长超过了24小时，请检查输入值"
        }
        if seconds / 3600 > 0 {
            let hour = seconds / 3600
            let min = seconds % 3600 / 60
            let sec = seconds % 3600 % 60
            return String(format: "%02d:%02d:%02d", hour, min, sec)
        } else {
            let min = seconds / 60
            let sec = seconds % 60 % 60
            return String(format: "%02d:%02d", min, sec)
        }
    }

    public static func getFormatDate(formatString: String = "yyyy/MM/dd", of seconds: Int) -> String {
        let format = DateFormatter()
        format.dateFormat = formatString
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        let str = format.string(from: date)
        return str
    }

    static func getFileSizeDesc(fileSize: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        let ret = formatter.string(fromByteCount: Int64(fileSize))
        return ret
    }

    static func isWeek(seconds: Int) -> Bool {
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        let ret = Calendar.current.isDateInWeekend(date)
        return ret
    }

    static func isThisMonth(seconds: Int) -> Bool {
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        let ret = Calendar.current.isDateInMonth(date)
        return ret
    }
}
