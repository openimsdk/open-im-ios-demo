
import RxSwift
import UIKit

class SingleChatMemberTableViewCell: UITableViewCell {
    var disposeBag = DisposeBag()

    lazy var memberCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: 60, height: 90)
        layout.scrollDirection = .horizontal
        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        v.register(MemberCell.self, forCellWithReuseIdentifier: MemberCell.className)
        v.backgroundColor = .white
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(memberCollectionView)
        memberCollectionView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(90)
            make.bottom.equalToSuperview().offset(-10).priority(.low)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    class MemberCell: UICollectionViewCell {
        let avatarImageView: UIImageView = {
            let v = UIImageView()
            v.layer.cornerRadius = 6
            v.clipsToBounds = true
            return v
        }()

        let nameLabel: UILabel = {
            let v = UILabel()
            v.font = UIFont.systemFont(ofSize: 14)
            v.textColor = StandardUI.color_666666
            v.textAlignment = .center
            return v
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            contentView.addSubview(avatarImageView)
            avatarImageView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.size.equalTo(48)
                make.centerX.equalToSuperview()
            }

            contentView.addSubview(nameLabel)
            nameLabel.snp.makeConstraints { make in
                make.top.equalTo(avatarImageView.snp.bottom).offset(14)
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().priority(.low)
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
