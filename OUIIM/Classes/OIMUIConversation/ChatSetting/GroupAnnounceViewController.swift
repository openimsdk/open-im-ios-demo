
import RxSwift
import ProgressHUD
import OUICore

class GroupAnnounceViewController: UIViewController {
    private let avatarImageView: UIImageView = {
        let v = UIImageView()
        v.layer.cornerRadius = 4
        v.clipsToBounds = true
        return v
    }()

    private let nameLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        v.textColor = StandardUI.color_333333
        return v
    }()

    private let timeLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 12)
        v.textColor = StandardUI.color_999999
        return v
    }()

    private let contentTextView: UITextView = {
        let v = UITextView()
        v.font = .f17
        v.textColor = .c0C1C33
        v.isEditable = false
        v.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        return v
    }()

    private let tipsView: SeparatorView = {
        let v = SeparatorView()
        v.titleLabel.textColor = StandardUI.color_999999
        v.titleLabel.font = UIFont.systemFont(ofSize: 12)
        v.titleLabel.text = "只有群主及管理员可以编辑".innerLocalized()
        return v
    }()

    private lazy var headerContainer: UIView = {
        let v = UIView()
        v.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(StandardUI.margin_22)
            make.top.bottom.equalToSuperview().inset(10)
            make.size.equalTo(StandardUI.avatar_42)
        }
        v.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(18)
            make.top.equalTo(avatarImageView).offset(2)
            make.right.lessThanOrEqualToSuperview().offset(-10)
        }
        v.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
        }
        let separatorLine: UIView = {
            let v = UIView()
            v.backgroundColor = .cF0F0F0
            return v
        }()
        v.addSubview(separatorLine)
        separatorLine.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(1)
        }
        return v
    }()

    private lazy var editBtn: UIBarButtonItem = {
        let v = UIBarButtonItem()
        v.title = "编辑".innerLocalized()
        return v
    }()

    private let _disposeBag = DisposeBag()
    private let memberInfo: GroupMemberInfo
    private let groupInfo: GroupInfo
    init(memberInfo: GroupMemberInfo, groupInfo: GroupInfo) {
        self.memberInfo = memberInfo
        self.groupInfo = groupInfo
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        
        if memberInfo.isOwnerOrAdmin {
            navigationItem.rightBarButtonItem = editBtn
            tipsView.isHidden = true
        } else {
            contentTextView.isEditable = false
        }

        initView()
        bindData()
    }

    private func initView() {
        navigationItem.title = "群公告".innerLocalized()
        let vStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [contentTextView, tipsView])
            v.axis = .vertical
            v.layer.cornerRadius = 6
            v.layer.masksToBounds = true
            
            return v
        }()
        view.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(8)
        }
    }

    private func bindData() {
        contentTextView.text = groupInfo.notification
        editBtn.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            
            self.contentTextView.isEditable = true
            
            if self.editBtn.title == "编辑" {
                self.contentTextView.becomeFirstResponder()
            } else {
                self.contentTextView.resignFirstResponder()
                AlertView.show(onWindowOf: self.view, alertTitle: "该公告会通知全部群成员，是否发布？".innerLocalized(), confirmTitle: "发布".innerLocalized()) {
                    self.groupInfo.notification = self.contentTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    IMController.shared.setGroupInfo(group: self.groupInfo) { _ in
                        ProgressHUD.showSuccess()
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
            
            self.editBtn.title = "发布".innerLocalized()
            
        }).disposed(by: _disposeBag)

        contentTextView.rx.didChange.subscribe(onNext: { [weak self] in
            guard let sself = self else { return }
            self?.editBtn.isEnabled = !sself.contentTextView.text.isEmpty
        }).disposed(by: _disposeBag)
    }

    class SeparatorView: UIView {
        let titleLabel: UILabel = {
            let v = UILabel()
            return v
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            let leftIcon = UIImageView(image: UIImage(nameInBundle: "setting_separator_line_icon"))
            let rightIcon = UIImageView(image: UIImage(nameInBundle: "setting_separator_line_icon"))
            let hStack: UIStackView = {
                let v = UIStackView(arrangedSubviews: [leftIcon, titleLabel, rightIcon])
                v.axis = .horizontal
                v.spacing = 8
                v.alignment = .center
                return v
            }()
            addSubview(hStack)
            hStack.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.centerX.equalToSuperview()
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
