
import OUICore

public class ShowSelectedTableViewCell: UITableViewCell {
    
    public let avatarView: AvatarView = {
        let v = AvatarView()
        return v
    }()

    public let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 16)
        v.textColor = StandardUI.color_333333
        return v
    }()

    let subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 12)
        v.textColor = StandardUI.color_666666
        return v
    }()
    
    let trainingButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle(" 移除 ", for: .normal)
        v.layer.borderColor = UIColor.systemBlue.cgColor
        v.layer.borderWidth = 1
        v.layer.cornerRadius = 2
        
        v.layer.masksToBounds = true
        
        return v
    }()
    
    let rowStack: UIStackView = {
        let v = UIStackView.init(arrangedSubviews: [SizeBox(width: 8)]);
        v.spacing = 8
        v.alignment = .center
        
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        
        avatarView.snp.makeConstraints { make in
            make.size.equalTo(StandardUI.avatar_42)
        }

        let textStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
            v.axis = .vertical
            v.spacing = 4
            v.alignment = .leading
            return v
        }()

        trainingButton.snp.makeConstraints { make in
            make.width.equalTo(44)
        }
        
        rowStack.addArrangedSubview(avatarView)
        rowStack.addArrangedSubview(textStack)
        rowStack.addArrangedSubview(trainingButton)
        rowStack.addArrangedSubview(SizeBox(width: 16))
        contentView.addSubview(rowStack)
        
        rowStack.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        reset()
    }
    
    private func reset() {
        titleLabel.text = nil
        subtitleLabel.text = nil
    }
}
