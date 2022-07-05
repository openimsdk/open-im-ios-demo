
import UIKit

class SearchResultView: UIView {
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 14)
        v.textColor = StandardUI.color_333333
        return v
    }()

    let tap = UITapGestureRecognizer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        let imageView: UIImageView = {
            let v = UIImageView(image: UIImage(nameInBundle: "contacts_search_result_icon"))
            v.setContentHuggingPriority(.required, for: .horizontal)
            v.setContentCompressionResistancePriority(.required, for: .horizontal)
            return v
        }()
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(StandardUI.margin_22)
            make.centerY.equalToSuperview()
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(imageView.snp.right).offset(6)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-18)
        }

        addGestureRecognizer(tap)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String?) {
        guard let title = title else {
            return
        }

        titleLabel.text = "搜索：" + title
    }
}
