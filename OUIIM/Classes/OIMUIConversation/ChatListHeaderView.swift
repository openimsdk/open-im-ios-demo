
import OUICore

class ChatListHeaderView: UIView {
    
    private var preConnectionStatus = ConnectionStatus.connected
    private var statusChangeInterval = Date().timeIntervalSince1970
    
    let avatarImageView: AvatarView = {
        let v = AvatarView()
        return v
    }()

    let companyNameLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 12)
        v.textColor = StandardUI.color_333333
        return v
    }()

    let nameLabel: UILabel = {
        let v = UILabel()
        v.font = .f17
        v.textColor = .c0C1C33
        
        return v
    }()

    lazy var statusLabel: StatusLabelView = {
        let v = StatusLabelView()
        return v
    }()
    
    let addBtn: UIButton = {
        let v = UIButton()
        v.setImage(UIImage(nameInBundle: "chat_add_btn_icon"), for: .normal)
        return v
    }()
    
    lazy var connectionIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.startAnimating()
        
        return v
    }()
    
    lazy var errorImageView: UIImageView = {
        let v = UIImageView(image: UIImage(systemName: "exclamationmark.circle"))
        v.tintColor = .cFF381F
        v.isHidden = true
        
        return v
    }()
    
    lazy var connectionLabel: UILabel = {
        let t = UILabel()
        t.font = .f12
        t.text = "连接中"
        t.textColor = .c0089FF
        
        return t
    }()
    
    // 链接状态view
    lazy var connectionView: UIView = {
        let t = UIView()
        t.layer.masksToBounds = true
        t.layer.cornerRadius = StandardUI.cornerRadius

        t.backgroundColor = .c0089FF.withAlphaComponent(0.15)
        let horSV = UIStackView.init(arrangedSubviews: [errorImageView, connectionIndicator, connectionLabel])
        horSV.spacing = 4
        horSV.alignment = .center
        t.addSubview(horSV)
        
        horSV.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview()
        }
        
        return t
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .tertiarySystemBackground
        
        addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview()
        }

        let hStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [nameLabel, connectionView])
            v.axis = .horizontal
            v.spacing = 12
            v.alignment = .center
            return v
        }()

        addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(10)
            make.centerY.equalTo(avatarImageView)
        }
        
        connectionView.snp.makeConstraints { make in
            make.height.equalTo(25)
        }

        let btnStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [addBtn])

            addBtn.snp.makeConstraints { make in
                make.size.equalTo(30)
            }
            v.axis = .horizontal
            v.distribution = .equalSpacing
            v.spacing = 16
            return v
        }()
        addSubview(btnStack)
        btnStack.snp.makeConstraints { make in
            make.centerY.equalTo(avatarImageView)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        snp.makeConstraints { make in
            make.height.equalTo(kStatusBarHeight + 60)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func showConnectionView(_ show: Bool) {
        show ? connectionIndicator.startAnimating() : connectionIndicator.stopAnimating()
        connectionView.snp.updateConstraints { make in
            make.height.equalTo(show ? 25 : 0)
        }
        
        UIView.animate(withDuration: 0.3, animations: {[weak self] in
            self?.connectionView.layoutIfNeeded()
        }, completion: { [weak self] _ in
            self?.connectionView.isHidden = !show
        })
    }

    func updateConnectionStatus(status: ConnectionStatus) {
        
        if status != preConnectionStatus {
            // 如果状态发生变更，展示出来
            showConnectionView(status != .syncComplete && status != .connected)
        }
        
        let now = Date().timeIntervalSince1970
        // 间隔两秒刷新一次UI
        if now - statusChangeInterval > 2 {
            switch status {
            case .connectFailure, .syncFailure:
                connectionLabel.text = status.title
                connectionLabel.textColor = StandardUI.color_F44038
                connectionIndicator.isHidden = true
                errorImageView.isHidden = false
                connectionView.backgroundColor = StandardUI.color_FF381F.withAlphaComponent(0.15)
                break
            case .connecting, .connected, .syncStart, .syncComplete:
                connectionLabel.text = status.title
                connectionLabel.textColor = StandardUI.color_0089FF
                errorImageView.isHidden = true
                connectionIndicator.isHidden = false
                connectionView.backgroundColor = StandardUI.color_0089FF.withAlphaComponent(0.15)
                break
            case .kickedOffline:
                break
            }
            statusChangeInterval = now
        }
        preConnectionStatus = status
    }
}
