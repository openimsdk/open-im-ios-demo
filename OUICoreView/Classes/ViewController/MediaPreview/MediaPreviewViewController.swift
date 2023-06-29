
import Lantern
import AVKit
import Kingfisher
import ProgressHUD

public enum PreviewMediaType {
    case image
    case video
    case gif
}

public struct MediaResource {
    let thumbUrl: String?
    let url: String
    let type: PreviewMediaType
    
    public init(thumbUrl: String? = nil, url: String, type: PreviewMediaType = .image) {
        self.thumbUrl = thumbUrl
        self.url = url
        self.type = type
    }
}

public class MediaPreviewViewController: UIViewController {
    
    public init(resources: [MediaResource]) {
        super.init(nibName: nil, bundle: nil)
        self.dataSource = resources
    }
    
    private var dataSource: [MediaResource]!
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let lantern = Lantern()
        
        lantern.numberOfItems = { [weak self] in
            self?.dataSource.count ?? 0
        }
        lantern.cellClassAtIndex = { [weak self] index in
            guard let self else { return ImageZoomCell.self }
            let resource = self.dataSource[index]
            return resource.type == .video ? VideoZoomCell.self : ImageZoomCell.self
        }
        lantern.reloadCellAtIndex = { [weak self] context in
            LanternLog.high("reload cell!")
            guard let resource = self?.dataSource[context.index] else { return }
            if resource.type == .video {
                let lanternCell = context.cell as? VideoZoomCell
                lanternCell?.imageView.setImage(with: resource.thumbUrl)
                lanternCell?.frameChangedHandler = { frame in
                    self?.view.frame = frame
                }
                lanternCell?.dismissHandler = {
                    self?.view.removeFromSuperview()
                    self?.removeFromParent()
                }
                
                // 这里特别注意下，目前SDK给到的地址需要获取重定向地址
                let url = URL(string: resource.url)!
                lanternCell?.videoURL = url
                
            } else {
                let lanternCell = context.cell as? ImageZoomCell
                lanternCell?.imageView.setImage(with: resource.url)
                lanternCell?.frameChangedHandler = { frame in
                    self?.view.frame = frame
                }
                lanternCell?.dismissHandler = {
                    self?.view.removeFromSuperview()
                    self?.removeFromParent()
                }
            }
        }
        lantern.cellWillAppear = { cell, index in
            (cell as? VideoZoomCell)?.play()
        }
        lantern.cellWillDisappear = { cell, index in
            (cell as? VideoZoomCell)?.pause()
        }
        
        lantern.show()
    }
    
    public override var shouldAutorotate: Bool {
        return true
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}
