
import Foundation

public class FileHelper {
    public static let shared: FileHelper = .init()

    let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/"
    let imageDirectory = "OpenIM/image/"
    let audioDirectory = "OpenIM/audio/"
    let videoDirectory = "OpenIM/video/"
    let fileDirecotory = "OpenIM/file/"

    init() {
        createDirectoryIfNotExist(path: documents + imageDirectory)
        createDirectoryIfNotExist(path: documents + audioDirectory)
        createDirectoryIfNotExist(path: documents + videoDirectory)
        createDirectoryIfNotExist(path: documents + fileDirecotory)
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
    
    func getFileName(with fileType: String) -> String {
        return "file_\(getCurrentTime()).\(fileType)"
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
    
    private func copyFile(path: String, toPath: String) -> Bool {
        do {
            try FileManager.default.copyItem(atPath: path, toPath: toPath)
        } catch {
            print("文件copy失败：\(error)")
            return false
        }

        return true
    }
    
    private func removeFile(path: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            print("删除文件失败：\(error)")
            return false
        }

        return true
    }
    
    // fileName: 链接最后的名字
    public func exsit(path: String, name: String? = nil) -> String? {
        let ext = path.split(separator: ".").last!
        let fileName = name ?? "\(path.md5).\(ext)"
        
        let imagePath = documents + imageDirectory + fileName
        
        if FileManager.default.fileExists(atPath: imagePath) {
            return imagePath
        }
        
        let videoPath = documents + videoDirectory + fileName
        
        if FileManager.default.fileExists(atPath: videoPath) {
            return videoPath
        }
        
        let audioPath = documents + audioDirectory + fileName

        if FileManager.default.fileExists(atPath: audioPath) {
            return audioPath
        }
        
        let filePath = documents + fileDirecotory + fileName
        
        if FileManager.default.fileExists(atPath: filePath) {
            return filePath
        }
        
        return nil
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

    public func saveAudio(from path: String, name: String? = nil) -> FileWriteResult {
        let ext = path.split(separator: ".").last!
        let fileName = name ?? "\(path.md5).\(ext)"
        let filePath = documents + audioDirectory + fileName
        print("源路径:\(path) 移动目标路径:\(filePath)")
        if !moveFile(path: path, toPath: filePath) {
            return FileWriteResult(relativeFilePath: "", fullPath: "", isSuccess: false)
        }
        
        return FileWriteResult(relativeFilePath: audioDirectory + fileName, fullPath: filePath, isSuccess: true)
    }

    public func saveVideo(from path: String, name: String? = nil) -> FileWriteResult {
        let ext = path.split(separator: ".").last!
        let fileName = name ?? "\(path.md5).\(ext)"
        let filePath = documents + videoDirectory + fileName

        if !moveFile(path: path, toPath: filePath) {
            return FileWriteResult(relativeFilePath: "", fullPath: "", isSuccess: false)
        }

        return FileWriteResult(relativeFilePath: videoDirectory + fileName, fullPath: filePath, isSuccess: true)
    }
    
    public func saveFile(from path: String, name: String? = nil) -> FileWriteResult {
        let ext = path.split(separator: ".").last!
        let fileName = name ?? "\(path.md5).\(ext)"
        let toPath = documents + fileDirecotory + fileName

        if !copyFile(path: path, toPath: toPath) {
            return FileWriteResult(relativeFilePath: "", fullPath: "", isSuccess: false)
        }

        return FileWriteResult(relativeFilePath: fileDirecotory + fileName, fullPath: toPath, isSuccess: true)
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
        format.dateFormat = "yyyy-MM-dd-mm-ss.SSS"
        let fileName = format.string(from: Date())
        return fileName
    }
    
    public static func formatLength(length: Int) -> String {
        
        let kb = 1024;
        let mb = kb * 1024;
        let gb = mb * 1024;
        
        if (length >= gb) {
            
            return String.init(format: "%.1f GB", Float(length) / Float(gb))
        } else if (length >= mb) {
            
            let f = Float(length) / Float(mb);
            if (f > 100) {
                return String.init(format: "%.0f MB", f)
            } else {
                return String.init(format: "%.1f MB", f)
            }
        } else if (length >= kb) {
            
            let f = Float(length) / Float(kb)
            if (f > 100) {
                return String.init(format: "%.0f KB", f)
            } else {
                return String.init(format: "%.1f KB", f)
            }
        } else {
            return String.init(format: "%lld B", length)
        }
    }

    public struct FileWriteResult {
        public let relativeFilePath: String
        public let fullPath: String
        public let isSuccess: Bool
    }
}

extension UIImage {
    public func compress(to maxSize: Int) -> UIImage {
        if let size = self.jpegData(compressionQuality: 1)?.count, size <= maxSize {
            return self
        }
        var min: CGFloat = 0
        var max: CGFloat = 1
        var data: Data?
        for _ in 0..<6 {
            let mid = (min + max) / 2
            data = self.jpegData(compressionQuality: mid)
            let compressSize = data?.count ?? 0
            if compressSize > maxSize {
                max = mid
            } else if compressSize < maxSize {
                min = mid
            } else {
                break
            }
        }
        guard let d = data else {
            return self
        }
        return UIImage(data: d) ?? self
    }
}
