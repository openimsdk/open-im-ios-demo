






import Foundation

public class FaceManager {
    public static let shared = FaceManager()
    
    var identity = "ISEmojiView"
    
    var images: [FaceEmoji] = []
    var selectedImages: [FaceEmoji] = []
    
    private let faceEmojiDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("FaceEmoji")
    
    public func addImage(_ imageURL: URL, onCompletion: @escaping () -> Void) {
        let newImage = FaceEmoji(imageURL: imageURL, localImagePath: nil, index: images.count)
        images.append(newImage)
        
        DispatchQueue.main.async {
            onCompletion()
        }
        
        saveImageLocally(imageURL) { [weak self] localImagePath in

        }
    }
    
    func removeImage(at index: Int) {
        if let localImagePath = images[index].localImagePath {
            try? FileManager.default.removeItem(atPath: localImagePath)
        }
        images.remove(at: index)
    }
    
    static func faceExists(path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
    
    private func saveImageLocally(_ imageURL: URL, onCompletion: @escaping (String) -> Void){
        DispatchQueue.global().async { [self] in
            
            guard let data = try? Data(contentsOf: imageURL) else { return }
            
            let fileName = "\(UUID().uuidString).\(imageURL.pathExtension)"
            do {
                try FileManager.default.createDirectory(at: faceEmojiDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                let localImagePath = faceEmojiDirectoryURL.appendingPathComponent(fileName)
                print("local Image Path: \(localImagePath.path)")
                
                try data.write(to: localImagePath, options: .atomic)
                onCompletion(localImagePath.path)
            } catch {
                print("Error saving image locally: \(error.localizedDescription)")
            }
        }
    }
}

extension FaceManager {

    public func save(_ id: String? = nil) {
        let plistFileName = "\(id ?? identity).plist"
        
        let plistPath = faceEmojiDirectoryURL.appendingPathComponent(plistFileName)
        
        do {
            let encoder = PropertyListEncoder()
            let plistData = try encoder.encode(images)
            try plistData.write(to: plistPath)
            print("Data written to \(plistPath)")
        } catch {
            print("Error writing data to plist: \(error)")
        }
    }
    
    func read() -> [FaceEmoji] {
        let plistFileName = "\(identity).plist"
        
        let plistPath = faceEmojiDirectoryURL.appendingPathComponent(plistFileName)
        
        if let data = try? Data(contentsOf: plistPath) {
            do {
                let decoder = PropertyListDecoder()
                let result = try decoder.decode([FaceEmoji].self, from: data)
                FaceManager.shared.images = result
                
                return result
            } catch {
                print("Error reading data from plist: \(error)")
            }
        }
        
        return []
    }
}
