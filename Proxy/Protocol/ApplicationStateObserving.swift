import UIKit

protocol ApplicationStateObserving {
    func applicationDidBecomeActive(callback: @escaping () -> Void)
    func applicationDidEnterBackground(callback: @escaping () -> Void)
}

class ApplicationStateObserver: ApplicationStateObserving {
    typealias Callback = (() -> Void)?
    private var applicationDidBecomeActiveCallback: Callback
    private var applicationDidBecomeActiveObserver: NSObjectProtocol?
    private var applicationDidEnterBackgroundCallback: Callback
    private var applicationDidEnterBackgroundObserver: NSObjectProtocol?

    init() {
        applicationDidBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: .UIApplicationDidBecomeActive,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.applicationDidBecomeActiveCallback?()
        }

        applicationDidEnterBackgroundObserver = NotificationCenter.default.addObserver(
            forName: .UIApplicationDidEnterBackground,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.applicationDidEnterBackgroundCallback?()
        }
    }

    func applicationDidBecomeActive(callback: @escaping () -> Void) {
        applicationDidBecomeActiveCallback = callback
    }

    func applicationDidEnterBackground(callback: @escaping () -> Void) {
        applicationDidEnterBackgroundCallback = callback
    }

    deinit {
        if let applicationDidBecomeActiveObserver = applicationDidBecomeActiveObserver {
            NotificationCenter.default.removeObserver(applicationDidBecomeActiveObserver)
        }
        if let applicationDidEnterBackgroundObserver = applicationDidEnterBackgroundObserver {
            NotificationCenter.default.removeObserver(applicationDidEnterBackgroundObserver)
        }
        applicationDidBecomeActiveCallback = nil
        applicationDidEnterBackgroundCallback = nil
    }
}
