import InputBarAccessoryView
import OUICore

public enum PadItemType: CaseIterable {
    case album
    case camera

    var name: String {
        switch self {
        case .album:
            return "相册".innerLocalized()
        case .camera:
            return "拍摄".innerLocalized()
        }
    }

    var image: UIImage? {
        let imageName: String
        switch self {
        case .album:
            imageName = "inputbar_pad_album_icon"
        case .camera:
            imageName = "inputbar_pad_camera_icon"
        }
        return UIImage(nameInBundle: imageName)
    }
}

public protocol InputPadViewDelegate: AnyObject {
    func didSelect(type: PadItemType)
}

class InputPadView: UIView, InputItem {
    var inputBarAccessoryView: InputBarAccessoryView?
    var parentStackViewPosition: InputStackView.Position?
    
    func textViewDidChangeAction(with textView: InputTextView) {
        
    }
    
    func keyboardSwipeGestureAction(with gesture: UISwipeGestureRecognizer) {
        
    }
    
    func keyboardEditingEndsAction() {
        
    }
    
    func keyboardEditingBeginsAction() {
        
    }
    
    func setSize(_ newValue: CGSize?, animated: Bool) {
        size = newValue
    }

    private var size: CGSize? = CGSize(width: UIScreen.main.bounds.width, height: 160) {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    open override var intrinsicContentSize: CGSize {
        var contentSize = size ?? super.intrinsicContentSize
        contentSize.height += 20
        return contentSize
    }
    
    public weak var delegate: InputPadViewDelegate?
    
    // 每行要展示的 item 数量
    private let itemsPerRow = 4
    private let items: [PadItemType] = PadItemType.allCases
    
    private lazy var collectionView: UICollectionView = {
        
        var layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: intrinsicContentSize.width / CGFloat(itemsPerRow) - 30, height: 90.0)
        layout.minimumLineSpacing = 16

        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.showsVerticalScrollIndicator = false
        v.showsHorizontalScrollIndicator = false
        v.register(ItemCell.self, forCellWithReuseIdentifier: ItemCell.className)
        v.backgroundColor = .clear
        
        v.dataSource = self
        v.delegate = self
        
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground

        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class ItemCell: UICollectionViewCell {
    let imageView: UIImageView = {
        let v = UIImageView()
        return v
    }()

    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .f12
        v.textColor = .c0C1C33
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let vStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [UIView(), imageView, titleLabel])
            v.axis = .vertical
            v.alignment = .center
            v.spacing = 8
            
            return v
        }()
        
        contentView.addSubview(vStack)
        vStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            vStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            vStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            vStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension InputPadView: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
    
        let count = items.count
        
        return count % itemsPerRow == 0 ? count / itemsPerRow : count / itemsPerRow + 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
        let count = items.count - section * itemsPerRow

        return count / itemsPerRow == 0 ? count % itemsPerRow : itemsPerRow
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ItemCell.className, for: indexPath) as! ItemCell
        
        let index = indexPath.section * itemsPerRow + indexPath.row
        let item = items[index]

        cell.imageView.image = item.image
        cell.titleLabel.text = item.name
        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.section * itemsPerRow + indexPath.row
        let item = items[index]
        delegate?.didSelect(type: item)
    }
}
