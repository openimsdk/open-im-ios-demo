
import UIKit

let kScreenWidth: CGFloat = UIScreen.main.bounds.size.width
let kScreenHeight: CGFloat = UIScreen.main.bounds.size.height
let kStatusBarHeight: CGFloat = {
    if #available(iOS 13.0, *) {
        guard let statusBarHeight = UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.size.height, statusBarHeight != 0 else { return 0 }
        return statusBarHeight
    } else {
        return UIApplication.shared.statusBarFrame.size.height
    }
}()

let kSafeAreaBottomHeight: CGFloat = {
    guard let bottomHeight = UIApplication.shared.windows.first?.safeAreaInsets.bottom else { return 0 }
    return bottomHeight
}()

let isIPhoneXSeries: Bool = {
    guard let bottomHeight = UIApplication.shared.windows.first?.safeAreaInsets.bottom, bottomHeight > 0 else { return false }
    return true
}()

enum StandardUI {
    /// 文本黑色
    static let color_333333 = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
    /// 文本灰色
    static let color_999999 = #colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
    static let color_666666 = #colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
    /// 主题蓝色
    static let color_1B72EC = #colorLiteral(red: 0.1058823529, green: 0.4470588235, blue: 0.9254901961, alpha: 1)
    /// badge红色
    static let color_F44038 = #colorLiteral(red: 0.9568627451, green: 0.2509803922, blue: 0.2196078431, alpha: 1)
    /// 分割线白色
    static let color_F1F1F1 = #colorLiteral(red: 0.9450980392, green: 0.9450980392, blue: 0.9450980392, alpha: 1)
    /// 分割线浅灰色
    static let color_E9E9E9 = #colorLiteral(red: 0.9137254902, green: 0.9137254902, blue: 0.9137254902, alpha: 1)
    /// 主题文本蓝色
    static let color_418AE5 = #colorLiteral(red: 0.2549019608, green: 0.5411764706, blue: 0.8980392157, alpha: 1)
    /// 按钮文本灰色
    static let color_898989 = #colorLiteral(red: 0.537254902, green: 0.537254902, blue: 0.537254902, alpha: 1)
    /// 提示文本浅灰色
    static let color_BEBEBE = #colorLiteral(red: 0.7450980392, green: 0.7450980392, blue: 0.7450980392, alpha: 1)
    /// 状态绿色
    static let color_10CC64 = #colorLiteral(red: 0.06274509804, green: 0.8, blue: 0.3921568627, alpha: 1)
    /// 提示蛋黄色
    static let color_FFAB41 = #colorLiteral(red: 1, green: 0.6705882353, blue: 0.2549019608, alpha: 1)
    /// 工具栏背景紫
    static let color_E8F2FF = #colorLiteral(red: 0.9098039216, green: 0.9490196078, blue: 1, alpha: 1)
    /// 工具栏强调紫
    static let color_1D6BED = #colorLiteral(red: 0.1137254902, green: 0.4196078431, blue: 0.9294117647, alpha: 1)
    /// 消息背景淡紫
    static let color_B3D7FF = #colorLiteral(red: 0.7019607843, green: 0.8431372549, blue: 1, alpha: 1)
    /// 消息背景灰
    static let color_F0F0F0 = #colorLiteral(red: 0.9411764706, green: 0.9411764706, blue: 0.9411764706, alpha: 1)
    /// 图片背景灰
    static let color_D8D8D8 = #colorLiteral(red: 0.8470588235, green: 0.8470588235, blue: 0.8470588235, alpha: 1)

    static let margin_22: CGFloat = 22
    static let avatar_42: CGFloat = 42
    /// 默认头像
    static let avatar_placeholder = "contact_my_friend_icon"
}
