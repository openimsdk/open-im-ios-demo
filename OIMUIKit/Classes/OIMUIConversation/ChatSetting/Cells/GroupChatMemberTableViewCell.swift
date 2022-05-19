//






import UIKit

class GroupChatMemberTableViewCell: UITableViewCell {
    
    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 13)
        return v
    }()
    
    private let countLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 13)
        v.textColor = StandardUI.color_999999
        return v
    }()
    
    private lazy var memberCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize.init(width: StandardUI.avatar_42, height: StandardUI.avatar_42)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 6
        let v = UICollectionView.init(frame: .zero, collectionViewLayout: layout)
        v.contentInset = UIEdgeInsets.init(top: 0, left: StandardUI.margin_22, bottom: 0, right: 0)
        v.backgroundColor = .purple
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(StandardUI.margin_22)
            make.top.equalToSuperview().offset(12)
        }
        
        let arrowImageView = UIImageView.init(image: UIImage.init(nameInBundle: "common_arrow_right"))
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
