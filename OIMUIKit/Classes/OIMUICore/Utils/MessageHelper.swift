//






import Foundation

struct MessageHelper {
    
    static func getAbstructOf(message: MessageInfo?, isSingleChat: Bool, unreadCount: Int, status: ReceiveMessageOpt) -> NSAttributedString {
        var abstruct: String = ""
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
            NSAttributedString.Key.foregroundColor: StandardUI.color_666666
        ]
        guard let message = message else {
            return NSAttributedString.init(string: abstruct, attributes: defaultAttr)
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
            
            if let atElem = message.atElem {
                if atElem.isAtSelf {
                    tmpAttr = NSAttributedString.init(string: "[有人@我]", attributes: [
                        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13),
                        NSAttributedString.Key.foregroundColor: StandardUI.color_1B72EC
                    ])
                } else {
                    let names = atElem.atUsersInfo?.compactMap{$0.groupNickname} ?? []
                    var desc: String = ""
                    for name in names {
                        desc.append(name)
                        desc.append(" ")
                    }
                    tmpAttr = NSAttributedString.init(string: "@\(desc)", attributes: [
                        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
                        NSAttributedString.Key.foregroundColor: StandardUI.color_999999
                    ])
                }
            }
        case .card:
            abstruct += "[名片]"
        case .location:
            abstruct += "[位置]"
        case .face:
            abstruct += "[自定义表情]"
        default:
            tmpAttr = getSystemNotificationOf(message: message, isSingleChat: isSingleChat)
        }
        var ret = NSMutableAttributedString.init(string: abstruct, attributes: defaultAttr)
        if let tmpAttr = tmpAttr {
            ret.append(tmpAttr)
        }
        return ret
    }
    
    private static func getMidnightOf(date: Date) -> TimeInterval {
      let formatter = DateFormatter();
      formatter.dateFormat = "yyyy/MM/dd";
      let dateStr = formatter.string(from: date);
      let midnight = formatter.date(from: dateStr);
      return midnight?.timeIntervalSince1970 ?? 0;
    }
    
    static func convertList(timestamp_ms: Int) -> String {
        let current = TimeInterval(timestamp_ms / 1000);
        
        let date = Date(timeIntervalSince1970: current);
        let formatter = DateFormatter();
        formatter.dateFormat = "HH:mm";
        let zero = getMidnightOf(date: Date());
        let offset = zero - current;
        let secondsPerDay: Double = 24 * 60 * 60;
        
        var desc = "";
        if offset <= 0 {
            let now = Date().timeIntervalSince1970;
            if fabs(now - current) < 3 * 60 {
                desc = "刚刚";
            }else {
                desc = formatter.string(from: date);
            }
            return desc;
        }
        
        if offset <= 1 * secondsPerDay {
            let m = formatter.string(from: date);
            desc = "昨天 \(m)";
            return desc;
        }
        
        let calendar = Calendar.current;
        if offset <= 7 * secondsPerDay {
            let flag = Calendar.Component.weekday;
            let currentCompo = calendar.dateComponents([flag], from: date);
            guard let week = currentCompo.weekday else {
                return desc;
            }
            switch week {
            case 1: desc = "星期日";break;
            case 2: desc = "星期一";break;
            case 3: desc = "星期二";break;
            case 4: desc = "星期三";break;
            case 5: desc = "星期四";break;
            case 6: desc = "星期五";break;
            case 7: desc = "星期日";break;
            default:
                break;
            }
            return desc;
        }
        
        formatter.dateFormat = "yyyy/MM/dd";
        desc = formatter.string(from: date);
        return desc;
    }
    
    static func convertDetail(timestamp_ms: Int) -> String {
        let current = TimeInterval(timestamp_ms / 1000);
        
        let date = Date(timeIntervalSince1970: current);
        let formatter = DateFormatter();
        formatter.dateFormat = "HH:mm";
        let zero = MessageHelper.getMidnightOf(date: Date());
        let offset = zero - current;
        let secondsPerDay: Double = 24 * 60 * 60;
        let hhmm = formatter.string(from: date);
        
        var desc = "";
        if offset <= 0 {
            desc = hhmm;
            return desc;
        }
        
        if offset <= 1 * secondsPerDay {
            desc = "昨天 \(hhmm)";
            return desc;
        }
        
        let calendar = Calendar.current;
        if offset <= 7 * secondsPerDay {
            let flag = Calendar.Component.weekday;
            let currentCompo = calendar.dateComponents([flag], from: date);
            guard let week = currentCompo.weekday else {
                return desc;
            }
            switch week {
            case 1: desc = "星期日 \(hhmm)";break;
            case 2: desc = "星期一 \(hhmm)";break;
            case 3: desc = "星期二 \(hhmm)";break;
            case 4: desc = "星期三 \(hhmm)";break;
            case 5: desc = "星期四 \(hhmm)";break;
            case 6: desc = "星期五 \(hhmm)";break;
            case 7: desc = "星期日 \(hhmm)";break;
            default:
                break;
            }
            return desc;
        }
        
        formatter.dateFormat = "yyyy/MM/dd HH:mm";
        desc = formatter.string(from: date);
        return desc;
    }
    
    static let emojiRegex = "\\[[^\\[\\]\\s]+\\]"
    static func getEmojiReplaced(string: String) -> NSAttributedString {
        let ntext = string as NSString
        let lineSpacing: CGFloat = 2
        let font = UIFont.systemFont(ofSize: 14)
        let textColor = StandardUI.color_333333
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing > 0 ? max(lineSpacing + font.pointSize - font.lineHeight, 0) : lineSpacing
        let defaultAttr: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]
        
        var atr = NSMutableAttributedString.init(string: string, attributes: defaultAttr)
        do {
            let emotionReg: NSRegularExpression = try NSRegularExpression.init(pattern: MessageHelper.emojiRegex, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let emotionResults = emotionReg.matches(in: string, options: [], range: NSRange.init(location: 0, length: ntext.length))
            
            for (_, match) in emotionResults.enumerated().reversed() {
                let matchString: String = ntext.substring(with: match.range)
                if let emojiName: String = ChatEmojiHelper.emojiMap[matchString], let emoji = UIImage.init(nameInEmoji: emojiName) {
                    let imageAttachment = NSTextAttachment.init()
                    imageAttachment.image = emoji
                    imageAttachment.bounds = CGRect(x: 0, y: font.descender, width: font.lineHeight, height: font.lineHeight)
                    let attrStringWithImage = NSAttributedString.init(attachment: imageAttachment)
                    atr.replaceCharacters(in: NSRange(location: match.range.location, length: match.range.length), with: attrStringWithImage)
                }
            }
        } catch { }
        return atr
    }
    
    static func getSystemNotificationOf(message: MessageInfo, isSingleChat: Bool) -> NSAttributedString? {
        let nameAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
            NSAttributedString.Key.foregroundColor: StandardUI.color_999999
        ]
        
        let contentAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
            NSAttributedString.Key.foregroundColor: StandardUI.color_999999
        ]
        func getSpaceString() -> NSAttributedString {
            return NSAttributedString.init(string: " ", attributes: contentAttributes)
        }
        func getOpUserName(message: MessageInfo) -> NSAttributedString {
            var ret = NSMutableAttributedString()
            if let opUser = message.notificationElem?.opUser {
                if opUser.userID == IMController.shared.uid {
                    ret.append(NSAttributedString.init(string: "你", attributes: contentAttributes))
                } else {
                    let name = NSAttributedString.init(string: opUser.nickname ?? "", attributes: nameAttributes)
                    ret.append(name)
                    ret.append(getSpaceString())
                }
            }
            return ret
        }
        switch message.contentType {
        case .friendAdded:
            let content = NSAttributedString.init(string: "你们已成功加为好友", attributes: contentAttributes)
            return content
        case .memberQuit:
            if let elem = message.notificationElem?.quitUser {
                let name = NSMutableAttributedString.init(string: elem.nickname ?? "", attributes: nameAttributes)
                let content = NSAttributedString.init(string: "已退出群聊", attributes: contentAttributes)
                name.append(getSpaceString())
                name.append(content)
                return name
            }
        case .memberEnter:
            if let elem = message.notificationElem?.entrantUser {
                var ret = NSMutableAttributedString()
                if elem.userID == IMController.shared.uid {
                    let name = NSAttributedString.init(string: "你", attributes: contentAttributes)
                    ret.append(name)
                } else {
                    ret.append(getSpaceString())
                    ret.append(NSAttributedString.init(string: elem.nickname ?? "", attributes: nameAttributes))
                    ret.append(getSpaceString())
                    ret.append(NSAttributedString.init(string: "已加入群聊", attributes: contentAttributes))
                }
                return ret
            }
        case .memberKicked:
            let ret = NSMutableAttributedString.init()
            if let nickName = message.notificationElem?.quitUser?.nickname {
                let name = NSAttributedString.init(string: nickName, attributes: nameAttributes)
                ret.append(name)
            }
            ret.append(getSpaceString())
            ret.append(NSAttributedString.init(string: "已被", attributes: contentAttributes))
            if let opUser = message.notificationElem?.opUser {
                if opUser.userID == IMController.shared.uid {
                    ret.append(NSAttributedString.init(string: "你", attributes: contentAttributes))
                } else {
                    ret.append(getSpaceString())
                    let name = NSAttributedString.init(string: opUser.nickname ?? "", attributes: nameAttributes)
                    ret.append(getSpaceString())
                }
            }
            ret.append(NSAttributedString.init(string: "踢出群聊", attributes: contentAttributes))
            return ret
        case .memberInvited:
            let ret = NSMutableAttributedString.init()
            ret.append(getOpUserName(message: message))
            ret.append(NSAttributedString.init(string: "邀请", attributes: contentAttributes))
            if let invitedUser = message.notificationElem?.invitedUserList {
                for user in invitedUser {
                    let name = NSAttributedString.init(string: user.nickname ?? "", attributes: nameAttributes)
                    ret.append(name)
                    ret.append(getSpaceString())
                }
            }
            ret.append(NSAttributedString.init(string: "加入群聊", attributes: contentAttributes))
            return ret
        case .groupCreated:
            let ret = NSMutableAttributedString.init()
            ret.append(getOpUserName(message: message))
            ret.append(NSAttributedString.init(string: "创建了群聊", attributes: contentAttributes))
            return ret
        case .groupInfoSet:
            let ret = NSMutableAttributedString.init()
            ret.append(getOpUserName(message: message))
            ret.append(NSAttributedString.init(string: "更新了群信息", attributes: contentAttributes))
            return ret
        case .revokeReciept:
            let ret = NSMutableAttributedString.init()
            ret.append(NSAttributedString.init(string: message.senderNickname ?? "", attributes: contentAttributes))
            ret.append(getSpaceString())
            ret.append(NSAttributedString.init(string: "撤回了一条消息", attributes: contentAttributes))
            return ret
        case .conversationNotification:
            let content = NSAttributedString.init(string: isSingleChat ? "你已开启此会话消息免打扰" : "你已解除屏蔽该群聊", attributes: contentAttributes)
            return content
        case .conversationNotNotification:
            let content = NSAttributedString.init(string: isSingleChat ? "你已关闭此会话消息免打扰" : "你已屏蔽该群聊", attributes: contentAttributes)
            return content
        case .dismissGroup:
            let ret = NSMutableAttributedString.init()
            ret.append(getOpUserName(message: message))
            ret.append(NSAttributedString.init(string: "解散了群聊", attributes: contentAttributes))
            return ret
        default:
            let content = NSAttributedString.init(string: "不支持的消息类型", attributes: contentAttributes)
            return content
        }
        return nil
    }
}
