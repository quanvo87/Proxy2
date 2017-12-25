import AVKit
import Firebase
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let authManager = AuthManager()
    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        setAudioSession()
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        authManager.load(self)
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }

    func setAudioSession(_ session: AVAudioSession = AVAudioSession.sharedInstance(),
                         category: String = AVAudioSessionCategoryAmbient,
                         mode: String = AVAudioSessionModeDefault) {
        do {
            if #available(iOS 10.0, *) {
                try session.setCategory(category, mode: mode)
                try session.setActive(true)
            }
        } catch let error as NSError {
            print("Failed to set the audio session category and mode: \(error.localizedDescription)")
        }
    }
}
