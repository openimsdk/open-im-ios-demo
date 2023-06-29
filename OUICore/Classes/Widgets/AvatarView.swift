
import Foundation
import UIKit
import RxSwift

public class AvatarView: UIView {
    
    private var disposeBag = DisposeBag()
    
    private let indexAvatarList = [
        "ic_avatar_01",
        "ic_avatar_02",
        "ic_avatar_03",
        "ic_avatar_04",
        "ic_avatar_05",
        "ic_avatar_06"
      ]
    
    let avatarImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleToFill
        v.isUserInteractionEnabled = true
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .c0089FF
        
        return v
    }()
    
    let textLabel: UILabel = {
        let v = UILabel()
        v.textAlignment = .center
        v.textColor = .white
        v.font = .f12
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 6
        clipsToBounds = true
        
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        
        addSubview(avatarImageView)
        addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            avatarImageView.topAnchor.constraint(equalTo: topAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            textLabel.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor)
        ])
        
        let width = avatarImageView.widthAnchor.constraint(equalToConstant: 44)
        width.priority = UILayoutPriority(999)
        width.isActive = true
        let height = avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor, multiplier: 1)
        height.priority = UILayoutPriority(999)
        height.isActive = true
    }
    
    public func setAvatar(url: String?, text: String?, placeHolder: String = "contact_my_friend_icon", onTap: (()-> Void)? = nil) {
        
        reset()
        
        if let url = url, !url.isEmpty {
            if indexAvatarList.contains(url) {// 默认的图
                avatarImageView.image = .init(nameInBundle: url)
            } else {
                // 网络图
                avatarImageView.setImage(with: url, placeHolder: placeHolder)
            }
            avatarImageView.backgroundColor = .clear
        } else if var t = text {
            if t.length > 2 {
                t = t.subString(t.length - 2)
            }
            textLabel.text = t
        } else {
            avatarImageView.image = .init(nameInBundle: placeHolder)
            avatarImageView.backgroundColor = .clear
        }
        
        if onTap != nil {
            let tap = UITapGestureRecognizer()
            tap.rx.event.subscribe(onNext: { [weak self] _ in
                guard let sself = self else { return }
                onTap!()
            }).disposed(by: disposeBag)
            avatarImageView.addGestureRecognizer(tap)
        }
    }
    
    public func reset() {
        avatarImageView.image = nil
        avatarImageView.backgroundColor = .c0089FF
        textLabel.text = nil
    }
}
