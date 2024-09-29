
import Foundation
import OpenIMSDK
import RxSwift
import RxCocoa

enum CallingState: String {
    case normal = "normal"
    case call = "call"
    case beCalled = "beCalled"
    case reject = "reject"
    case beRejected = "beRejected"
    case calling = "calling"
    case beAccepted = "beAccepted"
    case hangup = "hangup"
    case beHangup = "beHangup"
    case connecting = "connecting"
    case disConnect = "disConnect"
    case connectFailure = "connectFailure"
    case noReply = "noReply"
    case cancel = "cancel"
    case beCanceled = "beCanceled"
    case timeout = "timeout"
    case join = "join"
    case accessByOther = "accessByOther"
    case rejectedByOther = "rejectedByOther"
}

public typealias ValueChangedHandler<T> = (_ value: T) -> Void

public class CallingManager: NSObject {
    private let disposeBag = DisposeBag()
    private var signalingInfo: OIMSignalingInfo?
    
    private var senderViewController: CallingSenderController?
    private var reciverViewController: CallingReceiverController?
    private var inviter: CallingUserInfo?
    private var others: [CallingUserInfo]?
    private var liveURL: String?
    private var token: String?

    public static let manager: CallingManager = CallingManager()
    public var roomParticipantChangedHandler: ValueChangedHandler<OIMParticipantConnectedInfo>?
    public var endCallingHandler: ValueChangedHandler<OIMMessageInfo>?
    
