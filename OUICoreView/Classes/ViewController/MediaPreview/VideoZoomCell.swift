
import UIKit
import Foundation
import OUICore
import AVFoundation
import Lantern

class PlayControlView: UIView {
    
    var onPlay: ((Bool) -> Void)?
    
    var progress: Float = 0 {
        didSet {
            playingProgressHUD.progress = progress
        }
    }
    
    var bufferProgress: Float = 0 {
        didSet {
            bufferProgressHUD.progress = bufferProgress
        }
    }
    
    func stopLoading() {
        loadHUD.stopAnimating()
        playButton.isHidden = false
        playButton.isSelected = true
    }
    
    func reset() {
        playButton.isSelected = false
    }
    
    private lazy var playButton: UIButton = {
        let v = UIButton(type: .custom)
        v.setBackgroundImage(UIImage(systemName: "play.circle"), for: .normal)
        v.setBackgroundImage(UIImage(systemName: "pause.circle"), for: .selected)
        v.tintColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        v.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
        v.isHidden = true
        
        return v
    }()
    
    @objc
    private func playButtonAction(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        onPlay?(sender.isSelected)
    }
    
    private lazy var bufferProgressHUD: UIProgressView = {
      let v = UIProgressView(progressViewStyle: .bar)
        v.progressTintColor = .systemBlue
        v.trackTintColor = .systemGray5
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    private lazy var playingProgressHUD: UIProgressView = {
      let v = UIProgressView(progressViewStyle: .bar)
        v.trackTintColor = .clear
        v.progressTintColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    private lazy var loadHUD: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.startAnimating()
        
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        let contentView = UIView()
        contentView.layer.cornerRadius = 5
        contentView.backgroundColor = .black.withAlphaComponent(0.8)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(playButton)
        contentView.addSubview(loadHUD)
        contentView.addSubview(bufferProgressHUD)
        contentView.addSubview(playingProgressHUD)
        
        addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            playButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            playButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            playButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            loadHUD.centerXAnchor.constraint(equalTo: playButton.centerXAnchor),
            loadHUD.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            
            bufferProgressHUD.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            bufferProgressHUD.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            bufferProgressHUD.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            playingProgressHUD.leadingAnchor.constraint(equalTo: bufferProgressHUD.leadingAnchor),
            playingProgressHUD.centerXAnchor.constraint(equalTo: bufferProgressHUD.centerXAnchor),
            playingProgressHUD.centerYAnchor.constraint(equalTo: bufferProgressHUD.centerYAnchor)
        ])
    }
}

class VideoZoomCell: UIView, UIScrollViewDelegate, UIGestureRecognizerDelegate, LanternCell, LanternZoomSupportedCell {
    
    /// 弱引用PhotoBrowser
    weak var lantern: Lantern?
    
    var frameChangedHandler: ((CGRect) -> Void)?
    var dismissHandler: (() -> Void)?
    var singleTapHandler: (() -> Void)?
    
    var videoURL: URL? {
        didSet {
            guard let videoURL else { return }
            let currentAsset = playerItem?.asset as? AVURLAsset
            
            if currentAsset == nil || currentAsset!.url != videoURL {
                let name = videoURL.relativeString.md5 + "." + videoURL.relativeString.split(separator: ".").last!
                let filePath = FileHelper.shared.exsit(path: videoURL.absoluteString, name: name)
                let options = ["AVURLAssetOutOfBandMIMETypeKey": "video/mp4; codecs=\"avc1.42E01E, mp4a.40.2\""]
                let asset = AVURLAsset(url: filePath != nil ? URL(string: "file://" + filePath!)! : videoURL, options: options)
                print("=====asset:\(asset.url)")
                playerItem = AVPlayerItem(asset: asset)
                removePlayerItemObservers()
                player.replaceCurrentItem(with: playerItem)
                addPlayerItemObservers()
            }
        }
    }
    
