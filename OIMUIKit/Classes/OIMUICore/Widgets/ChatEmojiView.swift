

    
    

import UIKit

protocol ChatEmojiViewDelegate: AnyObject {
    func emojiViewDidSelect(emojiStr: String)
}

class ChatEmojiView: UIView {
    
    weak var delegate: ChatEmojiViewDelegate?
    
    private let emojis: [String] = [
        "[亲亲]",
        "[看穿]",
        "[色]",
        "[吓哭]",
        "[笑脸]",
        "[眨眼]",
        "[搞怪]",
        "[龇牙]",
        "[无语]",
        "[可怜]",
        "[咒骂]",
        "[晕]",
        "[尴尬]",
        "[暴怒]",
        "[可爱]",
        "[哭泣]"
    ]
    
    override var backgroundColor: UIColor? {
        didSet {
            collectionView.backgroundColor = backgroundColor
        }
    }

    private lazy var collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = {
            let v = UICollectionViewFlowLayout()
            v.minimumInteritemSpacing = 28
            v.minimumLineSpacing = 28
            v.scrollDirection = .vertical
            v.sectionInset = .zero
            v.itemSize = CGSize.init(width: 32, height: 32)
            return v
        }()
        let v = UICollectionView.init(frame: .zero, collectionViewLayout: layout)
        v.showsVerticalScrollIndicator = false
        v.showsHorizontalScrollIndicator = false
        v.register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.className)
        v.contentInset = UIEdgeInsets.init(top: StandardUI.margin_22, left: StandardUI.margin_22, bottom: kSafeAreaBottomHeight, right: StandardUI.margin_22)
        v.backgroundColor = .white
        v.dataSource = self
        v.delegate = self
        return v
    }()
    
    let deleteBtn: UIButton = {
        let v = UIButton()
        v.setImage(UIImage.init(nameInBundle: "inputbar_pad_delete_btn_icon"), for: .normal)
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.addSubview(deleteBtn)
        deleteBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(StandardUI.margin_22)
            make.bottom.equalToSuperview().inset(kSafeAreaBottomHeight)
            make.size.equalTo(32)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class EmojiCell: UICollectionViewCell {
        let imageView: UIImageView = {
            let v = UIImageView()
            return v
        }()
        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}


extension ChatEmojiView: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCell.className, for: indexPath) as! EmojiCell
        let key = emojis[indexPath.row]
        if let emojiName = ChatEmojiHelper.emojiMap[key] {
            cell.imageView.image = UIImage.init(nameInEmoji: emojiName)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emojiName = emojis[indexPath.row]
        delegate?.emojiViewDidSelect(emojiStr: emojiName)
    }
}

class ChatEmojiHelper {
    static let emojiMap: [String: String] = [
        "[亲亲]": "ic_face_01",
        "[看穿]": "ic_face_02",
        "[色]": "ic_face_03",
        "[吓哭]": "ic_face_04",
        "[笑脸]": "ic_face_05",
        "[眨眼]": "ic_face_06",
        "[搞怪]": "ic_face_07",
        "[龇牙]": "ic_face_08",
        "[无语]": "ic_face_09",
        "[可怜]": "ic_face_10",
        "[咒骂]": "ic_face_11",
        "[晕]": "ic_face_12",
        "[尴尬]": "ic_face_13",
        "[暴怒]": "ic_face_14",
        "[可爱]": "ic_face_15",
        "[哭泣]": "ic_face_16",
    ]
}
