import NotificationBannerSwift

class ProxyNotificationBannerQueue: NotificationBannerQueue {
    var currentBanner: BaseNotificationBanner? {
        willSet {
            currentBanner?.dismiss()
            removeAll()
        }
        didSet {
            if let currentBanner = currentBanner {
                currentBanner.show(queue: self)
            }
        }
    }
}
