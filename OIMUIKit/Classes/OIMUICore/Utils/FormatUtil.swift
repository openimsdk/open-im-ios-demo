//






import Foundation

struct FormatUtil {
    static func getMediaFormat(of seconds: Int) -> String {
        if seconds / 3600 > 24 {
            return "时长超过了24小时，请检查输入值"
        }
        if seconds / 3600 > 0 {
            let hour = seconds / 3600
            let min = seconds % 3600 / 60
            let sec = seconds % 3600 % 60
            return String.init(format: "%02d:%02d:%02d", hour, min, sec)
        } else {
            let min = seconds / 60
            let sec = seconds % 60 % 60
            return String.init(format: "%02d:%02d", min, sec)
        }
    }
}
