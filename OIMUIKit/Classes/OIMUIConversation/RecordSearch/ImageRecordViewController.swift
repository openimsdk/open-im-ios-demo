
import RxCocoa
import RxDataSources
import RxSwift
import SnapKit
import UIKit

class ImageRecordViewController: UIViewController {
    private lazy var contentCollectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = {
            let v = UICollectionViewFlowLayout()
            let itemWidth = kScreenWidth / 4
            v.itemSize = CGSize(width: itemWidth, height: itemWidth)
            v.minimumLineSpacing = 0
            v.minimumInteritemSpacing = 0
            v.scrollDirection = .vertical
            v.headerReferenceSize = CGSize(width: kScreenWidth, height: 48)
            return v
        }()
        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.backgroundColor = .white
        v.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.className)
        v.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.className)
        return v
    }()

    private let _viewModel: SearchRecordViewModel
    private let _disposeBag = DisposeBag()
    private let _viewType: ResultViewType
    private lazy var _photoHelper = PhotoHelper()
    init(viewModel: SearchRecordViewModel, viewType: ResultViewType) {
        _viewModel = viewModel
        _viewType = viewType
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(contentCollectionView)
        contentCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        bindData()

        switch _viewType {
        case .image:
            navigationItem.title = "图片".innerLocalized()
            _viewModel.searchImages()
        case .video:
            navigationItem.title = "视频".innerLocalized()
            _viewModel.searchVideos()
        }
    }

    private func bindData() {
        let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, MessageInfo>>.init(configureCell: { (_: CollectionViewSectionedDataSource<SectionModel>, colView: UICollectionView, indexPath: IndexPath, item: MessageInfo) -> UICollectionViewCell in
            let cell = colView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.className, for: indexPath) as! ImageCollectionViewCell
            cell.imageView.setImage(with: item.pictureElem?.snapshotPicture?.url, placeHolder: nil)
            return cell
        }, configureSupplementaryView: { (ds: CollectionViewSectionedDataSource<SectionModel>, colView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView in
            let header = colView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.className, for: indexPath) as! SectionHeaderView
            let title = ds[indexPath.section].model
            header.titleLabel.text = title
            return header
        })

        let messagesRelay: BehaviorRelay<[SearchRecordViewModel.MediaSectionModel]>
        switch _viewType {
        case .image:
            messagesRelay = _viewModel.imagesRelay
        case .video:
            messagesRelay = _viewModel.videosRelay
        }

        messagesRelay.bind(to: contentCollectionView.rx.items(dataSource: dataSource)).disposed(by: _disposeBag)

        contentCollectionView.rx.modelSelected(MessageInfo.self).subscribe(onNext: { [weak self] (message: MessageInfo) in
            guard let sself = self else { return }
            self?._photoHelper.preview(message: message, from: sself)
        }).disposed(by: _disposeBag)
    }

    enum ResultViewType {
        case image
        case video
    }
}

extension ImageRecordViewController {
    class ImageCollectionViewCell: UICollectionViewCell {
        let imageView: UIImageView = {
            let v = UIImageView()
            v.backgroundColor = StandardUI.color_D8D8D8
            v.layer.borderColor = StandardUI.color_999999.cgColor
            v.layer.borderWidth = 1
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

    class SectionHeaderView: UICollectionReusableView {
        let titleLabel: UILabel = {
            let v = UILabel()
            v.font = UIFont.systemFont(ofSize: 16)
            v.textColor = StandardUI.color_333333
            return v
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.left.bottom.equalToSuperview().inset(10)
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
