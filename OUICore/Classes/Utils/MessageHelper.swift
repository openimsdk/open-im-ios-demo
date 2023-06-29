
import Foundation

public struct MessageHelper {
    /// 获取消息摘要
    public static func getAbstructOf(conversation: ConversationInfo) -> NSAttributedString {
        var abstruct = ""
        let message = conversation.latestMsg
        let isSingleChat = conversation.conversationType == .c2c
        let unreadCount = conversation.unreadCount
        let status = conversation.recvMsgOpt
        
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
            NSAttributedString.Key.font: UIFont.f14,
            NSAttributedString.Key.foregroundColor: UIColor.c8E9AB0,
        ]
        guard let message = message else {
            return NSAttributedString(string: abstruct, attributes: defaultAttr)
        }
        var tmpAttr: NSAttributedString?
        switch message.contentType {
        case .text:
            abstruct += message.textElem?.content ?? ""
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
            if let atElem = message.atTextElem {
                if atElem.isAtSelf {
                    tmpAttr = NSAttributedString(string: "[有人@我]", attributes: [
                        NSAttributedString.Key.font: UIFont.f14,
                        NSAttributedString.Key.foregroundColor: UIColor.c0089FF,
                    ])
                } else {
                    let names = atElem.atUsersInfo?.compactMap { $0.groupNickname } ?? []
                    var desc: String = ""
                    for name in names {
                        desc.append(name)
                        desc.append(" ")
                    }
                    tmpAttr = NSAttributedString(string: "@\(desc)", attributes: [
                        NSAttributedString.Key.font: UIFont.f14,
                        NSAttributedString.Key.foregroundColor: UIColor.c8E9AB0,
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
        case .privateMessage:
            abstruct += conversation.isPrivateChat ? "开启了阅后即焚" : "关闭了阅后即焚"
        case .merge:
            abstruct = "[转发]"
        case .custom:
            abstruct += customMessageAbstruct(message: message)
        default:
            tmpAttr = getSystemNotificationOf(message: message, isSingleChat: isSingleChat)
        }
        var ret = NSMutableAttributedString(string: abstruct, attributes: defaultAttr)
        if let tmpAttr = tmpAttr {
            ret.append(tmpAttr)
        }
        return ret
    }
    
    public static func getSummary(by message: MessageInfo) -> String {
   
        var abstruct = ""
        
        switch message.contentType {
        case .text:
            abstruct += message.textElem?.content ?? ""
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
            if let atElem = message.atTextElem {
                
                if atElem.isAtSelf {
                    abstruct += "[有人@我]"
                } else {
                    let names = atElem.atUsersInfo?.compactMap { $0.groupNickname } ?? []
                    var desc: String = ""
                    for name in names {
                        desc.append(name)
                        desc.append(" ")
                    }
                    abstruct += desc
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
        case .merge:
            abstruct = "[转发]"
        case .custom:
            abstruct += customMessageAbstruct(message: message)
        default:
            break
        }
        
        return abstruct
    }

    private static func getMidnightOf(date: Date) -> TimeInterval {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateStr = formatter.string(from: date)
        let midnight = formatter.date(from: dateStr)
        return midnight?.timeIntervalSince1970 ?? 0
    }

    public static func convertList(timestamp_ms: Int) -> String {
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

    public static func getSystemNotificationOf(message: MessageInfo, isSingleChat: Bool) -> NSAttributedString? {
        let nameAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont.f14,
            NSAttributedString.Key.foregroundColor: UIColor.systemBlue,
        ]

        let contentAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont.f14,
            NSAttributedString.Key.foregroundColor: UIColor.c8E9AB0,
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
        case .friendAppApproved:
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
            if let kickedUsers = message.notificationElem?.kickedUserList {
                let name = NSAttributedString(string: (kickedUsers.map {
                    $0.userID == IMController.shared.uid ?
                    "你" :
                    $0.nickname ?? ""
                }).joined(separator: ","),
                                              attributes: nameAttributes)
                ret.append(name)
            }
            ret.append(getSpaceString())
            ret.append(NSAttributedString(string: "被", attributes: contentAttributes))
            ret.append(getOpUserName(message: message))
            ret.append(NSAttributedString(string: "踢出群聊", attributes: contentAttributes))
            return ret
        case .memberInvited:
            let ret = NSMutableAttributedString()
            ret.append(getOpUserName(message: message))
            ret.append(NSAttributedString(string: "邀请".innerLocalized(), attributes: contentAttributes))
            if let invitedUser = message.notificationElem?.invitedUserList {
                let name = NSAttributedString(string: (invitedUser.map {
                    ($0.userID == IMController.shared.uid ?
                     "你" :
                        $0.nickname) ?? ""
                }).joined(separator: ","),
                                              attributes: nameAttributes)
                ret.append(name)
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
        case .revoke:
            let ret = NSMutableAttributedString()
            var revoker = "" // 撤回人
            var beRevoker = "" // 被撤回的人
            
            let info = message.revokedInfo
            
            if info.sessionType == .c2c {
                revoker = info.revokerIsSelf ? "我".innerLocalized() : info.revokerNickname ?? ""
            } else {
                revoker = info.revokerIsSelf ? "我".innerLocalized() : info.revokerNickname!
                beRevoker = info.revokerIsSelf || info.revokerID == info.sourceMessageSendID
                ? "" : (info.sourceMessageSendIDIsSelf ? "我" : info.sourceMessageSenderNickname!)
            }
            
            ret.append(NSAttributedString(string: revoker, attributes: nameAttributes))
            ret.append(NSAttributedString(string: " 撤回了".innerLocalized(), attributes: contentAttributes))
            if !beRevoker.isEmpty {
                ret.append(NSAttributedString(string: " \(beRevoker) ".innerLocalized(), attributes: nameAttributes))
            }
            ret.append(NSAttributedString(string: "一条消息".innerLocalized(), attributes: contentAttributes))
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
        case .privateMessage:
            if let value = message.notificationElem?.detailObject {
                let enable = value["isPrivate"] as? Bool
                let content = NSAttributedString(string: enable == true ?
                                                 "开启了阅后即焚".innerLocalized() :
                                                 "关闭了阅后即焚".innerLocalized(),
                                                 attributes: contentAttributes)
                return content
            }
            return nil
        case .groupMuted:
            let ret = NSMutableAttributedString()
            ret.append(getOpUserName(message: message))
            ret.append(NSAttributedString(string: "开启了全体禁言".innerLocalized(), attributes: contentAttributes))
            return ret
        case .groupCancelMuted:
            let ret = NSMutableAttributedString()
            ret.append(getOpUserName(message: message))
            ret.append(NSAttributedString(string: "取消了全体禁言".innerLocalized(), attributes: contentAttributes))
            return ret
        case .groupOwnerTransferred:
            let ret = NSMutableAttributedString()
            ret.append(getOpUserName(message: message))
            ret.append(NSAttributedString(string: "将群转让给了\(message.notificationElem?.groupNewOwner?.nickname ?? "")", attributes: contentAttributes))
            return ret
        case .groupSetName:
            let ret = NSMutableAttributedString()
            ret.append(getOpUserName(message: message))
            ret.append(NSAttributedString(string: "修改了群名称".innerLocalized(), attributes: contentAttributes))
            return ret
        case .oaNotification:
            let ret = NSMutableAttributedString()
            if let detail = message.notificationElem?.detailObject {
                 ret.append(NSAttributedString(string: "\(detail["text"] ?? "")", attributes: contentAttributes))
            }
            return ret
        case .groupMemberMuted:
            let ret = NSMutableAttributedString()
            let detail = message.notificationElem?.detailObject
            guard let detail = detail,
                    let mutedUser = detail["mutedUser"] as? [String: Any],
                    let mutedSeconds = detail["mutedSeconds"] as? Int else {return ret}
            
            var dispalySeconds = FormatUtil.getMutedFormat(of: mutedSeconds)
            ret.append(NSAttributedString(string: "\(mutedUser["nickname"] ?? "")被\(getOpUserName(message: message).string)禁言 \(dispalySeconds)", attributes: contentAttributes))
            return ret
        case .groupMemberCancelMuted:
            let ret = NSMutableAttributedString()
            let detail = message.notificationElem?.detailObject
            guard let detail = detail,
                    let mutedUser = detail["mutedUser"] as? [String: Any],
                    let opUser = detail["opUser"] as? [String: Any] else {return ret}
            
            ret.append(NSAttributedString(string: "\(getOpUserName(message: message).string)取消了\(mutedUser["nickname"] ?? "")的禁言", attributes: contentAttributes))
            return ret
        case .groupMemberInfoSet:
            let ret = NSMutableAttributedString()
            ret.append(NSAttributedString(string: "\(getOpUserName(message: message).string)编辑了群成员信息", attributes: contentAttributes))
            return ret            
        default:
            let content = NSAttributedString(string: "不支持的消息类型\(message.contentType)".innerLocalized(), attributes: contentAttributes)
            return content
        }
        return nil
    }

    public static func getAudioMessageDisplayWidth(duration: Int) -> CGFloat {
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
    
    public static func getCustomMessageValueOf(message: MessageInfo) -> NSAttributedString {
        guard message.contentType == .custom,
                let type = message.customElem?.type,
                let value = message.customElem?.value() else { return NSAttributedString() }
        
        var str = NSMutableAttributedString()
        
        switch type {
        case .call:
            break
        case .blockedByFriend, .deletedByFriend:
            break
        case .meeting:
            let inviterNickname = value["inviterNickname"] as! String
            let subject = value["subject"] as! String
            let start = Date.timeString(timeInterval: (value["start"] as! TimeInterval) * 1000)
            let duration = value["duration"] as! Int / 60 / 60
            let ID = value["id"] as! String
            
            let text =
            "\(inviterNickname)邀请你加入视频会议" +
            "\n • 会议主题：\(subject)" +
            "\n • 开始时间：\(start)" +
            "\n • 会议时长：\(duration)小时" +
            "\n • 会议号：\(ID)"
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            str = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
            
            let tips = NSAttributedString(string: "\n\n点击此消息可直接加入会议",
                                          attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemBlue,
                                                       NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)])
            str.append(tips)
            
        default:
            break
        }
        return str
    }
    
    private static func customMessageAbstruct(message: MessageInfo) -> String {
        guard let type = message.customElem?.type else {
            return "不支持的消息类型".innerLocalized()
        }
        
        switch type {
        case .call:
            return "[" + "音视频".innerLocalized() + "]"
        case .customEmoji:
            return "[表情]".innerLocalized()
        case .tagMessage:
            return "[标签]".innerLocalized()
        case .blockedByFriend:
            return "消息已发出，但被对方拒收了".innerLocalized()
        case .deletedByFriend:
            return "对方开启了朋友验证，你还不是他（她）朋友，请先发送朋友验证请求，对方验证通过后才能聊天。".innerLocalized()
        case .moments:
            return "[朋友圈]"
        case .meeting:
            return "[视频会议]"
        }
    }
}

extension MessageInfo {
    public func getSummary() -> String {
        return MessageHelper.getSummary(by: self)
    }
}

extension ConversationInfo {
    public var summary: String? {
        return conversationType == .c2c ? latestMsg?.getSummary() : showName! + ":" + (latestMsg?.getSummary())!
    }
}