    public func start() {
        NotificationCenter.default.addObserver(self, selector: #selector(willTerminate), name: UIApplication.willTerminateNotification, object: nil);
        
        OIMManager.callbacker.addAdvancedMsgListener(listener: self)
    }
    
    public func end() {
    }
    
    func getTokenForRTC(roomID: String, userID: String) async -> OIMParticipantConnectedInfo? {
        let baseURL = UserDefaults.standard.string(forKey: "com.oimuikit.bussiness.api.adr") ?? ""
        let token = UserDefaults.standard.string(forKey: "bussinessTokenKey") ?? ""
        let body = try? JSONSerialization.data(withJSONObject: ["room": roomID, "identity": userID], options: .fragmentsAllowed)
        guard var request = try? URLRequest(url: URL(string: baseURL + "/user/rtc/get_token")!, method: .post) else { return nil }
        request.httpBody = body
        request.addValue(token, forHTTPHeaderField: "token")
        request.addValue(UUID().uuidString, forHTTPHeaderField: "operationID")
        
        let result = try? await URLSession.shared.data(for: request)
                
        if let d = result?.0 {
            guard let map = try? JSONSerialization.jsonObject(with: d, options: .fragmentsAllowed) as? [String: Any],
                  let data = map["data"] as? [String: Any] else { return nil }
            let url = data["serverUrl"] as! String
            let token = data["token"] as! String
            
            let r = OIMParticipantConnectedInfo()
            r.liveURL = url
            r.token = token
            r.roomID = roomID
            
            return r
        }
        
        return nil
    }

    public func forceDismiss() {
        if let senderViewController {
            senderViewController.removeMiniWindow()
        }
        
        if let reciverViewController {
            reciverViewController.removeMiniWindow()
        }
    }
    
    @objc private func willTerminate() {
        update(state: .hangup)
    }
    
    private func setupSenderViewController() {
        senderViewController = CallingSenderController()

        senderViewController!.onDisconnect = { [weak self] in
            self?.update(state: .disConnect)
        }
        
        senderViewController!.onConnectFailure = { [weak self] in
            self?.update(state: .connectFailure)
        }
        
        senderViewController!.onCancel = { [weak self] in
            self?.update(state: .cancel)
        }
        
        senderViewController!.onHungup = { [weak self] duration in
            self?.update(state: .hangup, duration: duration)
        }
    }
    
    private func setupReciverViewController() {
        reciverViewController = CallingReceiverController()
        reciverViewController!.onDisconnect = { [weak self] in
            self?.update(state: .disConnect)
        }
        
        reciverViewController!.onConnectFailure = { [weak self] in
            self?.update(state: .connectFailure)
        }
        
        reciverViewController!.onAccepted = { [weak self] in
            if let signalingInfo = self?.signalingInfo {
                
                self?.sendSinglingMessage(type: 201, data: signalingInfo.invitation.mj_keyValues() as! [String : Any], recvID: signalingInfo.invitation.inviterUserID)
                
                Task { [self] in
                    let certificate = await self?.getTokenForRTC(roomID: signalingInfo.invitation.roomID, userID: OIMManager.manager.getLoginUserID())
        
                    if let certificate {
                        await self?.reciverViewController?.connectRoom(liveURL: certificate.liveURL, token: certificate.token)
                    }
                }
            }
        }
        
        reciverViewController!.onRejected = { [weak self] in
            self?.update(state: .reject)
        }
        
        reciverViewController!.onHungup = { [weak self] duration in
            self?.update(state: .hangup, duration: duration)
        }
        
        reciverViewController!.onBeHungup = { [weak self] duration in
            self?.update(state: .beHangup, duration: duration)
        }
    }
    
    deinit {
    }
    
    public func startLiveChat(inviterID: String = OIMManager.manager.getLoginUserID(),
                              othersID: [String],
                              isVideo: Bool = true,
                              incoming: Bool = false) {
        
        if !incoming {
            setupSenderViewController()
            
            invite(othersID: othersID, isVideo: isVideo) { [weak self] canStart in
                guard let self, canStart else { return }
                
                getUsersInfo([inviterID] + othersID) { [weak self] r in
                    guard let `self` else { return }
                    
                    self.inviter = r.first
                    self.others = r.suffix(r.endIndex)
                    self.senderViewController!.startLiveChat(inviter: { [weak self] in
                        
                        guard let `self` else { return [] }
                        return [self.inviter!]
                    }, others: { [weak self] in
                        
                        guard let `self` else { return [] }
                        return self.others!
                    }, isVideo: isVideo)
                }
            }
        } else {
            setupReciverViewController()
            getUsersInfo([inviterID] + othersID) { [weak self] r in
                guard let `self` else { return }
                self.inviter = r.first
                self.others = Array(r.dropFirst())
                self.reciverViewController?.startLiveChat(inviter: { [weak self] in
                    
                    guard let `self` else { return [] }
                    return [self.inviter!]
                }, others: { [weak self] in
                    
                    guard let `self` else { return [] }
                    return self.others!
                }, isVideo: isVideo)
            }
            
        }
    }
    
    public func startLiveChat(inviter: CallingUserInfo = CallingUserInfo(userID: OIMManager.manager.getLoginUserID()),
                              others: [CallingUserInfo],
                              isVideo: Bool = true,
                              incoming: Bool = false) {

        self.inviter = inviter
        self.others = others
        
        if !incoming {
            setupSenderViewController()
            
            invite(othersID: others.map({$0.userID}), isVideo: isVideo) { [weak self] canStart in
                guard let self, canStart else { return }
                
                senderViewController!.startLiveChat(inviter: {
                    return [inviter]
                }, others: { [weak self] in
                    guard let self else { return [] }
                    return self.others!
                }, isVideo: isVideo)
            }
        } else {
            setupReciverViewController()
            self.reciverViewController!.startLiveChat(inviter: {
                return [inviter]
            }, others: {
                return others
            }, isVideo: isVideo)
        }
    }
    
    private func invite(othersID: [String], isVideo: Bool, groupID: String? = nil, completion: @escaping ((Bool) -> Void)) {
        let info = OIMInvitationInfo()
        info.inviterUserID = OIMManager.manager.getLoginUserID()
        info.inviteeUserIDList = othersID
        info.mediaType = isVideo ? "video" : "audio"
        info.roomID = info.inviterUserID
        info.sessionType = OIMConversationType(rawValue: 1)!
        
        var offlinePushInfo = OIMOfflinePushInfo()
        
        if let groupID, !groupID.isEmpty {
            offlinePushInfo.title = "Someone invited you to a group chat."
        }
        
        signalingInfo = OIMSignalingInfo()
        signalingInfo?.userID = OIMManager.manager.getLoginUserID()
        signalingInfo?.invitation = info
        sendSinglingMessage(type: 200, data: info.mj_keyValues() as! [String : Any], recvID: othersID[0])
        completion(true)
    }
    
    private func getUsersInfo(_ usersID: [String], callback: @escaping ([CallingUserInfo]) -> Void) {
        
        OIMManager.manager.getUsersInfo(usersID) { infos in
            guard let infos else {
                callback([])
                return
            }
            
            let us = infos.map { info in
                var u = CallingUserInfo()
                u.nickname = info.nickname ?? info.userID!
                u.faceURL = info.faceURL
                u.userID = info.userID!
                return u
            }
            
            callback(us)
        }
    }
    
    private func sendSinglingMessage(type: Int, data: [String: Any], recvID: String) {
        let data = ["customType": type, "data": data] as [String : Any]
        let json = try? JSONSerialization.data(withJSONObject: data, options: .fragmentsAllowed)
        let jsonStr = String(data: json!, encoding: .utf8)
        
        let message = OIMMessageInfo.createCustomMessage(jsonStr!, extension: nil, description: nil)
        let offlinePush = OIMOfflinePushInfo()
        offlinePush.title = "Someone invited you."
        offlinePush.desc = "Someone invited you."
        
        OIMManager.manager.sendMessage(message,
                                       recvID: recvID,
                                       groupID: nil,
                                       offlinePushInfo: offlinePush) { msg in
            print("msg:\(msg)")

        } onProgress: { _ in
            
        } onFailure: { code, msg in
            print("code:\(code), msg:\(msg)")
        }
    }
}

extension CallingManager {
    private func update(state: CallingState, duration: Int = 0) {
        
        if state == .beAccepted || state == .disConnect {
            if state == .beAccepted {
                Task {
                    let certificate = await getTokenForRTC(roomID: signalingInfo!.invitation.roomID, userID: OIMManager.manager.getLoginUserID())
                    
                    if let liveURL = certificate?.liveURL, let token = certificate?.token {
                        await senderViewController?.connectRoom(liveURL: liveURL, token: token)
                    }
                }
            }
            return
        }
        
        reciverViewController?.dismiss()
        reciverViewController = nil
        senderViewController?.dismiss()
        senderViewController = nil
    }
}

// MARK: Listener

extension CallingManager: OIMAdvancedMsgListener {
    
