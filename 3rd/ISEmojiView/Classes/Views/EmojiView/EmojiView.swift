






import Foundation
import UIKit

public enum BottomType: Int {
    case pageControl, categories, topCategories
}

public protocol EmojiViewDelegate: AnyObject {
    
    func emojiViewDidSelectEmoji(_ emoji: String, emojiView: EmojiView)
    func emojiViewDidSelectFace(_ emoji: FaceEmoji, emojiView: EmojiView)
    func emojiViewDidAddFace(_ addEmoji: ((URL) -> Void)?, emojiView: EmojiView)
    func emojiViewDidPressChangeKeyboardButton(_ emojiView: EmojiView)
    func emojiViewDidPressDeleteBackwardButton(_ emojiView: EmojiView)
    func emojiViewDidPressDismissKeyboardButton(_ emojiView: EmojiView)
    
}

public extension EmojiViewDelegate {
    func emojiViewDidAddFace(_ addEmoji: ((URL) -> Void)?, _: EmojiView) {}
    func emojiViewDidSelectFace(_ emoji: FaceEmoji, _: Int, _: EmojiView) {}
    func emojiViewDidPressChangeKeyboardButton(_ emojiView: EmojiView) {}
    func emojiViewDidPressDeleteBackwardButton(_ emojiView: EmojiView) {}
    func emojiViewDidPressDismissKeyboardButton(_ emojiView: EmojiView) {}
    
}

final public class EmojiView: UIView {

    
    @IBInspectable private var _bottomType: Int = BottomType.pageControl.rawValue {
        didSet {
            guard let type = BottomType(rawValue: _bottomType) else {
                fatalError()
            }
            
            bottomType = type
            setupBottomView()
        }
    }
    
    @IBInspectable private var isShowPopPreview: Bool = true {
        didSet {
            emojiCollectionView?.isShowPopPreview = isShowPopPreview
        }
    }
    
    @IBInspectable private var countOfRecentsEmojis: Int = MaxCountOfRecentsEmojis {
        didSet {
            if countOfRecentsEmojis > 0 {
                if !emojis.contains(where: { $0.category == .recents }) {
                    emojis.insert(EmojiLoader.recentEmojiCategory(), at: 0)
                }
            } else if let index = emojis.firstIndex(where: { $0.category == .recents }) {
                emojis.remove(at: index)
            }
            
            emojiCollectionView?.emojis = emojis
            categoriesView?.categories = emojis.map { $0.category }
        }
    }
    
    @IBInspectable private var needToShowAbcButton: Bool = false {
        didSet {
            categoriesView?.needToShowAbcButton = needToShowAbcButton
        }
    }

    
    public weak var delegate: EmojiViewDelegate?

    
    private weak var bottomContainerView: UIView?
    private weak var emojiCollectionView: EmojiCollectionView?
    private weak var faceCollectionView: FaceCollectionView?
    private weak var pageControlBottomView: PageControlBottomView?
    private weak var categoriesView: CategoriesView?
    private weak var categoriesTabView: CategoriesTabView?
    
    private var bottomConstraint: NSLayoutConstraint?
    
    private var bottomType: BottomType!
    private var emojis: [EmojiCategory]!
    private var faceEmojis: [EmojiCategory]!
    private var keyboardSettings: KeyboardSettings?
    
    public func forceReload() {
        let faces = FaceManager.shared.images
        
        faceCollectionView?.emojis = [EmojiCategory(category: .face, faceEmoji: faces)]
    }

    
    public init(keyboardSettings: KeyboardSettings) {
        super.init(frame: .zero)
        
        self.keyboardSettings = keyboardSettings
        bottomType = keyboardSettings.bottomType
        emojis = keyboardSettings.customEmojis ?? EmojiLoader.emojiCategories()
        countOfRecentsEmojis = keyboardSettings.countOfRecentsEmojis
        
        if keyboardSettings.countOfRecentsEmojis > 0 {
            emojis.insert(EmojiLoader.recentEmojiCategory(), at: 0)
        }
        
        if let identity = keyboardSettings.identity {
            FaceManager.shared.identity = identity
        }
        
        faceEmojis = [EmojiCategory(category: .face, faceEmoji: FaceManager.shared.images)]
                
        setupView()
        setupSubviews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        bottomType = BottomType(rawValue: _bottomType)
        emojis = EmojiLoader.emojiCategories()
        
        if countOfRecentsEmojis > 0 {
            emojis.insert(EmojiLoader.recentEmojiCategory(), at: 0)
        }
        
        faceEmojis = [EmojiCategory(category: .face, faceEmoji: FaceManager.shared.images)]
        
        setupSubviews()
    }

    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if #available(iOS 11.0, *) {
            bottomConstraint?.constant = -safeAreaInsets.bottom
        } else {
            bottomConstraint?.constant = 0
        }
        
    }
    
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if point.y > 0 || !(emojiCollectionView?.popPreviewShowing() ?? false) {
            return super.point(inside: point, with: event)
        }
        
        return emojiCollectionView?.point(inside: point, with: event) ?? true
    }
    
    private func topMostViewController() -> UIViewController? {
        guard let keyWindow = UIApplication.shared.windows.filter({$0.isKeyWindow}).first else {
            return nil
        }

        var topController = keyWindow.rootViewController

        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }

        return topController
    }

}