    func play() {
        if playControlView.progress >= 1.0 {
            player.seek(to: .zero)
        }
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    var index: Int = 0
    
    private var player = AVPlayer()
    private lazy var playerLayer = AVPlayerLayer(player: player)
    private var playerItem: AVPlayerItem?
    
    var imageView: UIImageView = {
        let v = UIImageView()
        v.backgroundColor = .black
        v.clipsToBounds = true
        
        return v
    }()
    
    var scrollView: UIScrollView = {
        let v = UIScrollView()
        v.maximumZoomScale = 2.0
        v.showsVerticalScrollIndicator = false
        v.showsHorizontalScrollIndicator = false
        v.contentInsetAdjustmentBehavior = .never

        return v
    }()
    
    private lazy var playButton: UIButton = {
        let v = UIButton(type: .system)
        v.setBackgroundImage(UIImage(systemName: "play.circle"), for: .normal)
        v.setBackgroundImage(UIImage(systemName: "pause.circle"), for: .selected)
        v.tintColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    private let playControlView: PlayControlView = {
        let v = PlayControlView()
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    private var playerTimeObserver: Any?
    private var playerObserver: NSKeyValueObservation?
    
    private var playerItemObserver: NSKeyValueObservation?
    private var playerItemLoadObserver: NSKeyValueObservation?
    
    private var playerLayerObserver: NSKeyValueObservation?
    
    deinit {
        removePlayerObservers()
        removePlayerItemObservers()
        LanternLog.high("deinit - \(self.classForCoder)")
    }
    
    public required override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    /// 生成实例
    public static func generate(with lantern: Lantern) -> Self {
        let cell = Self.init(frame: .zero)
        cell.lantern = lantern
        return cell
    }
    
    func setup() {
        backgroundColor = .clear
        scrollView.delegate = self
        addSubview(scrollView)
        scrollView.addSubview(imageView)
//        imageView.addSubview(playButton)
        addSubview(playControlView)
        
        NSLayoutConstraint.activate([
//            playButton.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
//            playButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
//            playButton.heightAnchor.constraint(equalToConstant: 44),
//            playButton.widthAnchor.constraint(equalToConstant: 44),
            
            playControlView.centerXAnchor.constraint(equalTo: centerXAnchor),
            playControlView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            playControlView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
        
        imageView.layer.addSublayer(playerLayer)
        
        playControlView.onPlay = { [weak self] isPlay in
            if isPlay {
                self?.play()
            } else {
                self?.pause()
            }
        }
        /// 拖动手势
        addPanGesture()
        // 单击手势
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(onSingleTap(_:)))
        addGestureRecognizer(singleTap)
        
        addPlayerObservers()
    }

    private func addPlayerObservers() {
        playerTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 100), queue: DispatchQueue.main, using: { [weak self] timeInterval in
            guard let self else { return }
            print("======paused")
            playControlView.progress = Float(CMTimeGetSeconds(timeInterval))
        })

        playerObserver = player.observe(\.timeControlStatus, options: [.new, .old]) { [weak self] (object, change) in
            guard let self else { return }
            switch object.timeControlStatus {
            case .paused:
                print("======paused")
                playControlView.reset()
            case .playing:
                print("======playing")
                playControlView.stopLoading()
                saveToLocal()
            case .waitingToPlayAtSpecifiedRate:
                print("======waitingToPlayAtSpecifiedRate")
            }
        }
    }
    
    private func removePlayerObservers() {
        player.removeTimeObserver(playerTimeObserver)
        playerObserver?.invalidate()
        playerObserver = nil
    }
    
    private func addPlayerItemObservers() {
        playerItemLoadObserver = playerItem?.observe(\.loadedTimeRanges, changeHandler: { [weak self] (object, change) in
            // 获取已缓冲的时间范围
            guard let self, let timeRange = object.loadedTimeRanges.first?.timeRangeValue else { return }

            // 计算已缓冲的进度
            let bufferedTime = CMTimeGetSeconds(CMTimeAdd(timeRange.start, timeRange.duration))
            let duration = CMTimeGetSeconds(object.duration)
            let bufferProgress = bufferedTime / duration
            print("======bufferProgress")
            playControlView.bufferProgress = Float(bufferProgress)
        })
    }

    private func removePlayerItemObservers() {
        playerItemObserver?.invalidate()
        playerItemObserver = nil
        
        playerItemLoadObserver?.invalidate()
        playerItemLoadObserver = nil
    }
    
    private func hiddenProgressHUD(hidden: Bool = true) {
        UIView.animate(withDuration: 0.2) { [self] in
            playControlView.alpha = hidden ? 0.0 : 1.0
        }
    }
    
    private func saveToLocal() {
        let name = videoURL!.relativeString.md5 + "." + videoURL!.relativeString.split(separator: ".").last!
        guard FileHelper.shared.exsit(path: videoURL!.relativeString, name: name) == nil else { return }
        
        let task = URLSession.shared.downloadTask(with: URLRequest(url: videoURL!)) { [weak self] tempURL, response, error in
            print("r=======:\(response)")
            guard let self, let tempURL else { return }
            
            FileHelper.shared.saveVideo(from: tempURL.relativeString, name: name)
        }
        task.resume()
    }
    
    private weak var existedPan: UIPanGestureRecognizer?
    
    /// 添加拖动手势
    private func addPanGesture() {
        guard existedPan == nil else {
            return
        }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        pan.delegate = self
        // 必须加在图片容器上，否则长图下拉不能触发
        scrollView.addGestureRecognizer(pan)
        existedPan = pan
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        scrollView.setZoomScale(1.0, animated: false)
        let size = computeImageLayoutSize(for: imageView.image, in: scrollView)
        let origin = computeImageLayoutOrigin(for: size, in: scrollView)
        imageView.frame = CGRect(origin: origin, size: size)
        scrollView.setZoomScale(1.0, animated: false)
        playerLayer.frame = CGRect(origin: .zero, size: size)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.center = computeImageLayoutCenter(in: scrollView)
    }
    
    func computeImageLayoutSize(for image: UIImage?, in scrollView: UIScrollView) -> CGSize {
        guard let imageSize = image?.size, imageSize.width > 0 && imageSize.height > 0 else {
            return .zero
        }
        var width: CGFloat
        var height: CGFloat
        let containerSize = scrollView.bounds.size
        if containerSize.width < containerSize.height {
            width = containerSize.width
            height = imageSize.height / imageSize.width * width
        } else {
            height = containerSize.height
            width = imageSize.width / imageSize.height * height
            if width > containerSize.width {
                width = containerSize.width
                height = imageSize.height / imageSize.width * width
            }
        }
        
        return CGSize(width: width, height: height)
    }
    
    func computeImageLayoutOrigin(for imageSize: CGSize, in scrollView: UIScrollView) -> CGPoint {
        let containerSize = scrollView.bounds.size
        var y = (containerSize.height - imageSize.height) * 0.5
        y = max(0, y)
        var x = (containerSize.width - imageSize.width) * 0.5
        x = max(0, x)
        return CGPoint(x: x, y: y)
    }
    
    func computeImageLayoutCenter(in scrollView: UIScrollView) -> CGPoint {
        var x = scrollView.contentSize.width * 0.5
        var y = scrollView.contentSize.height * 0.5
        let offsetX = (bounds.width - scrollView.contentSize.width) * 0.5
        if offsetX > 0 {
            x += offsetX
        }
        let offsetY = (bounds.height - scrollView.contentSize.height) * 0.5
        if offsetY > 0 {
            y += offsetY
        }
        return CGPoint(x: x, y: y)
    }
    
    /// 单击
    @objc open func onSingleTap(_ tap: UITapGestureRecognizer) {
//        lantern?.dismiss()
    }
    /// 记录pan手势开始时imageView的位置
    private var beganFrame = CGRect.zero
    
    /// 记录pan手势开始时，手势位置
    private var beganTouch = CGPoint.zero
    
    /// 响应拖动
    @objc open func onPan(_ pan: UIPanGestureRecognizer) {
        guard imageView.image != nil else {
            return
        }
        switch pan.state {
        case .began:
            beganFrame = imageView.frame
            beganTouch = pan.location(in: scrollView)
            hiddenProgressHUD()
        case .changed:
            let result = panResult(pan)
            imageView.frame = result.frame
            frameChangedHandler?(result.frame)
            
            lantern?.maskView.alpha = result.scale * result.scale
            lantern?.setStatusBar(hidden: result.scale > 0.99)
            lantern?.pageIndicator?.isHidden = result.scale < 0.99
        case .ended, .cancelled:
            imageView.frame = panResult(pan).frame
            frameChangedHandler?(panResult(pan).frame)
            
            lantern?.dismiss()
            dismissHandler?()
            
//            let isDown = pan.velocity(in: self).y > 0
//            if isDown {
//                lantern?.dismiss()
//                dismissHandler?()
//            } else {
//                hiddenProgressHUD(hidden: false)
//                lantern?.maskView.alpha = 1.0
//                lantern?.setStatusBar(hidden: true)
//                lantern?.pageIndicator?.isHidden = false
//                resetImageViewPosition()
//            }
        default:
            resetImageViewPosition()
        }
    }
    
    /// 计算拖动时图片应调整的frame和scale值
    private func panResult(_ pan: UIPanGestureRecognizer) -> (frame: CGRect, scale: CGFloat) {
        // 拖动偏移量
        let translation = pan.translation(in: scrollView)
        let currentTouch = pan.location(in: scrollView)
        
        // 由下拉的偏移值决定缩放比例，越往下偏移，缩得越小。scale值区间[0.3, 1.0]
        let scale = min(1.0, max(0.3, 1 - translation.y / bounds.height))
        
        let width = beganFrame.size.width * scale
        let height = beganFrame.size.height * scale
        
        // 计算x和y。保持手指在图片上的相对位置不变。
        // 即如果手势开始时，手指在图片X轴三分之一处，那么在移动图片时，保持手指始终位于图片X轴的三分之一处
        let xRate = (beganTouch.x - beganFrame.origin.x) / beganFrame.size.width
        let currentTouchDeltaX = xRate * width
        let x = currentTouch.x - currentTouchDeltaX
        
        let yRate = (beganTouch.y - beganFrame.origin.y) / beganFrame.size.height
        let currentTouchDeltaY = yRate * height
        let y = currentTouch.y - currentTouchDeltaY
        
        return (CGRect(x: x.isNaN ? 0 : x, y: y.isNaN ? 0 : y, width: width, height: height), scale)
    }
    
    /// 复位ImageView
    private func resetImageViewPosition() {
        // 如果图片当前显示的size小于原size，则重置为原size
        let size = computeImageLayoutSize(for: imageView.image, in: scrollView)
        let needResetSize = imageView.bounds.size.width < size.width || imageView.bounds.size.height < size.height
        UIView.animate(withDuration: 0.25) {
            self.imageView.center = self.computeImageLayoutCenter(in: self.scrollView)
            if needResetSize {
                self.imageView.bounds.size = size
            }
        }
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 只处理pan手势
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        let velocity = pan.velocity(in: self)
        // 向上滑动时，不响应手势
        if velocity.y < 0 {
            return false
        }
        // 横向滑动时，不响应pan手势
        if abs(Int(velocity.x)) > Int(velocity.y) {
            return false
        }
        // 向下滑动，如果图片顶部超出可视区域，不响应手势
        if scrollView.contentOffset.y > 0 {
            return false
        }
        // 响应允许范围内的下滑手势
        return true
    }
    
    var showContentView: UIView {
        return imageView
    }
}
