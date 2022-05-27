





import UIKit
import SnapKit
import RxSwift

class OptionTableViewCell: UITableViewCell {
    
    var disposeBag = DisposeBag()
    
    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 18)
        v.textColor = StandardUI.color_333333
        v.setContentHuggingPriority(.required, for: .horizontal)
        v.setContentCompressionResistancePriority(.required, for: .horizontal)
        return v
    }()
    
    let subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 16)
        v.textColor = StandardUI.color_999999
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.accessoryType = .disclosureIndicator
        self.selectionStyle = .none
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(StandardUI.margin_22)
            make.centerY.equalToSuperview()
        }
        
        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(10)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        accessoryType = .disclosureIndicator
        subtitleLabel.text = nil
        disposeBag = DisposeBag()
    }
}
