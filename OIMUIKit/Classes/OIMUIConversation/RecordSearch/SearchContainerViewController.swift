
import RxSwift
import UIKit

class SearchContainerViewController: UIViewController {
    private lazy var searchBar: UISearchBar = {
        let v = UISearchBar()
        v.searchBarStyle = .minimal
        v.showsCancelButton = false
        if #available(iOS 13.0, *) {
            v.searchTextField.clearButtonMode = .always
        }
        v.placeholder = "搜索".innerLocalized()
        return v
    }()

    private lazy var cancelBtn: UIButton = {
        let v = UIButton()
        v.setTitle("取消".innerLocalized(), for: .normal)
        v.setTitleColor(StandardUI.color_1B72EC, for: .normal)
        v.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        v.rx.tap.subscribe(onNext: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: _disposeBag)
        return v
    }()

    private let imageBtn: UIButton = {
        let v = UIButton()
        v.setTitle("图片".innerLocalized(), for: .normal)
        v.setTitleColor(StandardUI.color_1B72EC, for: .normal)
        v.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        return v
    }()

    private let videoBtn: UIButton = {
        let v = UIButton()
        v.setTitle("视频".innerLocalized(), for: .normal)
        v.setTitleColor(StandardUI.color_1B72EC, for: .normal)
        v.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        return v
    }()

    private let fileBtn: UIButton = {
        let v = UIButton()
        v.setTitle("文件".innerLocalized(), for: .normal)
        v.setTitleColor(StandardUI.color_1B72EC, for: .normal)
        v.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        return v
    }()

    private lazy var _tableView: UITableView = {
        let v = UITableView()
        v.register(MessageRecordTableViewCell.self, forCellReuseIdentifier: MessageRecordTableViewCell.className)
        v.rowHeight = UITableView.automaticDimension
        v.separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: StandardUI.margin_22)
        v.separatorColor = StandardUI.color_F1F1F1
        v.tableFooterView = UIView()
        v.backgroundColor = UIColor.white
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()

    private let _disposeBag = DisposeBag()
    private let _viewModel: SearchRecordViewModel

    init(conversationId: String) {
        _viewModel = SearchRecordViewModel(conversationId: conversationId)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        initView()
        bindData()
    }

    private let containerView: UIView = .init()

    private func initView() {
        let topContainer = UIView()
        topContainer.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(StandardUI.margin_22)
            make.centerY.equalToSuperview()
            make.height.equalTo(34)
        }

        topContainer.addSubview(cancelBtn)
        cancelBtn.snp.makeConstraints { make in
            make.left.equalTo(searchBar.snp.right)
            make.right.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(searchBar)
        }

        view.addSubview(topContainer)
        topContainer.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }

        let tipsLabel: UILabel = {
            let v = UILabel()
            v.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            v.textColor = StandardUI.color_666666
            v.text = "搜索指定内容".innerLocalized()
            return v
        }()

        let hStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [imageBtn, videoBtn, fileBtn])
            v.axis = .horizontal
            v.spacing = 30
            v.distribution = .fillEqually
            return v
        }()

        containerView.addSubview(tipsLabel)
        tipsLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        containerView.addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.top.equalTo(tipsLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(40)
            make.bottom.equalToSuperview()
        }

        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalTo(topContainer.snp.bottom).offset(52)
            make.left.right.equalToSuperview()
        }

        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.top.equalTo(topContainer.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func bindData() {
        searchBar.rx.text.changed.subscribe(onNext: { [weak self] (text: String?) in
            self?._viewModel.searchText(text)
        }).disposed(by: _disposeBag)

        searchBar.rx.searchButtonClicked.subscribe(onNext: { [weak self] in
            self?._viewModel.searchText(self?.searchBar.text)
        }).disposed(by: _disposeBag)

        imageBtn.rx.tap.subscribe(onNext: { [weak self] in
            guard let sself = self else { return }
            let vc = ImageRecordViewController(viewModel: sself._viewModel, viewType: .image)
            self?.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: _disposeBag)

        videoBtn.rx.tap.subscribe(onNext: { [weak self] in
            guard let sself = self else { return }
            let vc = ImageRecordViewController(viewModel: sself._viewModel, viewType: .video)
            self?.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: _disposeBag)

        fileBtn.rx.tap.subscribe(onNext: { [weak self] in
            guard let sself = self else { return }
            let vc = FileRecordViewController(viewModel: sself._viewModel)
            self?.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: _disposeBag)

        _viewModel.textRelay.map { $0.isEmpty }.bind(to: _tableView.rx.isHidden).disposed(by: _disposeBag)

        _viewModel.textRelay.bind(to: _tableView.rx.items) { (tv, _, message: MessageInfo) in
            let cell = tv.dequeueReusableCell(withIdentifier: MessageRecordTableViewCell.className) as! MessageRecordTableViewCell
            cell.avatarImageView.setImage(with: message.senderFaceUrl, placeHolder: nil)
            cell.nameLabel.text = message.senderNickname
            cell.contentLabel.text = message.content
            cell.timeLabel.text = FormatUtil.getFormatDate(of: Int(message.sendTime) / 1000)
            return cell
        }.disposed(by: _disposeBag)
    }
}

extension SearchContainerViewController {
    class MessageRecordTableViewCell: UITableViewCell {
        let avatarImageView: UIImageView = {
            let v = UIImageView()
            v.layer.cornerRadius = 4
            v.clipsToBounds = true
            v.contentMode = .scaleAspectFill
            v.backgroundColor = StandardUI.color_F1F1F1
            return v
        }()

        let nameLabel: UILabel = {
            let v = UILabel()
            v.font = UIFont.systemFont(ofSize: 14)
            v.textColor = StandardUI.color_333333
            return v
        }()

        let contentLabel: UILabel = {
            let v = UILabel()
            v.font = UIFont.systemFont(ofSize: 12)
            return v
        }()

        let timeLabel: UILabel = {
            let v = UILabel()
            v.font = UIFont.systemFont(ofSize: 10)
            v.textColor = StandardUI.color_999999
            return v
        }()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)

            contentView.addSubview(avatarImageView)
            avatarImageView.snp.makeConstraints { make in
                make.size.equalTo(StandardUI.avatar_42)
                make.left.equalToSuperview().offset(StandardUI.margin_22)
                make.top.equalToSuperview().offset(10)
                make.bottom.equalToSuperview().offset(-10).priority(.low)
            }

            contentView.addSubview(nameLabel)
            nameLabel.snp.makeConstraints { make in
                make.left.equalTo(avatarImageView.snp.right).offset(10)
                make.top.equalTo(avatarImageView).offset(2)
                make.right.equalToSuperview().offset(-80)
            }

            contentView.addSubview(contentLabel)
            contentLabel.snp.makeConstraints { make in
                make.leading.equalTo(nameLabel)
                make.bottom.equalTo(avatarImageView)
                make.right.equalToSuperview().offset(-StandardUI.margin_22)
            }

            contentView.addSubview(timeLabel)
            timeLabel.snp.makeConstraints { make in
                make.right.equalToSuperview().offset(-StandardUI.margin_22)
                make.centerY.equalTo(nameLabel)
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
