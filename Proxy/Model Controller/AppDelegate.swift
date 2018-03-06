import AVKit
import Firebase
import FBSDKCoreKit
import SwiftMessages
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    private let authObserver = AuthObserver()
    private let database = Firebase()
    private let gcmMessageIDKey = "gcm.message_id"
    private var isLoggedIn = false
    private var uid: String? {
        didSet {
            setRegistrationToken()
        }
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in }
            )
        } else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(
                types: [.alert, .badge, .sound],
                categories: nil
            )
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()

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
                self?.uid = user.uid
                self?.window?.rootViewController = TabBarController(uid: user.uid, displayName: displayName)
            } else {
                guard let isLoggedIn = self?.isLoggedIn, isLoggedIn,
                    let mainLoginController = Shared.storyboard.instantiateViewController(
                        withIdentifier: String(describing: WelcomeViewController.self)
                        ) as? WelcomeViewController else {
                            return
                }
                self?.isLoggedIn = false
                self?.uid = nil
                self?.window?.rootViewController = UINavigationController(rootViewController: mainLoginController)
            }
        }

//        Database.database().isPersistenceEnabled = true

        Messaging.messaging().delegate = self

        SwiftMessages.defaultConfig.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        SwiftMessages.defaultConfig.duration = .seconds(seconds: 4)

        return FBSDKApplicationDelegate.sharedInstance().application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    // < iOS 10
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let messageID = userInfo[gcmMessageIDKey] {
            print("😎 Message ID: \(messageID)")
        }
        print("🐻 \(userInfo)")
        completionHandler(.newData)
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

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        StatusBar.showErrorStatusBarBanner(error)
    }
}

private extension AppDelegate {
    func setRegistrationToken() {
        guard let registrationToken = registrationToken, let uid = uid else {
            return
        }
        database.setRegistrationToken(registrationToken, for: uid) { error in
            if let error = error {
                StatusBar.showErrorStatusBarBanner(error)
            }
        }
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        registrationToken = fcmToken
        setRegistrationToken()
    }

    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("📧 \(remoteMessage.appData)")
    }
}

@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    // foreground
    // swiftlint:disable line_length
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        if let messageID = userInfo[gcmMessageIDKey] {
            print("🐸 Message ID: \(messageID)")
        }
        print("🏈 \(userInfo)")
        completionHandler([])
    }
    // swiftlint:enable line_length

    // when user taps notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let messageID = userInfo[gcmMessageIDKey] {
            print("🎱 Message ID: \(messageID)")
        }
        print("🎾 \(userInfo)")
        completionHandler()
    }
}
