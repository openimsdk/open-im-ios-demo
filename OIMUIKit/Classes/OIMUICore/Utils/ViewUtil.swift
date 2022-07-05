
import UIKit

class ViewUtil {
    static func createSectionHeaderWith(text: String) -> UIView {
        let container: UIView = {
            let v = UIView()
            v.backgroundColor = StandardUI.color_F1F1F1
            let label: UILabel = {
                let v = UILabel()
                v.font = .systemFont(ofSize: 12)
                v.textColor = StandardUI.color_999999
                v.text = text
                return v
            }()
            v.addSubview(label)
            label.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(StandardUI.margin_22)
                make.centerY.equalToSuperview()
            }
            return v
        }()
        return container
    }

    static func createSpacer(height: CGFloat) -> UIView {
        let container: UIView = {
            let v = UIView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: height))
            v.backgroundColor = StandardUI.color_F1F1F1
            return v
        }()
        return container
    }
}
