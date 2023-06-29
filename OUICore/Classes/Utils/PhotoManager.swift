
import Foundation
import Photos
import UIKit
import ZLPhotoBrowser
import ProgressHUD

open class PhotoHelper {
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
    
    public func setConfigToMultipleSelected(forVideo: Bool = false, maxSelectCount: Int = 9) {
     
        let config = ZLPhotoConfiguration.default()
        config.allowSelectImage = !forVideo
        config.allowSelectVideo = forVideo
        config.allowSelectGif = false
        config.allowSelectLivePhoto = false
        config.allowSelectOriginal = false
        config.cropVideoAfterSelectThumbnail = true
        config.allowEditVideo = true
        config.allowMixSelect = false
        config.maxSelectCount = maxSelectCount
        config.maxEditVideoTime = 15
        
        
        let cameraConfig = ZLCameraConfiguration()
        cameraConfig.sessionPreset = .vga640x480
        config.cameraConfiguration = cameraConfig
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

    public static func getVideoAt(url: URL, handler: @escaping (_ main: FileHelper.FileWriteResult, _ thumb: FileHelper.FileWriteResult, _ duration: Int) -> Void) {
        let asset = AVURLAsset(url: url)
        let assetGen = AVAssetImageGenerator(asset: asset)
        assetGen.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: .zero, preferredTimescale: 600)
        var actualTime: CMTime = .zero
        DispatchQueue.global().async {
            do {
                let cgImage = try assetGen.copyCGImage(at: time, actualTime: &actualTime)
                let thumbnail = UIImage(cgImage: cgImage)
                let result = FileHelper.shared.saveImage(image: thumbnail)
                let p = FileHelper.shared.saveVideo(from: url.path)
                handler(p, result, Int(asset.duration.seconds))
            } catch {
                #if DEBUG
                    print("获取视频帧错误:", error)
                #endif
            }
        }
    }
    
    public static func getFirstRate(fromVideo: URL, completionHandler: @escaping (_ path: String, _ duration: Int) -> Void) {
        
        let asset = AVURLAsset(url: fromVideo)
        let assetGen = AVAssetImageGenerator(asset: asset)
        assetGen.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: .zero, preferredTimescale: 600)
        var actualTime: CMTime = .zero
        DispatchQueue.global().async {
            do {
                let cgImage = try assetGen.copyCGImage(at: time, actualTime: &actualTime)
                let thumbnail = UIImage(cgImage: cgImage)
                let result = FileHelper.shared.saveImage(image: thumbnail)
                let thumbnailPath = result.fullPath
                completionHandler(thumbnailPath, Int(asset.duration.seconds))
            } catch {
                #if DEBUG
                    print("获取视频帧错误:", error)
                #endif
                completionHandler("", 0)
            }
        }
    }
    
    public func showSelectMetaSheet(byController: UIViewController) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photoAction = UIAlertAction(title: "从相册选取", style: .default, handler: { [weak self] (alert) -> Void in
            guard let sself = self else {
                return
            }
            sself.presentPhotoLibrary(byController: byController)
        })
        
        let cameraAction = UIAlertAction(title: "拍摄", style: .default, handler: { [weak self] (alert) -> Void in
            guard let sself = self else {
                return
            }
            sself.presentCamera(byController: byController)
        })
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil )
        
        alertController.addAction(photoAction)
        alertController.addAction(cameraAction)
        alertController.addAction(cancelAction)
        byController.present(alertController, animated: true, completion: nil)
    }
    
    // 预览图片
    public func browserImages(_ images: [String], thumbsURL: [String] = [], forVideo: Bool = false, redirect: Bool = false, index: Int) {
        guard images.count > 0 else { return }
        
//        if redirect {
            let connection = URLSession.shared
            let originPath = images[0]
            let name = originPath.md5 + ".\(originPath.split(separator: ".").last!)"
//            var fullPath = FileHelper.shared.exsit(path: originPath, name: name)
//            if let fullPath {
//                browserHelper(paths: ["file://" + fullPath], forVideo: forVideo, index: index)
//            } else {
                ProgressHUD.show(interaction: false)
                let task = connection.dataTask(with: URLRequest(url: URL(string: originPath)!)) { [self] data, responose, error in
                    if let path = responose?.url?.relativeString, let url = URL(string: path) {
                        DispatchQueue.main.async {
                            ProgressHUD.dismiss()
                            print("重定向地址：\(url)")
                            browserHelper(paths: [path], thumbsURL: thumbsURL, forVideo: forVideo, index: index)
                        }
//                        let downloadTask = connection.downloadTask(with: URLRequest(url: url)) { url, response, error in
//
//                            fullPath = FileHelper.shared.saveVideo(from: url!.path, name: name).fullPath
//                            DispatchQueue.main.async {
//                                ProgressHUD.dismiss()
//                                browserHelper(paths: ["file://" + fullPath!], forVideo: forVideo, index: index)
//                            }
//                        }
//                        downloadTask.resume()
                    }
                }
                
                task.resume()
//            }
//        } else {
//            browserHelper(paths: images, thumbsURL: thumbsURL, forVideo: forVideo, index: index)
//        }
    }
    
    private func browserHelper(paths: [String], thumbsURL: [String] = [], forVideo: Bool, index: Int) {
        let previewController = ZLImagePreviewController(datas: paths.compactMap({ URL(string: $0) }), index: index, showSelectBtn: false, showBottomView: true) { _ in
            return forVideo ? .video : .image
        } urlImageLoader: { url, imageView, progress, loadFinish in
            imageView.kf.setImage(with: URL(string: thumbsURL.first!)) { receivedSize, totalSize in
                let percentage = (CGFloat(receivedSize) / CGFloat(totalSize))
                debugPrint("\(percentage)")
                progress(percentage)
            } completionHandler: { _ in
                loadFinish()
            }
        }
        previewController
        previewController.modalPresentationStyle = .fullScreen
        var keyWindow: UIWindow
        if #available(iOS 13.0, *) {
            keyWindow = (UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first)!
        } else {
            // Fallback on earlier versions
            keyWindow = UIApplication.shared.keyWindow!
        }
        
        keyWindow.rootViewController?.showDetailViewController(previewController, sender: nil)
    }

    public func preview(message: MessageInfo, from controller: UIViewController) {
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

    public static func compressVideoToMp4(asset: PHAsset, thumbnail: UIImage?, handler: @escaping (_ main: FileHelper.FileWriteResult, _ thumb: FileHelper.FileWriteResult, _ duration: Int) -> Void) {
        let fileHelper = FileHelper.shared
        let thumbnail = fileHelper.saveImage(image: thumbnail!)

        ZLVideoManager.exportVideo(for: asset, exportType: .mp4) { (url: URL?, _: Error?) in
            guard let url = url else { return }
            let p = fileHelper.saveVideo(from: url.path)
            handler(p, thumbnail, Int(asset.duration))
        }
    }
    
    public static func saveImage(image: UIImage) -> String {
        let result = FileHelper.shared.saveImage(image: image)
        
        return result.fullPath
    }

    public struct MediaTuple {
        let thumbnail: UIImage
        let asset: PHAsset
        public init(thumbnail: UIImage, asset: PHAsset) {
            self.thumbnail = thumbnail
            self.asset = asset
        }
    }

    deinit {
        #if DEBUG
            print("dealloc \(type(of: self))")
        #endif
    }
}
