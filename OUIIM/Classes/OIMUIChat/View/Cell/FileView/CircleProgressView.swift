
import Foundation
import UIKit

class CircleProgressView: UIView {

    public var progress: CGFloat = 0 {
        didSet {
            print("\(CircleProgressView.self): progress - \(progress)")

            setNeedsDisplay()
        }
    }

    public var progerssColor: UIColor = .systemBlue

    public var progerssBackgroundColor: UIColor = .white

    public var progerWidth: CGFloat = 3

    public var percentageFontSize: CGFloat = 10

    public var percentFontColor: UIColor = .white

    lazy var valueLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: percentageFontSize)
        v.textColor = percentFontColor
        v.textAlignment = .center
        
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setSubviews() {
        backgroundColor = .clear
        addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            valueLabel.topAnchor.constraint(equalTo: topAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    override func draw(_ rect: CGRect) {

        var backgroundPath = UIBezierPath()

        backgroundPath.lineWidth = progerWidth

        progerssBackgroundColor.set()

        backgroundPath.lineCapStyle = .round
        backgroundPath.lineJoinStyle = .round

        var radius = (min(rect.size.width, rect.size.height) - progerWidth) * 0.5;

        backgroundPath.addArc(withCenter: CGPoint(x: rect.size.width * 0.5, y: rect.size.height * 0.5), radius: radius, startAngle: M_PI * 1.5, endAngle: M_PI * 1.5 + M_PI * 2, clockwise: true)

        backgroundPath.stroke()

        var progressPath = UIBezierPath()

        progressPath.lineWidth = progerWidth

        progerssColor.set()

        progressPath.lineCapStyle = .round
        progressPath.lineJoinStyle = .round

        progressPath.addArc(withCenter: CGPoint(x: rect.size.width * 0.5, y: rect.size.height * 0.5), radius: radius, startAngle: M_PI * 1.5, endAngle: M_PI * 1.5 + M_PI * 2 * progress, clockwise: true)

        progressPath.stroke()
    }
}