extension EmojiView: EmojiCollectionViewDelegate {
    
    func emojiViewDidSelectEmoji(emojiView: EmojiCollectionView, emoji: Emoji, selectedEmoji: String) {
        if RecentEmojisManager.sharedInstance.add(emoji: emoji, selectedEmoji: selectedEmoji, maxCount: countOfRecentsEmojis),(keyboardSettings?.updateRecentEmojiImmediately) ?? true  {
            emojiCollectionView?.updateRecentsEmojis(RecentEmojisManager.sharedInstance.recentEmojis())
        }
        
        delegate?.emojiViewDidSelectEmoji(selectedEmoji, emojiView: self)
    }
    
    func emojiViewDidChangeCategory(_ category: Category, emojiView: EmojiCollectionView) {
        if let section = emojis.firstIndex(where: { $0.category == category }) {
            pageControlBottomView?.updatePageControlPage(section)
        }
        
        categoriesView?.updateCurrentCategory(category)
    }
}


extension EmojiView: PageControlBottomViewDelegate {
    
    func pageControlBottomViewDidPressDeleteBackwardButton(_ bottomView: PageControlBottomView) {
        delegate?.emojiViewDidPressDeleteBackwardButton(self)
    }
    
    func pageControlBottomViewDidPressDismissKeyboardButton(_ bottomView: PageControlBottomView) {
        delegate?.emojiViewDidPressDismissKeyboardButton(self)
    }
    
}


extension EmojiView: CategoriesViewDelegate {
    
    func categoriesViewDidSelecteCategory(_ category: Category, bottomView: CategoriesView) {
        emojiCollectionView?.scrollToCategory(category)
    }
    
    func categoriesViewDidPressChangeKeyboardButton(_ bottomView: CategoriesView) {
        delegate?.emojiViewDidPressChangeKeyboardButton(self)
    }
    
    func categoriesViewDidPressDeleteBackwardButton(_ bottomView: CategoriesView) {
        delegate?.emojiViewDidPressDeleteBackwardButton(self)
    }
    
}

extension EmojiView: CategoriesTabViewDelegate {
    func categoriesBottomViewDidSelecteCategory(_ category: TabCategory, bottomView: CategoriesTabView) {
        faceCollectionView?.isHidden = category == .emoji
        emojiCollectionView?.isHidden = category == .favorite
        categoriesView?.isHidden = category == .favorite
    }
    
}

extension EmojiView: FaceCollectionViewDelegate {
    func faceViewDidSelectEmoji(faceView: FaceCollectionView, emoji: FaceEmoji) {
        delegate?.emojiViewDidSelectFace(emoji, emojiView: self)
    }
    
    func faceViewDidSelectAdd(faceView: FaceCollectionView) {
        let vc = FaceManageViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .overCurrentContext
        
        topMostViewController()?.present(nav, animated: true)
        
        vc.faceEmojisCallback = { [weak self] faces in
            guard let self else { return }
            
            faceCollectionView?.emojis = [EmojiCategory(category: .face, faceEmoji: faces)]
        }
        
        vc.faceEmojiAddCallback = { [weak self] callbak in
            guard let self else { return }
            
            delegate?.emojiViewDidAddFace(callbak, emojiView: self)
        }
    }
    
}


extension EmojiView {
    
