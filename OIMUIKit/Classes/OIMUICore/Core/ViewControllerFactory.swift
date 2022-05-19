//






import Foundation

public class ViewControllerFactory {
    public static func getBundle() -> Bundle? {
        guard let path = Bundle.init(for: ContactsViewController.self).resourcePath else { return nil }
        var finalPath: String = path
        finalPath.append("/OIMUIResource.bundle")
        let bundle = Bundle.init(path: finalPath)
        return bundle
    }
    
    public static func getEmojiBundle() -> Bundle? {
        guard let path = Bundle.init(for: ContactsViewController.self).resourcePath else { return nil }
        var finalPath: String = path
        finalPath.append("/OIMUIEmoji.bundle")
        let bundle = Bundle.init(path: finalPath)
        return bundle
    }
    
    public static func getContactStoryboard() -> UIStoryboard {
        let storyboard = UIStoryboard.init(name: "OIMContacts", bundle: getBundle())
        return storyboard
    }
}
