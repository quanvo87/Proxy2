import FirebaseDatabase
import UIKit

protocol UserStatsObserving {
    func load(manager: UserStatsManaging, uid: String)
}

class UserStatsObserver: UserStatsObserving {
    private var messagesReceivedHandle: DatabaseHandle?
    private var messagesReceivedRef: DatabaseReference?
    private var messagesSentHandle: DatabaseHandle?
    private var messagesSentRef: DatabaseReference?
    private var proxiesInteractedWithHandle: DatabaseHandle?
    private var proxiesInteractedWithRef: DatabaseReference?

    func load(manager: UserStatsManaging, uid: String) {
        stopObservering()

        messagesReceivedRef = FirebaseHelper.makeReference(Child.userInfo,
                                                           uid,
                                                           IncrementableUserProperty.messagesReceived.rawValue)
        messagesReceivedHandle = messagesReceivedRef?.observe(.value) { [weak manager] (data) in
            manager?.messagesReceivedCount = data.asNumberLabel
        }

        messagesSentRef = FirebaseHelper.makeReference(Child.userInfo,
                                                       uid,
                                                       IncrementableUserProperty.messagesSent.rawValue)
        messagesSentHandle = messagesSentRef?.observe(.value) { [weak manager] (data) in
            manager?.messagesSentCount = data.asNumberLabel
        }

        proxiesInteractedWithRef = FirebaseHelper.makeReference(Child.userInfo,
                                                                uid,
                                                                IncrementableUserProperty.proxiesInteractedWith.rawValue)
        proxiesInteractedWithHandle = proxiesInteractedWithRef?.observe(.value) { [weak manager] (data) in
            manager?.proxiesInteractedWithCount = data.asNumberLabel
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
