
import Foundation
import Photos
import UIKit
import ZLPhotoBrowser
import SVProgressHUD

public class PhotoHelper {
    public var didPhotoSelected: ((_ images: [UIImage], _ assets: [PHAsset], _ isOriginPhoto: Bool) -> Void)?

    public var didPhotoSelectedCancel: (() -> Void)?

    public var didCameraFinished: ((UIImage?, URL?) -> Void)?

    public init() {
        resetConfigToSendMedia()
    }

    func resetConfigToSendMedia() {
        let editConfig = ZLPhotoConfiguration.default().editImageConfiguration
        editConfig.tools([.draw, .clip, .textSticker, .mosaic])
        ZLPhotoConfiguration.default().editImageConfiguration(editConfig)
            .canSelectAsset { _ in true }
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

    public func setConfigToPickAvatar() {
        let editConfig = ZLPhotoConfiguration.default().editImageConfiguration
        editConfig.tools([.clip])
            .clipRatios([ZLImageClipRatio.wh1x1])
        ZLPhotoConfiguration.default().maxSelectCount(1)
            .editAfterSelectThumbnailImage(true)
            .allowRecordVideo(false)
            .allowMixSelect(false)
            .allowSelectGif(false)
            .allowSelectVideo(false)
            .allowSelectLivePhoto(false)
            .allowSelectOriginal(false)
            .editImageConfiguration(editConfig)
            .showClipDirectlyIfOnlyHasClipTool(true)
            .canSelectAsset { _ in false }
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
    }

    func presentPhotoLibraryOnlyEdit(byController: UIViewController) {
        let sheet = ZLPhotoPreviewSheet(selectedAssets: nil)
        sheet.selectImageBlock = didPhotoSelected
        sheet.cancelBlock = didPhotoSelectedCancel
        sheet.showPhotoLibrary(sender: byController)
    }

    public func presentPhotoLibrary(byController: UIViewController) {
        let sheet = ZLPhotoPreviewSheet(selectedAssets: nil)
        sheet.selectImageBlock = didPhotoSelected
        sheet.cancelBlock = didPhotoSelectedCancel
        sheet.showPhotoLibrary(sender: byController)
    }

    public func presentCamera(byController: UIViewController) {
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
        let asset = AVURLAsset(url: url)
        let assetGen = AVAssetImageGenerator(asset: asset)
        assetGen.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: .zero, preferredTimescale: 600)
        var actualTime: CMTime = .zero
        DispatchQueue.global().async { [weak messageSender] in
            do {
                let cgImage = try assetGen.copyCGImage(at: time, actualTime: &actualTime)
                let thumbnail = UIImage(cgImage: cgImage)
                let result = FileHelper.shared.saveImage(image: thumbnail)
                let thumbnailPath = result.relativeFilePath
                messageSender?.sendVideo(path: url, thumbnailPath: thumbnailPath, duration: Int(asset.duration.seconds))
            } catch {
                #if DEBUG
                    print("获取视频帧错误:", error)
                #endif
            }
        }
    }

    func preview(message: MessageInfo, from controller: UIViewController) {
        switch message.contentType {
        case .image:
            var tmpURL: URL?
            if let imageUrl = message.pictureElem?.sourcePicture?.url, let url = URL(string: imageUrl) {
                tmpURL = url
            } else if let imageUrl = message.pictureElem?.sourcePath {
                let url = URL(fileURLWithPath: imageUrl)
                if FileManager.default.fileExists(atPath: url.path) {
                    tmpURL = url
                }
            }

            if let tmpURL = tmpURL {
                let previewController = ZLImagePreviewController(datas: [tmpURL], index: 0, showSelectBtn: false, showBottomView: false) { _ in
                    .image
                } urlImageLoader: { url, imageView, progress, loadFinish in
                    imageView.kf.setImage(with: url) { receivedSize, totalSize in
                        let percentage = (CGFloat(receivedSize) / CGFloat(totalSize))
                        debugPrint("progress: \(percentage)")
                        progress(percentage)
                    } completionHandler: { _ in
                        loadFinish()
                    }
                }
                previewController.modalPresentationStyle = .fullScreen
                controller.showDetailViewController(previewController, sender: nil)
            }
        case .video:
            var tmpURL: URL?
            if let videoUrl = message.videoElem?.videoUrl, let url = URL(string: videoUrl) {
                tmpURL = url
            } else if let videoUrl = message.videoElem?.videoPath {
                let url = URL(fileURLWithPath: videoUrl)
                if FileManager.default.fileExists(atPath: url.path) {
                    tmpURL = url
                }
            }

            if let tmpURL = tmpURL {
                let previewController = ZLImagePreviewController(datas: [tmpURL], index: 0, showSelectBtn: false, showBottomView: false) { _ in
                    .video
                } urlImageLoader: { url, imageView, progress, loadFinish in
                    imageView.kf.setImage(with: url) { receivedSize, totalSize in
                        let percentage = (CGFloat(receivedSize) / CGFloat(totalSize))
                        debugPrint("\(percentage)")
                        progress(percentage)
                    } completionHandler: { _ in
                        loadFinish()
                    }
                }
                previewController.modalPresentationStyle = .fullScreen
                controller.showDetailViewController(previewController, sender: nil)
            }
        default:
            break
        }
    }

    private func compressAndSendMp4(asset: PHAsset, thumbnail: UIImage?, messageSender: MessageListViewModel) {
        let fileHelper = FileHelper.shared
        var thumbnailPath = ""
        if let thumbnail = thumbnail {
            let result = fileHelper.saveImage(image: thumbnail)
            thumbnailPath = result.relativeFilePath
        }
        ZLVideoManager.exportVideo(for: asset, exportType: .mp4) { [weak messageSender] (url: URL?, _: Error?) in
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
