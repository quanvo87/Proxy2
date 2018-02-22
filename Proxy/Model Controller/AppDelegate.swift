import AVKit
import Firebase
import FBSDKCoreKit
import SwiftMessages

// todo: do not omit param name for single param funcs?
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    private let authObserver = AuthObserver()
    private var isLoggedIn = false

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if #available(iOS 10.0, *) {
            try? AVAudioSession.sharedInstance().setCategory(
                AVAudioSessionCategoryAmbient,
                mode: AVAudioSessionModeDefault
            )
            try? AVAudioSession.sharedInstance().setActive(true)
        }

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
                guard let isLoggedIn = self?.isLoggedIn, isLoggedIn,
                    let mainLoginController = Shared.storyboard.instantiateViewController(
                        withIdentifier: String(describing: WelcomeViewController.self)
                        ) as? WelcomeViewController else {
                            return
                }
                self?.isLoggedIn = false
                let navigationController = UINavigationController(rootViewController: mainLoginController)
                self?.window?.rootViewController = navigationController
            }
        }

        SwiftMessages.defaultConfig.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        SwiftMessages.defaultConfig.duration = .seconds(seconds: 4)

        return FBSDKApplicationDelegate.sharedInstance().application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(
            application,
            open: url,
            sourceApplication: sourceApplication,
            annotation: annotation
        )
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }
}
