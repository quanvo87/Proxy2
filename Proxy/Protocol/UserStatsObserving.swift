import FirebaseDatabase
import UIKit

enum UserStatsUpdate {
    case messagesReceived(String)
    case messagesSent(String)
    case proxiesInteractedWith(String)
}

protocol UserStatsObserving {
    func observe(uid: String, completion: @escaping (UserStatsUpdate) -> Void)
}

class UserStatsObserver: UserStatsObserving {
    private var messagesReceivedHandle: DatabaseHandle?
    private var messagesReceivedRef: DatabaseReference?
    private var messagesSentHandle: DatabaseHandle?
    private var messagesSentRef: DatabaseReference?
    private var proxiesInteractedWithHandle: DatabaseHandle?
    private var proxiesInteractedWithRef: DatabaseReference?

    func observe(uid: String, completion: @escaping (UserStatsUpdate) -> Void) {
        stopObservering()
        messagesReceivedRef = try? Shared.firebaseHelper.makeReference(
            Child.users,
            uid,
            Child.stats,
            IncrementableUserProperty.Name.messagesReceived.rawValue
        )
        messagesReceivedHandle = messagesReceivedRef?.observe(.value) { data in
            completion(.messagesReceived(data.asNumberLabel))
        }
        messagesSentRef = try? Shared.firebaseHelper.makeReference(
            Child.users,
            uid,
            Child.stats,
            IncrementableUserProperty.Name.messagesSent.rawValue
        )
        messagesSentHandle = messagesSentRef?.observe(.value) { data in
            completion(.messagesSent(data.asNumberLabel))
        }
        proxiesInteractedWithRef = try? Shared.firebaseHelper.makeReference(
            Child.users,
            uid,
            Child.stats,
            IncrementableUserProperty.Name.proxiesInteractedWith.rawValue
        )
        proxiesInteractedWithHandle = proxiesInteractedWithRef?.observe(.value) { data in
            completion(.proxiesInteractedWith(data.asNumberLabel))
        }
    }

    private func stopObservering() {
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

    deinit {
        stopObservering()
    }
}
