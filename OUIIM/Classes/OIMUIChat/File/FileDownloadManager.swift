
import Alamofire

struct DownloadCallBack {
    typealias DownloadProgressReturnVoid = (String, Int, Int) -> Void
    typealias CompletionReturnVoid = (String, URL) -> Void
}

public struct FileDownloadRequest {
    let request: DownloadRequest
}

public class FileDownloadManager {
    static let manager = FileDownloadManager()
    
    private let progressKey = "progressKey"
    private let completionKey = "completionKey"
    private let messageIDKey = "messageIDKey"
    private let downloader = FileDownloader()
    private var tasksHandlers: [Int: [String: Any]] = [:]
        
    func downloadMessageFile(messageID: String,
                             url: URL,
                             name: String? = nil,
                             progress: DownloadCallBack.DownloadProgressReturnVoid? = nil,
                             completion: DownloadCallBack.CompletionReturnVoid? = nil) -> FileDownloadRequest? {
        
        guard let url = try? url.asURL() else { return nil }
        
        let request = downloader.download(url, name: name)
        guard let taskIdentifier = request.task?.taskIdentifier else { return nil }
        
        tasksHandlers[taskIdentifier] = [progressKey: progress,
                                       completionKey: completion,
                                        messageIDKey: messageID]
        downloader.manager.delegate.taskDidComplete = { [weak self] (session, task, error) in
            if let error {
                if let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    self?.downloader.resumeData = resumeData
                }
            } else {
                print("taskDidComplete: \(task)")
            }
        }
        
        downloader.manager.delegate.downloadTaskDidFinishDownloadingToURL = { [weak self] (session, downloadTask, location) in
            guard let self,
                  let completion = self.tasksHandlers[downloadTask.taskIdentifier]?[self.completionKey] as? DownloadCallBack.CompletionReturnVoid,
                  let messageID = self.tasksHandlers[downloadTask.taskIdentifier]?[self.messageIDKey] as? String else { return }
            do {
                let des = URL.init(fileURLWithPath: downloader.filePath)
                try FileManager.default.moveItem(at: location, to: des)
                completion(messageID, des)
            } catch let error {
                print("downloadTaskDidFinishDownloadingToURL - error: \(error.localizedDescription)")
            }
        }
        
        downloader.manager.delegate.downloadTaskDidWriteData = { [weak self] (session, downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
            guard let self,
                  let progress = self.tasksHandlers[downloadTask.taskIdentifier]?[self.progressKey] as? DownloadCallBack.DownloadProgressReturnVoid,
                  let messageID = self.tasksHandlers[downloadTask.taskIdentifier]?[self.messageIDKey] as? String else { return }
            progress(messageID, Int(totalBytesWritten), Int(totalBytesExpectedToWrite))
        }
        
        return FileDownloadRequest(request: request)
    }
}


class FileDownloader: NSObject {
    var resumeData: Data?
    var request: DownloadRequest?
    public private(set) var filePath: String!
    
    lazy var manager: SessionManager = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.oim.file.download.manager.session.manager")
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.sharedContainerIdentifier = "com.oim.file.download.manager.session.manager"
        let manager = SessionManager(configuration: configuration)
        manager.startRequestsImmediately = true
        
        return manager
    }()
    
    func download(_ url: URLConvertible, name: String? = nil) -> DownloadRequest {
        let ext = try! url.asURL().absoluteString.split(separator: ".").last!
        var r = name
        
        if r == nil {
            r = try! url.asURL().md5 + ".\(ext)"
        }

        filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/\(r!)"
        print("下载地址:\(filePath)")
        
        let destination: DownloadRequest.DownloadFileDestination = { [weak self] _, _ in
            return (URL(string: self!.filePath)!, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        if self.resumeData != nil {
            request = manager.download(resumingWith: self.resumeData!)
        } else {
            if let resumeData = request?.resumeData {
                request = manager.download(resumingWith: resumeData)
            } else {
                request = manager.download(url, to: destination)
            }
        }
        return request!
    }
}
