//






import UIKit

class QRCodeViewController: UIViewController {
    
    private lazy var shadowView: UIView = {
        let v = UIView()
        v.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.08).cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 0)
        v.layer.shadowOpacity = 1
        v.layer.shadowRadius = 7
        return v
    }()
    
    private let backgroundView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10
        v.backgroundColor = .white
        return v
    }()

    private let avatarImageView: UIImageView = {
        let v = UIImageView()
        v.layer.cornerRadius = 6
        v.backgroundColor = .purple
        return v
    }()
    
    private let nameLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 20)
        v.textColor = .black
        return v
    }()
    
    private let tipLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 14)
        v.textColor = StandardUI.color_999999
        return v
    }()
    
    private lazy var codeBackgroundImageView: UIImageView = {
        let v = UIImageView.init(image: UIImage.init(nameInBundle: "common_qrcode_background_image"))
        v.contentMode = .scaleAspectFill
        return v
    }()
    
    private let codeContentImageView: UIImageView = UIImageView()
    
    init(faceUrl: String?, nickName: String, idString: String) {
        super.init(nibName: nil, bundle: nil)
        avatarImageView.setImage(with: faceUrl, placeHolder: nil)
        nameLabel.text = nickName
        tipLabel.text = "扫一扫群二维码，立刻加入该群。"
        DispatchQueue.global().async {
            let image = CodeImageGenerator().createQRCodeImage(content: idString, size: CGSize.init(width: 140, height: 140), foregroundColor: UIColor.black, backgroundColor: UIColor.clear)
            DispatchQueue.main.async {
                self.codeContentImageView.image = image
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.navigationItem.title = "群二维码"
        initView()
        bindData()
    }
    
    private func initView() {
        shadowView.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        backgroundView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.top.left.equalToSuperview().inset(30)
            make.size.equalTo(48)
        }
        
        backgroundView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(13)
            make.centerY.equalTo(avatarImageView)
        }
        
        backgroundView.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(56)
            make.centerX.equalToSuperview()
        }
        
        backgroundView.addSubview(codeBackgroundImageView)
        codeBackgroundImageView.snp.makeConstraints { make in
            make.top.equalTo(tipLabel.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.size.equalTo(180)
            make.bottom.equalToSuperview().offset(-80)
        }
        
        codeBackgroundImageView.addSubview(codeContentImageView)
        codeContentImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        view.addSubview(shadowView)
        shadowView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(58)
            make.left.right.equalToSuperview().inset(StandardUI.margin_22)
        }
    }
    
    private func bindData() {
        
    }
}