    private func setupView() {
        if #available(iOS 13, *) {

            backgroundColor = .secondarySystemBackground
        } else {
            backgroundColor = UIColor(red: 249/255.0, green: 249/255.0, blue: 249/255.0, alpha: 1)
        }
    }
    
    private func setupSubviews() {
        setupEmojiCollectionView()
        setupCategoriesContainerView()
        setupConstraints()
    }
    
    private func setupEmojiCollectionView() {
        let emojiCollectionView = EmojiCollectionView.loadFromNib(emojis: emojis)
        emojiCollectionView.isShowPopPreview = keyboardSettings?.isShowPopPreview ?? isShowPopPreview
        emojiCollectionView.delegate = self
        emojiCollectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emojiCollectionView)
        
        self.emojiCollectionView = emojiCollectionView
    }
    
    private func setupCategoriesContainerView() {
        let bottomContainerView = UIView()
        bottomContainerView.backgroundColor = .clear
        bottomContainerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomContainerView)
        
        self.bottomContainerView = bottomContainerView
        
        if bottomType == .topCategories {
            setupTopCategoriesView()
            setupCategoriesTabView()
            setupFaceCollectionView()
        } else {
            setupBottomView()
        }
    }
    
    private func setupBottomView() {
        bottomContainerView?.subviews.forEach { $0.removeFromSuperview() }
        
        let categories: [Category] = emojis.map { $0.category }
        
        var _bottomView: UIView?
        
        if bottomType == .pageControl {
          let needToShowDeleteButton = keyboardSettings?.needToShowDeleteButton ?? true
          let bottomView = PageControlBottomView.loadFromNib(
              categoriesCount: categories.count,
              needToShowDeleteButton: needToShowDeleteButton
            )
            bottomView.delegate = self
            self.pageControlBottomView = bottomView
            
            _bottomView = bottomView
        } else if bottomType == .categories {
            let needToShowAbcButton = keyboardSettings?.needToShowAbcButton ?? self.needToShowAbcButton
            let needToShowDeleteButton = keyboardSettings?.needToShowDeleteButton ?? true
            let bottomView = CategoriesView.loadFromNib(
                with: categories,
                needToShowAbcButton: needToShowAbcButton,
                needToShowDeleteButton: needToShowDeleteButton
            )
            bottomView.delegate = self
            self.categoriesView = bottomView
            
            _bottomView = bottomView
        }
        
        guard let bottomView = _bottomView else {
            return
        }
        
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerView?.addSubview(bottomView)
        
        let views = ["bottomView": bottomView]
        
        addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-0-[bottomView]-0-|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                metrics: nil,
                views: views
            )
        )
        
        addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-0-[bottomView]-0-|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                metrics: nil,
                views: views
            )
        )
    }
    
    private func setupTopCategoriesView() {
        let categories: [Category] = emojis.map { $0.category }
        
        let needToShowAbcButton = keyboardSettings?.needToShowAbcButton ?? self.needToShowAbcButton
        let needToShowDeleteButton = keyboardSettings?.needToShowDeleteButton ?? true
        categoriesView = CategoriesView.loadFromNib(
            with: categories,
            needToShowAbcButton: needToShowAbcButton,
            needToShowDeleteButton: needToShowDeleteButton
        )
        categoriesView!.delegate = self
        
        addSubview(categoriesView!)
    }
    
    private func setupFaceCollectionView() {

        let fe = FaceManager.shared.read()
        faceCollectionView = FaceCollectionView.loadFromNib(emojis: [EmojiCategory(category: .face, faceEmoji: fe)])
        faceCollectionView!.delegate = self
        faceCollectionView!.translatesAutoresizingMaskIntoConstraints = false
        faceCollectionView!.isHidden = true
        
        addSubview(faceCollectionView!)
    }
    
    private func setupCategoriesTabView() {
        categoriesTabView = CategoriesTabView.loadFromNib()
        categoriesTabView!.delegate = self
        
        addSubview(categoriesTabView!)
    }
    
    private func setupConstraints() {
        
        if bottomType == .topCategories {
            guard let emojiCollectionView, let categoriesView, let categoriesTabView, let faceCollectionView else { return }
            
            categoriesTabView.translatesAutoresizingMaskIntoConstraints = false
            categoriesView.translatesAutoresizingMaskIntoConstraints = false
            emojiCollectionView.translatesAutoresizingMaskIntoConstraints = false
            faceCollectionView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                categoriesView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                categoriesView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                categoriesView.topAnchor.constraint(equalTo: self.topAnchor),
                categoriesView.bottomAnchor.constraint(equalTo: emojiCollectionView.topAnchor, constant: -8),
                
                emojiCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                emojiCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                emojiCollectionView.bottomAnchor.constraint(equalTo: categoriesTabView.topAnchor),
                
                categoriesTabView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                categoriesTabView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                categoriesTabView.bottomAnchor.constraint(equalTo: self.readableContentGuide.bottomAnchor),
                categoriesTabView.heightAnchor.constraint(equalToConstant: 32),
                
                faceCollectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
                faceCollectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
                faceCollectionView.topAnchor.constraint(equalTo: self.topAnchor),
                faceCollectionView.bottomAnchor.constraint(equalTo: categoriesTabView.topAnchor),
            ])
            
            return
        }
        
        guard let emojiCollectionView = emojiCollectionView, let bottomContainerView = bottomContainerView else {
            return
        }
        
        let views = [
            "emojiCollectionView": emojiCollectionView,
            "bottomContainerView": bottomContainerView
        ]
        
        addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-0-[emojiCollectionView]-0-|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                metrics: nil,
                views: views
            )
        )
        
        addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|-0-[bottomContainerView]-0-|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                metrics: nil,
                views: views
            )
        )
        
        addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|-5-[emojiCollectionView]-(0)-[bottomContainerView(44)]",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                metrics: nil,
                views: views
            )
        )
        
        var bottomOffset = CGFloat(0)
        
        if #available(iOS 11.0, *) {
            bottomOffset = -safeAreaInsets.bottom
        }
        
        let bottomConstraint = NSLayoutConstraint(
            item: bottomContainerView,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: self,
            attribute: .bottom,
            multiplier: 1,
            constant: bottomOffset
        )
        
        addConstraint(bottomConstraint)
        
        self.bottomConstraint = bottomConstraint
    }
    
}
