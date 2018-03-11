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
        messagesReceivedRef = try? Constant.firebaseHelper.makeReference(
            Child.users,
            uid,
            IncrementableUserProperty.messagesReceived.rawValue
        )
        messagesReceivedHandle = messagesReceivedRef?.observe(.value) { data in
            completion(.messagesReceived(data.asNumberLabel))
        }
        messagesSentRef = try? Constant.firebaseHelper.makeReference(
            Child.users,
            uid,
            IncrementableUserProperty.messagesSent.rawValue
        )
        messagesSentHandle = messagesSentRef?.observe(.value) { data in
            completion(.messagesSent(data.asNumberLabel))
        }
        proxiesInteractedWithRef = try? Constant.firebaseHelper.makeReference(
            Child.users,
            uid,
            IncrementableUserProperty.proxiesInteractedWith.rawValue
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
