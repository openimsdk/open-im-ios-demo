






import Foundation
import UIKit

extension Bundle {
    
    class var podBundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        var podBundle = Bundle(for: EmojiView.classForCoder())


        if let bundleURL = podBundle.url(forResource: "ISEmojiView", withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                podBundle = bundle
            }
        }
        
        return podBundle
        #endif
    }
    
}
