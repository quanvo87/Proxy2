import UIKit

protocol MessagesReceivedManaging: class {
    var messagesReceivedCount: String { get set }
}

protocol MessagesSentManaging: class {
    var messagesSentCount: String { get set }
}

protocol ProxiesInteractedWithManaging: class {
    var proxiesInteractedWithCount: String { get set }
}

typealias UserStatsManaging = MessagesReceivedManaging & MessagesSentManaging & ProxiesInteractedWithManaging

class UserStatsManager: UserStatsManaging {
    var messagesReceivedCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }

    var messagesSentCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }

    var proxiesInteractedWithCount = "-" {
        didSet {
            tableView?.reloadData()
        }
    }

    private let messagesReceivedObserver = MessagesReceivedObserver()
    private let messagesSentObserver = MessagesSentObserver()
    private let proxiesInteractedWithObserver = ProxiesInteractedWithObserver()
    private weak var tableView: UITableView?

    func load(uid: String, tableView: UITableView) {
        self.tableView = tableView
        messagesReceivedObserver.observe(uid: uid, manager: self)
        messagesSentObserver.observe(uid: uid, manager: self)
        proxiesInteractedWithObserver.observe(uid: uid, manager: self)
    }
}
