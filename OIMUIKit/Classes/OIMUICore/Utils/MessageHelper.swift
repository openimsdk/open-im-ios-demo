
import Foundation

struct MessageHelper {
    /// 获取消息摘要
    static func getAbstructOf(message: MessageInfo?, isSingleChat: Bool, unreadCount: Int, status: ReceiveMessageOpt) -> NSAttributedString {
        var abstruct = ""
        if status != .receive, unreadCount > 0 {
            let unreadDesc: String
            if unreadCount > 99 {
                unreadDesc = "99+"
            } else {
                unreadDesc = "\(unreadCount)"
            }
            abstruct = "[\(unreadDesc)]条"
        }
        let defaultAttr: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13),
            NSAttributedString.Key.foregroundColor: StandardUI.color_666666,
        ]
        guard let message = message else {
            return NSAttributedString(string: abstruct, attributes: defaultAttr)
        }
        var tmpAttr: NSAttributedString?
        switch message.contentType {
        case .text:
            abstruct += message.content ?? ""
        case .image:
            abstruct += "[图片]"
        case .audio:
            abstruct += "[语音]"
        case .video:
            abstruct += "[视频]"
        case .file:
            abstruct += "[文件]"
        case .at:
            // TODO:
            if let atElem = message.atElem {
                if atElem.isAtSelf {
                    tmpAttr = NSAttributedString(string: "[有人@我]", attributes: [
                        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13),
                        NSAttributedString.Key.foregroundColor: StandardUI.color_1B72EC,
                    ])
                } else {
                    let names = atElem.atUsersInfo?.compactMap { $0.groupNickname } ?? []
                    var desc: String = ""
                    for name in names {
                        desc.append(name)
                        desc.append(" ")
                    }
                    tmpAttr = NSAttributedString(string: "@\(desc)", attributes: [
                        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
                        NSAttributedString.Key.foregroundColor: StandardUI.color_999999,
                    ])
                }
            }
        case .card:
            abstruct += "[名片]"
        case .location:
            abstruct += "[位置]"
        case .face:
            abstruct += "[自定义表情]"
        case .quote:
            abstruct += message.quoteElem?.text ?? ""
        default:
            tmpAttr = getSystemNotificationOf(message: message, isSingleChat: isSingleChat)
        }
        var ret = NSMutableAttributedString(string: abstruct, attributes: defaultAttr)
        if let tmpAttr = tmpAttr {
            ret.append(tmpAttr)
        }
        return ret
    }

    private static func getMidnightOf(date: Date) -> TimeInterval {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateStr = formatter.string(from: date)
        let midnight = formatter.date(from: dateStr)
        return midnight?.timeIntervalSince1970 ?? 0
    }

    static func convertList(timestamp_ms: Int) -> String {
        let current = TimeInterval(timestamp_ms / 1000)

        let date = Date(timeIntervalSince1970: current)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let zero = getMidnightOf(date: Date())
        let offset = zero - current
        let secondsPerDay: Double = 24 * 60 * 60

        var desc = ""
        if offset <= 0 {
            let now = Date().timeIntervalSince1970
            if fabs(now - current) < 3 * 60 {
                desc = "刚刚".innerLocalized()
            } else {
                desc = formatter.string(from: date)
            }
            return desc
        }

        if offset <= 1 * secondsPerDay {
            let m = formatter.string(from: date)
            desc = "昨天".innerLocalized() + " " + "\(m)"
            return desc
        }

        let calendar = Calendar.current
        if offset <= 7 * secondsPerDay {
            let flag = Calendar.Component.weekday
            let currentCompo = calendar.dateComponents([flag], from: date)
            guard let week = currentCompo.weekday else {
                return desc
            }
            switch week {
            case 1: desc = "星期日".innerLocalized()
            case 2: desc = "星期一".innerLocalized()
            case 3: desc = "星期二".innerLocalized()
            case 4: desc = "星期三".innerLocalized()
            case 5: desc = "星期四".innerLocalized()
            case 6: desc = "星期五".innerLocalized()
            case 7: desc = "星期日".innerLocalized()
            default:
                break
            }
            return desc
        }

        formatter.dateFormat = "yyyy/MM/dd"
        desc = formatter.string(from: date)
        return desc
    }

    static func getSystemNotificationOf(message: MessageInfo, isSingleChat: Bool) -> NSAttributedString? {
        let nameAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
            NSAttributedString.Key.foregroundColor: StandardUI.color_999999,
        ]

        let contentAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
            NSAttributedString.Key.foregroundColor: StandardUI.color_999999,
        ]
        func getSpaceString() -> NSAttributedString {
            return NSAttributedString(string: " ", attributes: contentAttributes)
        }
        func getOpUserName(message: MessageInfo) -> NSAttributedString {
            var ret = NSMutableAttributedString()
            if let opUser = message.notificationElem?.opUser {
                if opUser.userID == IMController.shared.uid {
                    ret.append(NSAttributedString(string: "你".innerLocalized(), attributes: contentAttributes))
                } else {
                    let name = NSAttributedString(string: opUser.nickname ?? "", attributes: nameAttributes)
                    ret.append(name)
                    ret.append(getSpaceString())
                }
            }
            return ret
        }
        switch message.contentType {
        case .friendAdded:
            let content = NSAttributedString(string: "你们已成功加为好友".innerLocalized(), attributes: contentAttributes)
            return content
        case .memberQuit:
            if let elem = message.notificationElem?.quitUser {
                var ret = NSMutableAttributedString()
                if elem.userID == IMController.shared.uid {
                    ret.append(NSAttributedString(string: "你".innerLocalized(), attributes: contentAttributes))
                } else {
                    let name = NSAttributedString(string: elem.nickname ?? "", attributes: nameAttributes)
                    ret.append(name)
                    ret.append(getSpaceString())
                }
                let content = NSAttributedString(string: "已退出群聊".innerLocalized(), attributes: contentAttributes)
                ret.append(content)
                return ret
            }
        case .memberEnter:
            if let elem = message.notificationElem?.entrantUser {
                var ret = NSMutableAttributedString()
                if elem.userID == IMController.shared.uid {
                    let name = NSAttributedString(string: "你".innerLocalized(), attributes: contentAttributes)
                    ret.append(name)
                } else {
                    ret.append(getSpaceString())
                    ret.append(NSAttributedString(string: elem.nickname ?? "", attributes: nameAttributes))
                    ret.append(getSpaceString())
                }
                ret.append(NSAttributedString(string: "已加入群聊".innerLocalized(), attributes: contentAttributes))
                return ret
            }
        case .memberKicked:
            let ret = NSMutableAttributedString()
            if let nickName = message.notificationElem?.quitUser?.nickname {
                let name = NSAttributedString(string: nickName, attributes: nameAttributes)
                ret.append(name)
            }
            ret.append(getSpaceString())
            ret.append(NSAttributedString(string: "已被", attributes: contentAttributes))
            if let opUser = message.notificationElem?.opUser {
                if opUser.userID == IMController.shared.uid {
                    ret.append(NSAttributedString(string: "你", attributes: contentAttributes))
                } else {
                    ret.append(getSpaceString())
                    let name = NSAttributedString(string: opUser.nickname ?? "", attributes: nameAttributes)
                    ret.append(getSpaceString())
                }
            }
            ret.append(NSAttributedString(string: "踢出群聊", attributes: contentAttributes))
            return ret
        case .memberInvited:
            let ret = NSMutableAttributedString()
            ret.append(getOpUserName(message: message))
            ret.append(NSAttributedString(string: "邀请".innerLocalized(), attributes: contentAttributes))
            if let invitedUser = message.notificationElem?.invitedUserList {
                for user in invitedUser {
                    let name = NSAttributedString(string: user.nickname ?? "", attributes: nameAttributes)
                    ret.append(name)
                    ret.append(getSpaceString())
                }
            }
            ret.append(NSAttributedString(string: "加入群聊".innerLocalized(), attributes: contentAttributes))
            return ret
        case .groupCreated:
            let ret = NSMutableAttributedString()
            ret.append(getOpUserName(message: message))
            ret.append(NSAttributedString(string: "创建了群聊".innerLocalized(), attributes: contentAttributes))
            return ret
        case .groupInfoSet:
            let ret = NSMutableAttributedString()
            ret.append(getOpUserName(message: message))
            ret.append(NSAttributedString(string: "更新了群信息".innerLocalized(), attributes: contentAttributes))
            return ret
        case .revokeReciept:
            let ret = NSMutableAttributedString()
            ret.append(NSAttributedString(string: message.senderNickname ?? "", attributes: contentAttributes))
            ret.append(getSpaceString())
            ret.append(NSAttributedString(string: "撤回了一条消息".innerLocalized(), attributes: contentAttributes))
            return ret
        case .conversationNotification:
            let content = NSAttributedString(string: isSingleChat ? "你已开启此会话消息免打扰".innerLocalized() : "你已解除屏蔽该群聊".innerLocalized(), attributes: contentAttributes)
            return content
        case .conversationNotNotification:
            let content = NSAttributedString(string: isSingleChat ? "你已关闭此会话消息免打扰".innerLocalized() : "你已屏蔽该群聊".innerLocalized(), attributes: contentAttributes)
            return content
        case .dismissGroup:
            let ret = NSMutableAttributedString()
            ret.append(getOpUserName(message: message))
            ret.append(NSAttributedString(string: "解散了群聊".innerLocalized(), attributes: contentAttributes))
            return ret
        case .typing:
            return nil
        default:
            let content = NSAttributedString(string: "不支持的消息类型".innerLocalized(), attributes: contentAttributes)
            return content
        }
        return nil
    }

    static func getAudioMessageDisplayWidth(duration: Int) -> CGFloat {
        let duration = CGFloat(duration)
        let Lmin: CGFloat = 50

        let Lmax: CGFloat = kScreenWidth * 0.5
        var barLen: CGFloat = 0
        var barCanChangeLen: CGFloat = Lmax - Lmin
        var unitWidth: CGFloat = barCanChangeLen / 58

        switch duration {
        case 0 ..< 2:
            barLen = Lmin
        case 2 ..< 10:
            barLen = Lmin + (duration - 2) * unitWidth
        case 10 ..< 60:
            barLen = (Lmin + 10 * unitWidth) + (70 - duration) / 10 * unitWidth
        default:
            barLen = Lmax
        }
        return barLen
    }
}
