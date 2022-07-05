
import RxSwift
import UIKit

class SingleChatRecordTableViewCell: UITableViewCell {
    var disposeBag = DisposeBag()

    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 16)
        v.textColor = StandardUI.color_333333
        return v
    }()

    let searchTextBtn: UpImageButton = {
        let v = UpImageButton()
        v.imageView.image = UIImage(nameInBundle: "setting_record_search_text_icon")
        v.titleLabel.text = "搜索".innerLocalized()
        return v
    }()

    let searchImageBtn: UpImageButton = {
        let v = UpImageButton()
        v.imageView.image = UIImage(nameInBundle: "setting_record_search_image_icon")
        v.titleLabel.text = "图片".innerLocalized()
        return v
    }()

    let searchVideoBtn: UpImageButton = {
        let v = UpImageButton()
        v.imageView.image = UIImage(nameInBundle: "setting_record_search_video_icon")
        v.titleLabel.text = "视频".innerLocalized()
        return v
    }()

    let searchFileBtn: UpImageButton = {
        let v = UpImageButton()
        v.imageView.image = UIImage(nameInBundle: "setting_record_search_file_icon")
        v.titleLabel.text = "文件".innerLocalized()
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(18)
            make.left.equalToSuperview().offset(StandardUI.margin_22)
        }

        let hStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [searchTextBtn, searchImageBtn, searchVideoBtn, searchFileBtn])
            v.spacing = 40
            v.distribution = .fillEqually
            return v
        }()
        contentView.addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(30)
            make.bottom.equalToSuperview().offset(-25)
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
}
