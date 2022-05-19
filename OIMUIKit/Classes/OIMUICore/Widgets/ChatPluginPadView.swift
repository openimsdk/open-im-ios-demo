

    
    

import UIKit

protocol ChatPluginPadDelegate: AnyObject {
    func didSelect(plugin: PluginType)
}

class ChatPluginPadView: UIView {
        
    var itemSpacing: CGFloat = 0 {
        didSet {
            _layout.minimumInteritemSpacing = itemSpacing
        }
    }
    
    var lineSpacing: CGFloat = 0 {
        didSet {
            _layout.minimumLineSpacing = lineSpacing
        }
    }
    
    override var backgroundColor: UIColor? {
        didSet {
            collectionView.backgroundColor = backgroundColor
        }
    }
    
    weak var delegate: ChatPluginPadDelegate?

    lazy var collectionView: UICollectionView = {
        let v = UICollectionView.init(frame: .zero, collectionViewLayout: _layout)
        v.showsVerticalScrollIndicator = false
        v.showsHorizontalScrollIndicator = false
        v.register(PluginCell.self, forCellWithReuseIdentifier: PluginCell.className)
        v.contentInset = UIEdgeInsets.init(top: 20, left: 38, bottom: kSafeAreaBottomHeight, right: 38)
        v.backgroundColor = .white
        v.dataSource = self
        v.delegate = self
        return v
    }()
    
    private let _layout: UICollectionViewFlowLayout = {
        let v = UICollectionViewFlowLayout()
        v.minimumInteritemSpacing = 36
        v.minimumLineSpacing = 12
        v.scrollDirection = .vertical
        v.sectionInset = .zero
        v.itemSize = CGSize.init(width: 50, height: 70)
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let plugins: [PluginType] = PluginType.allCases
    
    class PluginCell: UICollectionViewCell {
        let imageView: UIImageView = {
            let v = UIImageView()
            return v
        }()
        let titleLabel: UILabel = {
            let v = UILabel()
            v.font = .systemFont(ofSize: 11)
            v.textColor = StandardUI.color_999999
            return v
        }()
        override init(frame: CGRect) {
            super.init(frame: frame)
            let vStack: UIStackView = {
                let v = UIStackView.init(arrangedSubviews: [imageView, titleLabel])
                v.axis = .vertical
                v.alignment = .center
                v.spacing = 2
                return v
            }()
            contentView.addSubview(vStack)
            vStack.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension ChatPluginPadView: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return plugins.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PluginCell.className, for: indexPath) as! PluginCell
        let item = plugins[indexPath.row]
        cell.imageView.image = item.image
        cell.titleLabel.text = item.name
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = plugins[indexPath.item]
        delegate?.didSelect(plugin: item)
    }
}

public enum PluginType: CaseIterable {
    case album
    case camera


    case businessCard


    
    var name: String {
        switch self {
        case .album:
            return "相册"
        case .camera:
            return "拍摄"
        case .businessCard:
            return "名片"
        }
    }
    var image: UIImage? {
        let imageName: String
        switch self {
        case .album:
            imageName = "inputbar_pad_album_icon"
        case .camera:
            imageName = "inputbar_pad_camera_icon"
        case .businessCard:
            imageName = "inputbar_pad_business_card_icon"
        }
        return UIImage.init(nameInBundle: imageName)
    }
}
