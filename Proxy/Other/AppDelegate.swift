import AVKit
import Firebase
import FBSDKCoreKit
import SwiftMessages
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    private let authObserver = AuthObserver()
    private let database = Shared.database
    private let notificationHandler = NotificationHandler()
    private var launchScreenFinishedObserver: NSObjectProtocol?
    private var uid: String?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        if Constant.isRunningTests {
            return true
        }

        authObserver.observe { [weak self] user in
            UIApplication.shared.applicationIconBadgeNumber = 0
            if let user = user {
                var displayName = user.displayName
                if (user.displayName == nil || user.displayName == ""), let email = user.email, email != "" {
                    displayName = email
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = email
                    changeRequest.commitChanges()
                }
                let tabBarController = TabBarController(uid: user.uid, displayName: displayName)
                self?.window?.rootViewController = tabBarController
                self?.uid = user.uid
                self?.setRegistrationToken()
            } else {
                guard self?.uid != nil, let welcomeViewController = Shared.storyboard.instantiateViewController(
                    withIdentifier: String(describing: WelcomeViewController.self)
                    ) as? WelcomeViewController else {
                        return
                }
                let navigationController = UINavigationController(rootViewController: welcomeViewController)
                self?.window?.rootViewController = navigationController
                self?.uid = nil
            }
        }

//        Database.database().isPersistenceEnabled = true

        launchScreenFinishedObserver = NotificationCenter.default.addObserver(
            forName: .launchScreenFinished,
            object: nil,
            queue: .main) { [weak self] _ in
                if #available(iOS 10.0, *) {
                    UNUserNotificationCenter.current().delegate = self
                    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                    UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
                } else {
                    let settings: UIUserNotificationSettings = UIUserNotificationSettings(
                        types: [.alert, .badge, .sound],
                        categories: nil
                    )
                    application.registerUserNotificationSettings(settings)
                }
                application.registerForRemoteNotifications()
                if let launchScreenFinishedObserver = self?.launchScreenFinishedObserver {
                    NotificationCenter.default.removeObserver(launchScreenFinishedObserver)
                }
                self?.launchScreenFinishedObserver = nil
        }

        Messaging.messaging().delegate = self

        SwiftMessages.defaultConfig.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        SwiftMessages.defaultConfig.duration = .seconds(seconds: 4)

        return FBSDKApplicationDelegate.sharedInstance().application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let uid = uid else {
            completionHandler(.noData)
            return
        }
        switch application.applicationState {
        case .active:
            notificationHandler.showNewMessageBanner(uid: uid, userInfo: userInfo) {
                completionHandler(.newData)
            }
        case .background:
            completionHandler(.noData)
        case .inactive:
            notificationHandler.sendShouldShowConvoNotification(uid: uid, userInfo: userInfo) {
                completionHandler(.newData)
            }
        }
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

    deinit {
        if let launchScreenFinishedObserver = launchScreenFinishedObserver {
            NotificationCenter.default.removeObserver(launchScreenFinishedObserver)
        }
    }
}

private extension AppDelegate {
    func setRegistrationToken() {
        guard let registrationToken = Messaging.messaging().fcmToken, let uid = uid else {
            return
        }
        database.set(.registrationToken(registrationToken), for: uid) { error in
            if let error = error {
                StatusBar.showErrorStatusBarBanner(error)
            }
        }
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        setRegistrationToken()
    }
}

@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    // swiftlint:disable line_length
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard let uid = uid else {
            completionHandler([])
            return
        }
        let userInfo = notification.request.content.userInfo
        notificationHandler.showNewMessageBanner(uid: uid, userInfo: userInfo) {
            completionHandler([])
        }
    }
    // swiftlint:enable line_length

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let uid = uid else {
            completionHandler()
            return
        }
        let userInfo = response.notification.request.content.userInfo
        notificationHandler.sendShouldShowConvoNotification(uid: uid, userInfo: userInfo, completion: completionHandler)
    }
}
