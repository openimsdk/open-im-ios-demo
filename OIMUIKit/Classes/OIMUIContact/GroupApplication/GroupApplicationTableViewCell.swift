
import RxSwift
import UIKit

class GroupApplicationTableViewCell: UITableViewCell {
    var disposeBag = DisposeBag()

    let avatarImageView: UIImageView = {
        let v = UIImageView()
        return v
    }()

    let nameLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 16)
        v.textColor = StandardUI.color_333333
        return v
    }()

    private let applyInfoLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 12)
        v.textColor = StandardUI.color_666666
        return v
    }()

    private let applyReasonLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 12)
        v.textColor = StandardUI.color_666666
        v.numberOfLines = 3
        return v
    }()

    let agreeBtn: UIButton = {
        let v = UIButton()
        v.setTitle("同意".innerLocalized(), for: .normal)
        v.titleLabel?.font = .systemFont(ofSize: 12)
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(StandardUI.avatar_42)
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(22)
        }

        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView)
            make.left.equalTo(avatarImageView.snp.right).offset(18)
        }

        contentView.addSubview(applyInfoLabel)
        applyInfoLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalTo(nameLabel)
        }

        contentView.addSubview(applyReasonLabel)
        applyReasonLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(12)
            make.leading.equalTo(nameLabel)
            make.bottom.equalToSuperview().offset(-12)
            make.right.equalToSuperview().offset(-18)
        }

        contentView.addSubview(agreeBtn)
        agreeBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-18)
            make.centerY.equalTo(avatarImageView)
            make.size.equalTo(CGSize(width: 44, height: 22))
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

    func setApplyState(_ state: ApplyState) {
        switch state {
        case .uncertain:
            agreeBtn.setTitle("同意".innerLocalized(), for: .normal)
            agreeBtn.layer.cornerRadius = 3
            agreeBtn.layer.borderColor = StandardUI.color_1B72EC.cgColor
            agreeBtn.layer.borderWidth = 1
            agreeBtn.setTitleColor(StandardUI.color_418AE5, for: .normal)
            agreeBtn.isUserInteractionEnabled = true
        case .agreed:
            agreeBtn.setTitle("已同意".innerLocalized(), for: .normal)
            agreeBtn.isUserInteractionEnabled = false
            agreeBtn.layer.cornerRadius = 0
            agreeBtn.layer.borderWidth = 0
            agreeBtn.layer.borderColor = UIColor.white.cgColor
            agreeBtn.setTitleColor(StandardUI.color_418AE5, for: .normal)
        case .rejected:
            agreeBtn.setTitle("已拒绝".innerLocalized(), for: .normal)
            agreeBtn.isUserInteractionEnabled = false
            agreeBtn.layer.cornerRadius = 0
            agreeBtn.layer.borderWidth = 0
            agreeBtn.layer.borderColor = UIColor.white.cgColor
            agreeBtn.setTitleColor(StandardUI.color_898989, for: .normal)
        }
    }

    func setCompanyName(_ name: String) {
        let attr = NSMutableAttributedString(string: "申请加入".innerLocalized() + " ")
        let companyAttrName = NSAttributedString(string: name, attributes: [.foregroundColor: StandardUI.color_418AE5])
        attr.append(companyAttrName)
        applyInfoLabel.attributedText = attr
    }

    func setApply(reason: String) {
        applyReasonLabel.text = "申请理由".innerLocalized() + ":\n \(reason)"
    }

    enum ApplyState: Int {
        case uncertain
        case agreed
        case rejected
    }
}
