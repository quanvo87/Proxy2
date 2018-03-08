import AVKit
import Firebase
import FBSDKCoreKit
import SwiftMessages
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    private let authObserver = AuthObserver()
    private var currentConvoKey: String?
    private let database = Firebase()
    private var didHideConvoObserver: NSObjectProtocol?
    private var didShowConvoObserver: NSObjectProtocol?
    private var isLoggedIn = false
    private var uid: String?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        // todo: add option in settings
        // todo: badge - serverless - get unreadMessages count, send as badge in notification payload
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
                self?.isLoggedIn = true
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
                self?.isLoggedIn = false
                self?.uid = nil
            }
        }

//        Database.database().isPersistenceEnabled = true

        didHideConvoObserver = NotificationCenter.default.addObserver(
            forName: .didHideConvo,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.currentConvoKey = nil
        }

        didShowConvoObserver = NotificationCenter.default.addObserver(
            forName: .didShowConvo,
            object: nil,
            queue: .main) { [weak self] notification in
                if let convoKey = notification.userInfo?["convoKey"] as? String {
                    self?.currentConvoKey = convoKey
                }
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

    deinit {
        if let didHideConvoObserver = didHideConvoObserver {
            NotificationCenter.default.removeObserver(didHideConvoObserver)
        }
        if let currentConvoKeyObserver = didShowConvoObserver {
            NotificationCenter.default.removeObserver(currentConvoKeyObserver)
        }
    }
}

private extension AppDelegate {
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
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        setRegistrationToken()
    }

    // todo: investigate what this is
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("📧 \(remoteMessage.appData)")
    }
}

@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    // swiftlint:disable line_length
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        do {
            let userInfo = notification.request.content.userInfo
            let newMessageNotification = try NewMessageNotification(userInfo)
            let parentConvoKey = newMessageNotification.parentConvoKey
            if parentConvoKey != currentConvoKey, let uid = uid {
                database.getConvo(convoKey: parentConvoKey, ownerId: uid) { result in
                    switch result {
                    case .failure(let error):
                        StatusBar.showErrorStatusBarBanner(error)
                    case .success(let convo):
                        StatusBar.showNewMessageBanner(newMessageNotification, convo: convo)
                    }
                }
            }
        } catch {}
        completionHandler([])
    }
    // swiftlint:enable line_length

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        do {
            let userInfo = response.notification.request.content.userInfo
            let newMessageNotification = try NewMessageNotification(userInfo)
            let parentConvoKey = newMessageNotification.parentConvoKey
            if parentConvoKey != currentConvoKey, let uid = uid {
                database.getConvo(convoKey: parentConvoKey, ownerId: uid) { result in
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
                }
            }
        } catch {}
        completionHandler()
    }
}
