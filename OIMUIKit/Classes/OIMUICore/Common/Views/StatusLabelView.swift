
import UIKit

class StatusLabelView: UIView {
    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 12)
        v.textColor = StandardUI.color_333333
        return v
    }()

    let statusView: UIView = {
        let v = UIView()
        v.backgroundColor = .green
        v.layer.cornerRadius = 3
        v.clipsToBounds = true
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let stackView: UIStackView = {
            let v = UIStackView(arrangedSubviews: [statusView, titleLabel])
            statusView.snp.makeConstraints { make in
                make.size.equalTo(6)
            }
            v.axis = .horizontal
            v.distribution = .equalSpacing
            v.alignment = .center
            v.spacing = 4
            return v
        }()
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
