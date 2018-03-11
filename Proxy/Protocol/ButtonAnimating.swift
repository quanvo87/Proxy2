import UIKit

protocol ButtonAnimating {
    func add(_ button: UIBarButtonItem)
    func animate()
    func stopAnimating()
}

class ButtonAnimator: ButtonAnimating {
    private var buttons = Set<UIBarButtonItem>()
    private var applicationDidBecomeActiveObserver: NSObjectProtocol?
    private var isAnimating = false

    init() {
        applicationDidBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: .UIApplicationDidBecomeActive,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.resume()
        }
    }

    func add(_ button: UIBarButtonItem) {
        buttons.update(with: button)
    }

    func animate() {
        buttons.forEach {
            $0.animate(loop: true)
        }
        isAnimating = true
    }

    func stopAnimating() {
        buttons.forEach {
            $0.stopAnimating()
        }
        isAnimating = false
    }

    func resume() {
        if isAnimating {
            animate()
        }
    }

    deinit {
        if let applicationDidBecomeActiveObserver = applicationDidBecomeActiveObserver {
            NotificationCenter.default.removeObserver(applicationDidBecomeActiveObserver)
        }
    }
}
