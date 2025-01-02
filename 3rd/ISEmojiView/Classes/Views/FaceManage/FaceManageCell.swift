






import UIKit

class FaceManageCell: UICollectionViewCell {
    var imageView: UIImageView!
    var deleteButton: UIButton!
    
    var selectedButtonTappedHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    private func setupViews() {

        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        deleteButton = UIButton(type: .custom)
        deleteButton.tintColor = .white
        deleteButton.setImage(UIImage(systemName: "circle"), for: .normal)
        deleteButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        contentView.addSubview(deleteButton)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            deleteButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 30),
            deleteButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc private func deleteButtonTapped(_ sender: UIButton) {


        sender.isSelected = !sender.isSelected
        selectedButtonTappedHandler?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        deleteButton.isSelected = false
    }
}

