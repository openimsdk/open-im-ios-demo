
import AVFoundation
import Foundation
import LiveKitClient
import RxSwift
import SnapKit
import ProgressHUD
import OUICore

public class CallingSenderController: CallingBaseController {
    
    private var signal: SignalViewController?
    private var isPresented: Bool = false

    public var duration: Int {
        signal?.linkingDuration ?? 0
    }
    
    public override func connectRoom(liveURL: String, token: String) {
        signal?.connectRoom(liveURL: liveURL, token: token)
    }
    
    public override func dismiss() {
        isPresented = false
        signal?.dismiss()
    }
    
    public override func startLiveChat(inviter: @escaping UserInfoHandler,
                                       others: @escaping UserInfoHandler,
                                       isVideo: Bool = true)
    {
        if isPresented {
            return
        }
        isPresented = true
        
        signal = SignalViewController()
        signal!.inviter = inviter
        signal!.users = others
        signal!.isVideo = isVideo
        signal!.onCancel = onCancel
        signal!.onHungup = onHungup
        signal!.onDisconnect = onDisconnect
        signal!.onConnectFailure = onConnectFailure
        signal!.onInvitedOthers = onInvitedOthers
        
        signal!.modalPresentationStyle = .overCurrentContext
        UIViewController.currentViewController().present(signal!, animated: true)
    }
}

class SignalViewController: CallingBaseViewController {
    private var verStackView: UIStackView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playSounds()
        setupView()
        room.add(delegate: self)
    }
    
    func setupView() {
        tipsLabel.text = "waitingVoiceCallHint".innerLocalized()
        let inviter = users().first
        let avatarView = AvatarView()
        avatarView.setAvatar(url: inviter?.faceURL, text: inviter?.nickname)
        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(70)
        }
        
        let nameLabel = UILabel()
        nameLabel.layer.cornerRadius = 6
        nameLabel.layer.masksToBounds = true
        nameLabel.text = inviter?.nickname
        nameLabel.font = .systemFont(ofSize: 28)
        nameLabel.textAlignment = .center
        nameLabel.textColor = .white
        
        if !isVideo {
            let infoStackView = UIStackView(arrangedSubviews: [avatarView, nameLabel, tipsLabel])
            infoStackView.axis = .vertical
            infoStackView.spacing = 24
            infoStackView.alignment = .center
            
            verStackView = UIStackView(arrangedSubviews: [infoStackView, UIView()])
        } else {
            let infoStackView = UIStackView(arrangedSubviews: [nameLabel, tipsLabel])
            infoStackView.axis = .vertical
            infoStackView.distribution = .equalSpacing
            infoStackView.alignment = .leading
            
            let rowStackView = UIStackView(arrangedSubviews: [SizeBox(width: 24), avatarView, infoStackView, SizeBox(width: 24)])
            rowStackView.axis = .horizontal
            rowStackView.spacing = 8
            
            verStackView = UIStackView(arrangedSubviews: [rowStackView, UIView()])
        }
        
        verStackView!.axis = .vertical
        verStackView!.distribution = .equalSpacing
        view.addSubview(verStackView!)
        
        verStackView!.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(minimizeButton.snp_bottom).offset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        insertLinkingViewAbove(aboveView: verStackView!)
        senderPreviewFuncButtons()
    }
}

extension SignalViewController: RoomDelegate {
    func room(_ room: Room, didUpdate connectionState: ConnectionState, oldValue: ConnectionState) {
        print("connection state did update")
        DispatchQueue.main.async { [self] in
            if case .disconnected = connectionState {
                self.cameraTrackState = .notPublished()
                self.microphoneTrackState = .notPublished()
                
                if let error = connectionState.disconnectedWithError {
                    self.onConnectFailure?()
                    self.dismiss()
                }
            }
        }
    }
    
    func room(_ room: Room, localParticipant: LocalParticipant, didPublish publication: LocalTrackPublication) {
        guard let track = publication.track as? VideoTrack else {
            print("sender did publish track return")
            return
        }
        
        DispatchQueue.main.async { [self] in
            self.smallVideoView.track = track
        }
    }
    
    func room(_ room: Room, participantDidJoin participant: RemoteParticipant) {
        print("participant did join")
    }
    
    func room(_ room: Room, participantDidLeave participant: RemoteParticipant) {
        print("participant did leave")
    }
    
    public func room(_ room: Room, participant: RemoteParticipant, didSubscribe publication: RemoteTrackPublication, track: Track) {
        DispatchQueue.main.async { [self] in
            if isVideo {
                if let track = track as? VideoTrack {
                    bigVideoView.track = track
                }
                verStackView?.isHidden = true
                onlineFuncButtons()
            }
            linkingTimer()
            showLinkingView(show: false)
        }
    }
    
    func room(_ room: Room, participant: RemoteParticipant, didUnsubscribe publication: RemoteTrackPublication, track: Track) {
        if linkedTimer != nil, participant.identity == users().last?.userID {
            linkedTimer = nil
        }
    }
    
    func room(_ room: Room, participant: Participant, didUpdate publication: TrackPublication, muted: Bool) {
        print("\(#function) muted \(String(describing: participant.showName)) - \(publication.kind) status:\(!muted)")
        if publication.kind == .video {
            DispatchQueue.main.async { [self] in
                let participantUser = CallingUserInfo(userID: participant.identity, nickname: participant.showName, faceURL: participant.faceURL)
                
                if let user = users().first, participant.identity == user.userID {
                    remoteMuted = muted
                    
                    if smallViewIsMe {
                        bigDisableVideoImageView.isHidden = !muted
                        setupBigPlaceholerView(user: participantUser)
                    } else {
                        smallDisableVideoImageView.isHidden = !muted
                        setupSmallPlaceholerView(user: participantUser)
                    }
                } else if let user = inviter().first, participant.identity == user.userID {
                    localMuted = muted
                    
                    if smallViewIsMe {
                        smallDisableVideoImageView.isHidden = !muted
                        setupSmallPlaceholerView(user: participantUser)
                    } else {
                        bigDisableVideoImageView.isHidden = !muted
                        setupBigPlaceholerView(user: participantUser)
                    }
                }
            }
        }
    }
}
