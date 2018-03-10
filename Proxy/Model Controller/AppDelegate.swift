import AVKit
import Firebase
import FBSDKCoreKit
import SwiftMessages
import UserNotifications

// todo: di?
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    private let authObserver = AuthObserver()
    private let convoPresenceObserver = ConvoPresenceObserver()
    private let database = Firebase()
    private var isLoggedIn = false
    private var uid: String? {
        didSet {
            isLoggedIn = uid != nil
        }
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
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
                let tabBarController = TabBarController(uid: user.uid, displayName: displayName)
                self?.window?.rootViewController = tabBarController
                self?.uid = user.uid
                self?.setRegistrationToken()
            } else {
                guard let isLoggedIn = self?.isLoggedIn, isLoggedIn,
                    let welcomeViewController = Shared.storyboard.instantiateViewController(
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
        switch application.applicationState {
        case .active:
            showNewMessageBanner(userInfo) {
                completionHandler(.newData)
            }
        case .background:
            completionHandler(.noData)
        case .inactive:
            sendShouldShowConvoNotification(userInfo) {
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

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        StatusBar.showErrorStatusBarBanner(error)
    }
}

// todo: move to protocol
private extension AppDelegate {
    func sendShouldShowConvoNotification(_ userInfo: [AnyHashable: Any], completion: @escaping () -> Void) {
        guard let convoKey = userInfo.parentConvoKey,
            convoKey != convoPresenceObserver.currentConvoKey,
            let uid = uid else {
                completion()
                return
        }
        database.getConvo(convoKey: convoKey, ownerId: uid) { result in
            switch result {
            case .failure(let error):
                StatusBar.showErrorStatusBarBanner(error)
            case .success(let convo):
                NotificationCenter.default.post(
                    name: .shouldShowConvo,
                    object: nil,
                    userInfo: ["convo": convo]
                )
            }
            completion()
        }
    }

    func setRegistrationToken() {
        guard let registrationToken = Messaging.messaging().fcmToken, let uid = uid else {
            return
        }
        database.setRegistrationToken(registrationToken, for: uid) { error in
            if let error = error {
                StatusBar.showErrorStatusBarBanner(error)
            }
        }
    }

    func showNewMessageBanner(_ userInfo: [AnyHashable: Any], completion: @escaping () -> Void) {
        guard let convoKey = userInfo.parentConvoKey,
            convoKey != convoPresenceObserver.currentConvoKey,
            let uid = uid else {
                completion()
                return
        }
        database.getConvo(convoKey: convoKey, ownerId: uid) { result in
            switch result {
            case .failure(let error):
                StatusBar.showErrorStatusBarBanner(error)
            case .success(let convo):
                StatusBar.showNewMessageBanner(convo)
            }
            completion()
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
        let userInfo = notification.request.content.userInfo
        showNewMessageBanner(userInfo) {
            completionHandler([])
        }
    }
    // swiftlint:enable line_length

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        sendShouldShowConvoNotification(userInfo, completion: completionHandler)
    }
}
