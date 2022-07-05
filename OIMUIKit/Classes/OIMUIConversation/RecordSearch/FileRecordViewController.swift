
import RxDataSources
import RxRelay
import RxSwift
import SnapKit
import UIKit

class FileRecordViewController: UIViewController {
    private lazy var _tableView: UITableView = {
        let v = UITableView()
        v.register(FileRecordTableViewCell.self, forCellReuseIdentifier: FileRecordTableViewCell.className)
        v.separatorStyle = .none
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()

    private let _disposeBag = DisposeBag()
    private let _viewModel: SearchRecordViewModel
    init(viewModel: SearchRecordViewModel) {
        _viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "文件".innerLocalized()
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        bindData()
        _viewModel.searchFiles()
    }

    private func bindData() {
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, MessageInfo>>.init { (_, tableView, index, message: MessageInfo) in
            let cell = tableView.dequeueReusableCell(withIdentifier: FileRecordTableViewCell.className, for: index) as! FileRecordTableViewCell
            cell.avatarImageView.setImage(with: message.senderFaceUrl, placeHolder: nil)
            cell.nameLabel.text = message.senderNickname
            cell.timeLabel.text = FormatUtil.getFormatDate(formatString: "MM月dd日", of: Int(message.sendTime) / 1000)
            cell.fileNameLabel.text = message.fileElem?.fileName
            cell.fileSizeLabel.text = FormatUtil.getFileSizeDesc(fileSize: message.fileElem?.fileSize ?? 0)
            return cell
        } titleForHeaderInSection: { (ds: TableViewSectionedDataSource<SectionModel<String, MessageInfo>>, section) -> String? in
            ds[section].model
        }

        _viewModel.filesRelay.bind(to: _tableView.rx.items(dataSource: dataSource)).disposed(by: _disposeBag)

        _tableView.rx.modelSelected(MessageInfo.self).subscribe(onNext: { (_: MessageInfo) in
            print("跳转文件预览")
        }).disposed(by: _disposeBag)
    }
}

extension FileRecordViewController {
    class FileRecordTableViewCell: UITableViewCell {
        let avatarImageView: UIImageView = {
            let v = UIImageView()
            v.layer.cornerRadius = 4
            v.clipsToBounds = true
            v.backgroundColor = StandardUI.color_F1F1F1
            return v
        }()

        let nameLabel: UILabel = {
            let v = UILabel()
            v.font = UIFont.systemFont(ofSize: 14)
            v.textColor = StandardUI.color_666666
            return v
        }()

        let timeLabel: UILabel = {
            let v = UILabel()
            v.font = UIFont.systemFont(ofSize: 12)
            v.textColor = StandardUI.color_999999
            v.setContentHuggingPriority(.required, for: .horizontal)
            v.setContentCompressionResistancePriority(.required, for: .horizontal)
            return v
        }()

        let fileNameLabel: UILabel = {
            let v = UILabel()
            v.font = UIFont.systemFont(ofSize: 12)
            v.textColor = StandardUI.color_333333
            return v
        }()

        let fileSizeLabel: UILabel = {
            let v = UILabel()
            v.font = UIFont.systemFont(ofSize: 12)
            v.textColor = StandardUI.color_999999
            return v
        }()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            contentView.addSubview(avatarImageView)
            avatarImageView.snp.makeConstraints { make in
                make.left.top.equalToSuperview().inset(StandardUI.margin_22)
                make.size.equalTo(30)
            }

            contentView.addSubview(nameLabel)
            nameLabel.snp.makeConstraints { make in
                make.left.equalTo(avatarImageView.snp.right).offset(10)
                make.centerY.equalTo(avatarImageView)
            }

            contentView.addSubview(timeLabel)
            timeLabel.snp.makeConstraints { make in
                make.right.equalToSuperview().offset(-StandardUI.margin_22)
                make.centerY.equalTo(avatarImageView)
                make.left.greaterThanOrEqualTo(nameLabel.snp.right).offset(10)
            }

            let iconImageView = UIImageView(image: UIImage(nameInBundle: "setting_record_file_icon"))
            contentView.addSubview(iconImageView)
            iconImageView.snp.makeConstraints { make in
                make.top.equalTo(avatarImageView.snp.bottom).offset(18)
                make.left.equalTo(avatarImageView)
                make.width.equalTo(40)
                make.height.equalTo(38)
            }

            contentView.addSubview(fileNameLabel)
            fileNameLabel.snp.makeConstraints { make in
                make.left.equalTo(iconImageView.snp.right).offset(16)
                make.top.equalTo(iconImageView)
                make.right.equalToSuperview().offset(-10)
            }

            contentView.addSubview(fileSizeLabel)
            fileSizeLabel.snp.makeConstraints { make in
                make.left.equalTo(fileNameLabel)
                make.top.equalTo(fileNameLabel.snp.bottom).offset(3)
            }

            let separatorLine: UIView = {
                let v = UIView()
                v.backgroundColor = StandardUI.color_F1F1F1
                return v
            }()

            contentView.addSubview(separatorLine)
            separatorLine.snp.makeConstraints { make in
                make.top.equalTo(iconImageView.snp.bottom).offset(16)
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(6)
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
