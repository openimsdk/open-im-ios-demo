
import RxSwift
import UIKit

class GroupChatMemberTableViewCell: UITableViewCell {
    var disposeBag = DisposeBag()
    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 13)
        return v
    }()

    let countLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 13)
        v.textColor = StandardUI.color_999999
        return v
    }()

    lazy var memberCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let maxCount: CGFloat = 7
        let itemWidth: CGFloat = (kScreenWidth - StandardUI.margin_22 * 2 - 10 * (maxCount - 1)) / maxCount
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 6
        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.className)
        v.contentInset = UIEdgeInsets(top: 0, left: StandardUI.margin_22, bottom: 0, right: StandardUI.margin_22)
        v.backgroundColor = .white
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(StandardUI.margin_22)
            make.top.equalToSuperview().offset(12)
        }

        let arrowImageView = UIImageView(image: UIImage(nameInBundle: "common_arrow_right"))
        contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-StandardUI.margin_22)
            make.centerY.equalTo(titleLabel)
        }

        contentView.addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.right.equalTo(arrowImageView.snp.left).offset(-6)
            make.centerY.equalTo(titleLabel)
        }

        contentView.addSubview(memberCollectionView)
        memberCollectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.height.equalTo(42)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class ImageCollectionViewCell: UICollectionViewCell {
        let imageView: UIImageView = {
            let v = UIImageView()
            v.layer.cornerRadius = 4
            v.clipsToBounds = true
            return v
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            contentView.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}
