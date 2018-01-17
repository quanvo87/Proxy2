import FirebaseDatabase
import UIKit

protocol UserStatsManaging: class {
    var messagesReceivedCount: String { get }
    var messagesSentCount: String { get }
    var proxiesInteractedWithCount: String { get }
}

class UserStatsManager: UserStatsManaging {
    private (set) var messagesReceivedCount = "-"
    private (set) var messagesSentCount = "-"
    private (set) var proxiesInteractedWithCount = "-"
    private let messagesReceivedRef: DatabaseReference?
    private let messagesSentRef: DatabaseReference?
    private let proxiesInteractedWithRef: DatabaseReference?
    private var messagesReceivedHandle: DatabaseHandle?
    private var messagesSentHandle: DatabaseHandle?
    private var proxiesInteractedWithHandle: DatabaseHandle?

    init(uid: String, tableView: UITableView) {
        messagesReceivedRef = DB.makeReference(Child.userInfo, uid, IncrementableUserProperty.messagesReceived.rawValue)
        messagesSentRef = DB.makeReference(Child.userInfo, uid, IncrementableUserProperty.messagesSent.rawValue)
        proxiesInteractedWithRef = DB.makeReference(Child.userInfo, uid, IncrementableUserProperty.proxiesInteractedWith.rawValue)
        messagesReceivedHandle = messagesReceivedRef?.observe(.value) { [weak self, weak tableView] (data) in
            self?.messagesReceivedCount = data.asNumberLabel
            tableView?.reloadData()
        }
        messagesSentHandle = messagesSentRef?.observe(.value) { [weak self, weak tableView] (data) in
            self?.messagesSentCount = data.asNumberLabel
            tableView?.reloadData()
        }
        proxiesInteractedWithHandle = proxiesInteractedWithRef?.observe(.value) { [weak self, weak tableView] (data) in
            self?.proxiesInteractedWithCount = data.asNumberLabel
            tableView?.reloadData()
        }
    }

    deinit {
        if let messagesReceivedHandle = messagesReceivedHandle {
            messagesReceivedRef?.removeObserver(withHandle: messagesReceivedHandle)
        }
        if let messagesSentHandle = messagesSentHandle {
            messagesSentRef?.removeObserver(withHandle: messagesSentHandle)
        }
        if let proxiesInteractedWithHandle = proxiesInteractedWithHandle {
            proxiesInteractedWithRef?.removeObserver(withHandle: proxiesInteractedWithHandle)
        }
    }
}
