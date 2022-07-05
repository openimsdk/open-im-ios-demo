
import UIKit

class ChatMenuView: UIView, UITableViewDataSource, UITableViewDelegate {
    private var _actionItems: [MenuItem] = []
    private lazy var _tableView: UITableView = {
        let v = UITableView()
        v.register(MenuTableViewCell.self, forCellReuseIdentifier: MenuTableViewCell.className)
        v.showsVerticalScrollIndicator = false
        v.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: topInset, right: 0)
        v.separatorStyle = .none
        v.dataSource = self
        v.delegate = self
        v.layer.cornerRadius = 6
        v.clipsToBounds = true
        v.isScrollEnabled = false
        return v
    }()

    private let shadowContainer: UIView = {
        let v = UIView()
        v.layer.shadowOpacity = 1
        v.layer.shadowColor = UIColor(white: 0, alpha: 0.16).cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 0)
        v.layer.shadowRadius = 2
        return v
    }()

    private let topInset: CGFloat = 8
    func setItems(_ items: [MenuItem]) {
        _actionItems = items
        let height = CGFloat(44 * items.count) + topInset * 2
        _tableView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        _tableView.reloadData()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        shadowContainer.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(0)
        }
        addSubview(shadowContainer)
        shadowContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(kStatusBarHeight + 60)
            make.width.equalTo(170)
            make.right.equalToSuperview().offset(-18)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let view = _tableView
        let point = touch.location(in: self)
        let tPoint = view.convert(point, from: self)
        if view.point(inside: tPoint, with: event) { return }
        removeFromSuperview()
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return _actionItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = _actionItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: MenuTableViewCell.className) as! MenuTableViewCell
        cell.iconImageView.image = item.icon
        cell.titleLabel.text = item.title
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = _actionItems[indexPath.row]
        item.action()
        removeFromSuperview()
    }

    struct MenuItem {
        let title: String
        let icon: UIImage?
        let action: () -> Void
    }

    class MenuTableViewCell: UITableViewCell {
        let iconImageView: UIImageView = {
            let v = UIImageView()
            return v
        }()

        let titleLabel: UILabel = {
            let v = UILabel()
            v.font = .systemFont(ofSize: 14)
            v.textColor = StandardUI.color_333333
            return v
        }()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            selectionStyle = .none
            contentView.addSubview(iconImageView)
            iconImageView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(StandardUI.margin_22)
                make.centerY.equalToSuperview()
            }

            contentView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.left.equalTo(iconImageView.snp.right).offset(15)
                make.centerY.equalTo(iconImageView)
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
