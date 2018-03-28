import UIKit

protocol ApplicationStateObserving {
    typealias Callback = (() -> Void)
    func applicationDidBecomeActive(callback: @escaping Callback)
    func applicationDidEnterBackground(callback: @escaping Callback)
}

class ApplicationStateObserver: ApplicationStateObserving {
    private var applicationDidBecomeActiveCallback: Callback?
    private var applicationDidBecomeActiveObserver: NSObjectProtocol?
    private var applicationDidEnterBackgroundCallback: Callback?
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

    func applicationDidBecomeActive(callback: @escaping Callback) {
        applicationDidBecomeActiveCallback = callback
    }

    func applicationDidEnterBackground(callback: @escaping Callback) {
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
