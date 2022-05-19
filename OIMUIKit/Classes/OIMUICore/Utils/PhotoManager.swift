//






import Foundation
import Photos
import ZLPhotoBrowser
import UIKit

class PhotoHelper {
    
    var didPhotoSelected: ((_ images: [UIImage], _ assets: [PHAsset], _ isOriginPhoto: Bool) -> Void)?
    
    var didPhotoSelectedCancel: (() -> Void)?
    
    var didCameraFinished: ((UIImage?, URL?) -> Void)?
    
    init() {
        let editConfig = ZLPhotoConfiguration.default().editImageConfiguration
        editConfig.tools([.draw, .clip, .textSticker, .mosaic])
        ZLPhotoConfiguration.default().editImageConfiguration(editConfig)
            .canSelectAsset({_ in true})
            .navCancelButtonStyle(.text)
            .noAuthorityCallback { (authType: ZLNoAuthorityType) in
                switch authType {
                case .library:
                    debugPrint("No library authority")
                case .camera:
                    debugPrint("No camera authority")
                case .microphone:
                    debugPrint("No microphone authority")
                }
            }
        ZLPhotoConfiguration.default().cameraConfiguration.videoExportType = .mp4
    }
    
    func presentPhotoLibrary(byController: UIViewController) {
        let sheet = ZLPhotoPreviewSheet.init(selectedAssets: nil)
        sheet.selectImageBlock = didPhotoSelected
        sheet.cancelBlock = didPhotoSelectedCancel
        sheet.showPhotoLibrary(sender: byController)
    }
    
    func presentCamera(byController: UIViewController) {
        let camera = ZLCustomCamera()
        camera.takeDoneBlock = didCameraFinished
        byController.showDetailViewController(camera, sender: nil)
    }
    
    func sendMediaTuple(assets: [MediaTuple], with messageSender: MessageListViewModel) {
        for tuple in assets {
            let asset = tuple.asset
            switch asset.mediaType {
            case .video:
                compressAndSendMp4(asset: asset, thumbnail: tuple.thumbnail, messageSender: messageSender)
            case .image:
                messageSender.sendImage(image: tuple.thumbnail)
            default:
                break
            }
        }
    }
    
    func sendVideoAt(url: URL, messageSender: MessageListViewModel) {
        let asset = AVURLAsset.init(url: url)
        let assetGen = AVAssetImageGenerator.init(asset: asset)
        assetGen.appliesPreferredTrackTransform = true
        let time = CMTime.init(seconds: .zero, preferredTimescale: 600)
        var actualTime: CMTime = .zero
        DispatchQueue.global().async { [weak messageSender] in
            do {
                let cgImage = try assetGen.copyCGImage(at: time, actualTime: &actualTime)
                let thumbnail = UIImage.init(cgImage: cgImage)
                let result = FileHelper.shared.saveImage(image: thumbnail)
                let thumbnailPath = result.filePath
                messageSender?.sendVideo(path: url, thumbnailPath: thumbnailPath, duration: Int(asset.duration.seconds))
            } catch {
                #if DEBUG
                print("获取视频帧错误:", error)
                #endif
            }
        }
    }
    
    private func compressAndSendMp4(asset: PHAsset, thumbnail: UIImage?, messageSender: MessageListViewModel) {
        let fileHelper = FileHelper.shared
        var thumbnailPath: String = ""
        if let thumbnail = thumbnail {
            let result = fileHelper.saveImage(image: thumbnail)
            thumbnailPath = result.filePath
        }
        ZLVideoManager.exportVideo(for: asset, exportType: .mp4) { [weak messageSender] (url: URL?, error: Error?) in
            guard let url = url else { return }
            messageSender?.sendVideo(path: url, thumbnailPath: thumbnailPath, duration: Int(asset.duration))
        }
    }
    
    struct MediaTuple {
        let thumbnail: UIImage
        let asset: PHAsset
    }
    
    deinit {
#if DEBUG
        print("dealloc \(type(of: self))")
#endif
    }
}
