






import UIKit
import Kingfisher

class FaceManageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
        
    var faceEmojisCallback: (([FaceEmoji]) -> Void)?
    var faceEmojiAddCallback: ((((URL) -> Void)?) -> Void)?
    
    private let cellIdentifier = "ImageFaceManageCell"
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 60, height: 60)

        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(FaceManageCell.self, forCellWithReuseIdentifier: cellIdentifier)
        
        return collection
    }()
    
    private var isEditingMode = false
    private let faceManager = FaceManager.shared
    
    private lazy var editButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "编辑", style: .plain, target: self, action: #selector(toggleEditingMode))
    }()
    
    private lazy var dismissButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "关闭", style: .plain, target: self, action: #selector(dismissViewController))
    }()
    
    private lazy var totalFaceLabel: UILabel = {
        let v = UILabel()
        v.textColor = .systemGray5
        
        return v
    }()
    
    private var totalSelected: Int = 0 {
        didSet {
            deleteButton.setTitle("删除（\(totalSelected)）", for: .normal)
        }
    }
    
    private lazy var deleteButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("删除", for: .normal)
        v.addTarget(self, action: #selector(handleDeleteButtonTapped), for: .touchUpInside)
        
        return v
    }()
    
    lazy var bottomStack: UIStackView = {
        let v = UIStackView(arrangedSubviews: [totalFaceLabel, UIView(), deleteButton])
        v.axis = .horizontal
        v.spacing = 8
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = editButton
        navigationItem.leftBarButtonItem = dismissButton
        
        view.addSubview(bottomStack)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            bottomStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottomStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: bottomStack.topAnchor)
        ])
    }
    
    private func updateTotalItem() {
        totalFaceLabel.text = "共\(faceManager.images.count)个表情"
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return faceManager.images.count + 1 // Add 1 for the "Add Image" cell
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! FaceManageCell

        if indexPath.item == 0 {

            cell.imageView.image = UIImage(named: "ic_add_face", in: Bundle.podBundle,compatibleWith: nil)
            cell.deleteButton.isHidden = true
        } else {

            let imageIndex = indexPath.item - 1 // Adjust index to account for "Add Image" button
            if let localImagePath = faceManager.images[imageIndex].localImagePath,
                FaceManager.faceExists(path: localImagePath) {
                
                let image = UIImage(contentsOfFile: localImagePath)
                cell.imageView.image = image
            } else {
                let imageURL = faceManager.images[imageIndex].imageURL
                cell.imageView.kf.setImage(with: imageURL)
            }

            cell.deleteButton.isHidden = !isEditingMode

            cell.selectedButtonTappedHandler = { [weak self] in
                self?.handleSelectedButtonTapped(at: imageIndex)
            }
        }

        return cell
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isEditingMode else { return }
        
        if indexPath.item == 0 {



            handleAddImageButtonTapped()
        } else {
        }
    }
    
    private func handleSelectedButtonTapped(at index: Int) {

        if let first = faceManager.selectedImages.firstIndex(where: { $0.imageURL == faceManager.images[index].imageURL }) {
            faceManager.selectedImages.remove(at: first)
        } else {
            faceManager.selectedImages.append(faceManager.images[index])
        }
        
        totalSelected = faceManager.selectedImages.count
    }

    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let touchPoint = gesture.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: touchPoint) {

                if indexPath.item < faceManager.images.count {
                    faceManager.removeImage(at: indexPath.item)
                    collectionView.reloadData()
                }
            }
        }
    }
    
    @objc private func toggleEditingMode() {
        isEditingMode.toggle()
        bottomStack.isHidden = !isEditingMode
        editButton.title = isEditingMode ? "完成" : "编辑"
        collectionView.reloadData()
    }
    
    @objc private func dismissViewController() {
        faceManager.selectedImages.removeAll()
        faceManager.save()
        dismiss(animated: true)
    }
}

extension FaceManageViewController {

    @objc private func handleAddImageButtonTapped() {


        faceEmojiAddCallback?({ [weak self] url in
            guard let self else { return }
            
            faceManager.addImage(url) { [self] in
                self.updateTotalItem()
                self.faceEmojisCallback?(self.faceManager.images)
                self.collectionView.reloadData()
            }
        })
    }
    
    @objc private func handleEditButtonTapped() {

        toggleEditingMode()
    }
    
    @objc private func handleDeleteButtonTapped() {

        faceManager.images = faceManager.images.filter { element in
            !faceManager.selectedImages.contains(where: { $0.imageURL == element.imageURL })
        }
        faceEmojisCallback?(faceManager.images)
        collectionView.reloadData()
    }
}


