
import Foundation

let enablePasswordLockKey = "com.screenlock.enable.password"
let enableBiometricsKey = "com.screenlock.enable.biometrics"
let hasSetPasswordKey = "com.screenlock.has.set.password"
let currentPasswordKey = "com.screenlock.password"

class LocalAuthManager {
    class func currentPassword() -> String? {
        return UserDefaults.standard.string(forKey: currentPasswordKey)
    }

    class func updatePassword(_ password: String?) {
        enablePasswordLock = password != nil
        hasSetPassword = password != nil
        
        UserDefaults.standard.setValue(password, forKey: currentPasswordKey)
        UserDefaults.standard.synchronize()
    }
    
    class var enablePasswordLock: Bool {
        get {
            UserDefaults.standard.bool(forKey: enablePasswordLockKey)
        }
        
        set {
            UserDefaults.standard.setValue(newValue, forKey: enablePasswordLockKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    class var enableBiometrics: Bool {
        get {
            UserDefaults.standard.bool(forKey: enableBiometricsKey)
        }
        
        set {
            UserDefaults.standard.setValue(newValue, forKey: enableBiometricsKey)
        }
    }
    
    class var hasSetPassword: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasSetPasswordKey)
        }
        
        set {
            UserDefaults.standard.setValue(newValue, forKey: hasSetPasswordKey)
        }
    }
}
