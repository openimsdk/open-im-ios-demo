
import RxSwift
import OUICore

class GroupApplicationTableViewCell: UITableViewCell {
    var disposeBag = DisposeBag()

    let avatarView = AvatarView()

    let nameLabel: UILabel = {
        let v = UILabel()
        v.font = .f17
        v.textColor = .c0C1C33
        return v
    }()

    private let applyInfoLabel: UILabel = {
        let v = UILabel()
        v.font = .f14

        return v
    }()

    private let applyReasonLabel: UILabel = {
        let v = UILabel()
        v.font = .f14
        v.textColor = .c8E9AB0
        v.numberOfLines = 3
        return v
    }()

    let agreeBtn: UIButton = {
        let v = UIButton(type: .system)
        v.titleLabel?.font = .f14
        v.layer.cornerRadius = 5
        v.contentEdgeInsets = UIEdgeInsets(top: .margin8, left: .margin8, bottom: .margin8, right: .margin8)

        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.size.equalTo(StandardUI.avatar_42)
            make.top.equalToSuperview().offset(15)
            make.left.equalToSuperview().offset(22)
        }

        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView)
            make.left.equalTo(avatarView.snp.right).offset(18)
        }

        contentView.addSubview(applyInfoLabel)
        applyInfoLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalTo(nameLabel)
        }

        contentView.addSubview(applyReasonLabel)
        applyReasonLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(12)
            make.leading.equalTo(nameLabel)
            make.bottom.equalToSuperview().offset(-12)
            make.right.equalToSuperview().offset(-18)
        }

        contentView.addSubview(agreeBtn)
        agreeBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-18)
            make.centerY.equalTo(avatarView)
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
            agreeBtn.setTitle("接受".innerLocalized(), for: .normal)
            agreeBtn.backgroundColor = .c0089FF
            agreeBtn.tintColor = .white
            agreeBtn.isEnabled = true
        case .agreed:
            agreeBtn.setTitle("已同意".innerLocalized(), for: .normal)
            agreeBtn.backgroundColor = .clear
            agreeBtn.tintColor = .c8E9AB0
            agreeBtn.isEnabled = false
        case .rejected:
            agreeBtn.setTitle("已拒绝".innerLocalized(), for: .normal)
            agreeBtn.backgroundColor = .clear
            agreeBtn.tintColor = .c8E9AB0
            agreeBtn.isEnabled = false
        }
    }

    func setCompanyName(_ name: String) {
        let attr = NSMutableAttributedString(string: "申请加入".innerLocalized() + " ", attributes: [.foregroundColor: UIColor.c8E9AB0])
        let companyAttrName = NSAttributedString(string: name, attributes: [.foregroundColor: UIColor.c0089FF])
        attr.append(companyAttrName)
        applyInfoLabel.attributedText = attr
    }

    func setApply(reason: String) {
        applyReasonLabel.text = "申请理由".innerLocalized() + ":\n \(reason)"
    }
    
    enum ApplyState: Int {
        case rejected = -1
        case uncertain = 0
        case agreed = 1
        
    }
}
