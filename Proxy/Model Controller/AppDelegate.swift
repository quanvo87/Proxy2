import AVKit
import Firebase
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    private let authObserver = AuthObserver()
    private var isLoggedIn = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        setAudioSession()
        FirebaseApp.configure()
//        Database.database().isPersistenceEnabled = true
        authObserver.observe { [weak self] user in
            if let user = user {
                var displayName = user.displayName
                if (user.displayName == nil || user.displayName == ""), let email = user.email, email != "" {
                    displayName = email
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = email
                    changeRequest.commitChanges()
                }
                self?.isLoggedIn = true
                self?.window?.rootViewController = TabBarController(uid: user.uid, displayName: displayName)
            } else {
                guard
                    let isLoggedIn = self?.isLoggedIn, isLoggedIn,
                    let loginController = LoginViewController.make() else {
                        return
                }
                self?.isLoggedIn = false
                self?.window?.rootViewController = loginController
            }
        }
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setAudioSession(_ session: AVAudioSession = AVAudioSession.sharedInstance(),
                                 category: String = AVAudioSessionCategoryAmbient,
                                 mode: String = AVAudioSessionModeDefault) {
        do {
            if #available(iOS 10.0, *) {
                try session.setCategory(category, mode: mode)
                try session.setActive(true)
            }
        } catch {
            print("Failed to set the audio session category and mode: \(error.localizedDescription)")
        }
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }
}
