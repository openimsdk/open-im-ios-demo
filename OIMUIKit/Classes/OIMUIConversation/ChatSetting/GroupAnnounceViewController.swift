
import RxSwift
import SnapKit
import SVProgressHUD
import UIKit

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
        v.font = UIFont.systemFont(ofSize: 16)
        v.textColor = StandardUI.color_333333
        v.contentInset = UIEdgeInsets(top: 0, left: StandardUI.margin_22, bottom: 0, right: StandardUI.margin_22)
        v.isEditable = false
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
            v.backgroundColor = StandardUI.color_F0F0F0
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
        view.backgroundColor = .white
        if memberInfo.roleLevel == .super || memberInfo.roleLevel == .admin {
            navigationItem.rightBarButtonItem = editBtn
        } else {
            tipsView.isHidden = true
            contentTextView.isEditable = false
        }

        initView()
        bindData()
    }

    private func initView() {
        navigationItem.title = "群公告".innerLocalized()
        let vStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [headerContainer, contentTextView, tipsView])
            v.axis = .vertical
            return v
        }()
        view.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-kSafeAreaBottomHeight - 60)
        }
    }

    private func bindData() {
        nameLabel.text = memberInfo.nickname
        avatarImageView.setImage(with: memberInfo.faceURL, placeHolder: "contact_my_friend_icon")
        timeLabel.text = FormatUtil.getFormatDate(formatString: "yyyy-MM-dd", of: memberInfo.joinTime / 1000)
        contentTextView.text = groupInfo.introduction
        editBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?.contentTextView.isEditable = true
            guard let sself = self, let announce = sself.contentTextView.text, announce.isEmpty == false else {
                self?.contentTextView.becomeFirstResponder()
                return
            }
            self?.contentTextView.resignFirstResponder()
            AlertView.show(onWindowOf: sself.view, alertTitle: "该公告会通知全部群成员，是否发布？".innerLocalized(), confirmTitle: "发布".innerLocalized()) {
                sself.groupInfo.notification = announce
                IMController.shared.setGroupInfo(group: sself.groupInfo) { _ in
                    SVProgressHUD.showSuccess(withStatus: nil)
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }).disposed(by: _disposeBag)

        contentTextView.rx.didChange.subscribe(onNext: { [weak self] in
            guard let sself = self else { return }
            self?.editBtn.title = sself.contentTextView.text.isEmpty ? "编辑".innerLocalized() : "发布".innerLocalized()
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