    public func onRecvNewMessage(_ message: OIMMessageInfo) {        
        if message.contentType == .custom, let dataStr = message.customElem?.data {
            var data = try! JSONSerialization.jsonObject(with: dataStr.data(using: .utf8)!) as! [String: Any]
            let customType = data["customType"] as! Int
            let userID = data["userID"] as? String
            
            data = data["data"] as! [String: Any]
            
            
            if (customType == 200 ||
                customType == 201 ||
                customType == 202 ||
                customType == 203 ||
                customType == 204) {
                
                let invitation = OIMInvitationInfo()
                invitation.inviterUserID = data["inviterUserID"] as! String
                invitation.roomID = data["roomID"] as? String ?? ""
                invitation.timeout = data["timeout"] as? Int ?? 0
                invitation.mediaType = data["mediaType"] as! String
                invitation.sessionType = .C2C
                invitation.platformID = OIMPlatform(rawValue: (data["platformID"] as! NSNumber).intValue)!
                
                let signaling = OIMSignalingInfo()
                signaling.userID = userID ?? ""
                signaling.invitation = invitation

                switch (customType) {
                case 200:
                    CallingManager.manager.onReceiveNewInvitation(signaling)
                    break;
                case 201:
                    CallingManager.manager.onInviteeAccepted(signaling)
                    break;
                case 202:
                    CallingManager.manager.onInviteeRejected(signaling)
                    break;
                case 203:
                    CallingManager.manager.onInvitationCancelled(signaling)
                    break;
                case 204:
                    CallingManager.manager.onHunguUp(signaling)
                    break;
                default:
                    break
                }
            }
        }
    }
    
    public func onReceiveNewInvitation(_ signalingInfo: OIMSignalingInfo) {
        self.signalingInfo = signalingInfo
        startLiveChat(inviterID: signalingInfo.invitation.inviterUserID,
                      othersID: signalingInfo.invitation.inviteeUserIDList,
                      isVideo: signalingInfo.isVideo,
                      incoming: true)
    }
    
    public func onInviteeAccepted(_ signalingInfo: OIMSignalingInfo) {
        print("Accepted：\(signalingInfo)")
        self.signalingInfo = signalingInfo
        update(state: .beAccepted)
    }
    
    public func onInviteeRejected(_ signalingInfo: OIMSignalingInfo) {
        print("Rejected：\(signalingInfo)")
        self.signalingInfo = signalingInfo

        update(state: .beRejected)
    }
    
    public func onInvitationCancelled(_ signalingInfo: OIMSignalingInfo) {
        print("Cancelled：\(signalingInfo)")
        self.signalingInfo = signalingInfo
        update(state: .beCanceled)
    }
    
    public func onInvitationTimeout(_ signalingInfo: OIMSignalingInfo) {
        print("Timeout：\(signalingInfo)")
        self.signalingInfo = signalingInfo
       
        update(state: .noReply)
    }
    
    public func onHunguUp(_ signalingInfo: OIMSignalingInfo) {
        print("HunguUp：\(signalingInfo)")
        self.signalingInfo = signalingInfo

        var duration = (senderViewController?.duration ?? reciverViewController?.duration) ?? 0
        update(state: .beHangup, duration: duration)
    }
}

extension OIMSignalingInfo {
    var isSignal: Bool {
        true
    }
    
    var isVideo: Bool {
        return invitation.isVideo()
    }
}

extension Array {
    static func toJson<T: Encodable>(fromObject: T) -> String {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(fromObject)
            guard let json = String(data: data, encoding: .utf8) else {
                fatalError("check your data is encodable from utf8!")
            }
            return json
        } catch let err {
            return ""
        }
    }
}
