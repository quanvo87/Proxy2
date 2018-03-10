import Foundation

protocol ConvoPresenceObserving {
    var currentConvoKey: String? { get }
}

class ConvoPresenceObserver: ConvoPresenceObserving {
    var currentConvoKey: String?
    private var didEnterConvoObserver: NSObjectProtocol?
    private var didLeaveConvoObserver: NSObjectProtocol?

    init() {
        didEnterConvoObserver = NotificationCenter.default.addObserver(
            forName: .didEnterConvo,
            object: nil,
            queue: .main) { [weak self] notification in
                if let convoKey = notification.userInfo?["convoKey"] as? String {
                    self?.currentConvoKey = convoKey
                }
        }

        didLeaveConvoObserver = NotificationCenter.default.addObserver(
            forName: .didLeaveConvo,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.currentConvoKey = nil
        }
    }

    deinit {
        if let didHideConvoObserver = didLeaveConvoObserver {
            NotificationCenter.default.removeObserver(didHideConvoObserver)
        }
        if let currentConvoKeyObserver = didEnterConvoObserver {
            NotificationCenter.default.removeObserver(currentConvoKeyObserver)
        }
    }
}
