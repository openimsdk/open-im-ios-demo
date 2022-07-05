
import RxSwift
import UIKit

class ChatToolController: UICollectionViewController, UIPopoverPresentationControllerDelegate {
    let disposeBag = DisposeBag()
    init(sourceView: UIView, items: [ToolItem]) {
        let itemSize = CGSize(width: 35, height: 40)
        let lineSpacing = 10
        let itemSpacing = 5
        let leftRightInset = 16
        let topBottomInset = 0
        let layout: UICollectionViewFlowLayout = {
            let v = UICollectionViewFlowLayout()
            v.itemSize = itemSize
            v.minimumLineSpacing = CGFloat(lineSpacing)
            v.minimumInteritemSpacing = CGFloat(itemSpacing)
            v.scrollDirection = .vertical
            return v
        }()
        super.init(collectionViewLayout: layout)
        collectionView.register(ChatToolCell.self, forCellWithReuseIdentifier: ChatToolCell.className)
        collectionView.backgroundColor = StandardUI.color_666666
        collectionView.isScrollEnabled = false
        toolItems = items
        modalPresentationStyle = .popover
        let maxCountPerLine = 4
        let itemWidth = Int(itemSize.width)
        let itemHeight = Int(itemSize.height)
        let width: Int = items.count >= maxCountPerLine ? (itemWidth * maxCountPerLine + (maxCountPerLine - 1) * itemSpacing) : (items.count * itemWidth + (items.count - 1) * itemSpacing + leftRightInset * 2)
        let height: Int = items.count > maxCountPerLine ? (itemHeight * 2 + lineSpacing + topBottomInset * 2) : (itemHeight + topBottomInset * 2)
        preferredContentSize = CGSize(width: width, height: height)
        let popover = popoverPresentationController
        popover?.delegate = self
        popover?.sourceView = sourceView
        popover?.popoverBackgroundViewClass = CustomPopoverBackgroundView.self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    override func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return toolItems.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatToolCell.className, for: indexPath) as! ChatToolCell
        let item = toolItems[indexPath.item]
        cell.imageView.image = item.image
        cell.titleLabel.text = item.name
        return cell
    }

    var toolItems: [ToolItem] = ToolItem.allCases

    enum ToolItem: CaseIterable {
        case copy
        case delete
        case forward
        case reply
        case revoke
        case muiltSelection
        case translate

        var image: UIImage? {
            switch self {
            case .copy:
                return UIImage(nameInBundle: "chattool_copy_btn_icon")
            case .delete:
                return UIImage(nameInBundle: "chattool_delete_btn_icon")
            case .forward:
                return UIImage(nameInBundle: "chattool_forward_btn_icon")
            case .reply:
                return UIImage(nameInBundle: "chattool_reply_btn_icon")
            case .revoke:
                return UIImage(nameInBundle: "chattool_revoke_btn_icon")
            case .muiltSelection:
                return UIImage(nameInBundle: "chattool_multi_sel_btn_icon")
            case .translate:
                return UIImage(nameInBundle: "chattool_translate_btn_icon")
            }
        }

        var name: String {
            switch self {
            case .copy:
                return "复制".innerLocalized()
            case .delete:
                return "删除".innerLocalized()
            case .forward:
                return "转发".innerLocalized()
            case .reply:
                return "回复".innerLocalized()
            case .revoke:
                return "撤回".innerLocalized()
            case .muiltSelection:
                return "多选".innerLocalized()
            case .translate:
                return "翻译".innerLocalized()
            }
        }
    }

    class ChatToolCell: UICollectionViewCell {
        let imageView: UIImageView = {
            let v = UIImageView()
            return v
        }()

        let titleLabel: UILabel = {
            let v = UILabel()
            v.font = .systemFont(ofSize: 10)
            v.textColor = .white
            return v
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 18, height: 20))
                make.top.equalToSuperview().offset(3)
                make.centerX.equalToSuperview()
            }
            contentView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(imageView.snp.bottom).offset(3)
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
