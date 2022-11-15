
import Foundation

public class FileHelper {
    public static let shared: FileHelper = .init()

    let documents: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/"
    let imageDirectory: String = "OpenIM/image/"
    let audioDirectory: String = "OpenIM/audio/"
    let videoDirectory: String = "OpenIM/video/"

    init() {
        createDirectoryIfNotExist(path: documents + imageDirectory)
        createDirectoryIfNotExist(path: documents + audioDirectory)
        createDirectoryIfNotExist(path: documents + videoDirectory)
    }

    func getVideoName() -> String {
        return "video_\(getCurrentTime()).mp4"
    }

    func getImageName(with fileType: String) -> String {
        return "image_\(getCurrentTime()).\(fileType)"
    }

    func getAudioName() -> String {
        return "voice_\(getCurrentTime()).m4a"
    }

    private func createDirectoryIfNotExist(path: String) {
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            } catch let err {
                print("路径创建错误:\(err)")
            }
        } else {
            print("文件夹存在")
        }
    }

    private func createFileIfNotExist(path: String, data: Data) {
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createFile(atPath: path, contents: data)
            } catch let err {
                print("路径创建错误:\(err)")
            }
        } else {
            print("文件存在")
        }
    }

    private func moveFile(path: String, toPath: String) -> Bool {
        do {
            try FileManager.default.moveItem(atPath: path, toPath: toPath)
        } catch {
            print("文件迁移失败：\(error)")
            return false
        }

        return true
    }

    public func saveImage(image: UIImage) -> FileWriteResult {
        var imageData: Data?
        var fileType = ""
        if let pngData = image.pngData() {
            imageData = pngData
            fileType = "png"
        }
        if imageData == nil {
            imageData = image.jpegData(compressionQuality: 0.6)
            fileType = "jpg"
        }

        guard let imageData = imageData else {
            return FileWriteResult(relativeFilePath: "", fullPath: "", isSuccess: false)
        }

        let data = NSData(data: imageData)
        let fileName = getImageName(with: fileType)
        let filePath = documents + imageDirectory + fileName

        createFileIfNotExist(path: filePath, data: imageData)

        return FileWriteResult(relativeFilePath: imageDirectory + fileName, fullPath: filePath, isSuccess: true)
    }

    func saveAudioFrom(audioPath: String) -> FileWriteResult {
        let fileName = getAudioName()
        let filePath = documents + audioDirectory + fileName

        if !moveFile(path: audioPath, toPath: filePath) {
            return FileWriteResult(relativeFilePath: "", fullPath: "", isSuccess: false)
        }

        return FileWriteResult(relativeFilePath: audioDirectory + fileName, fullPath: filePath, isSuccess: true)
    }

    func saveVideoFrom(videoPath: String) -> FileWriteResult {
        let fileName = getVideoName()
        let filePath = documents + videoDirectory + fileName

        if !moveFile(path: videoPath, toPath: filePath) {
            return FileWriteResult(relativeFilePath: "", fullPath: "", isSuccess: false)
        }

        return FileWriteResult(relativeFilePath: videoDirectory + fileName, fullPath: filePath, isSuccess: true)
    }

    func getContentTypeOf(imageData: NSData) -> String? {
        var c: UInt8?
        imageData.getBytes(&c, length: 1)
        switch c {
        case 0xFF:
            return "jpeg"
        case 0x89:
            return "png"
        case 0x47:
            return "gif"
        case 0x49, 0x4D:
            return "tiff"
        case 0x52:
            if imageData.length < 12 {
                return nil
            }
            let string = NSString(data: imageData.subdata(with: NSRange(location: 0, length: 12)), encoding: String.Encoding.ascii.rawValue) ?? ""
            if string.hasPrefix("RIFF"), string.hasPrefix("WEBP") {
                return "webp"
            }
            return nil
        default:
            return nil
        }
    }

    func isGif(imageData: NSData) -> Bool {
        if getContentTypeOf(imageData: imageData) == "gif" {
            return true
        }
        return false
    }

    private func getCurrentTime() -> String {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd-mm-ss"
        let fileName = format.string(from: Date())
        return fileName
    }

    public struct FileWriteResult {
        public let relativeFilePath: String
        public let fullPath: String
        public let isSuccess: Bool
    }
}
