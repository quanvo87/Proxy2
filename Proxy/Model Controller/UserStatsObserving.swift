import FirebaseDatabase
import FirebaseHelper
import UIKit

protocol UserStatsObserving {
    func observe(uid: String, userStatsManager: UserStatsManaging)
}

class UserStatsObserver: UserStatsObserving {
    private var messagesReceivedHandle: DatabaseHandle?
    private var messagesReceivedRef: DatabaseReference?
    private var messagesSentHandle: DatabaseHandle?
    private var messagesSentRef: DatabaseReference?
    private var proxiesInteractedWithHandle: DatabaseHandle?
    private var proxiesInteractedWithRef: DatabaseReference?

    func observe(uid: String, userStatsManager: UserStatsManaging) {
        stopObservering()

        messagesReceivedRef = try? FirebaseHelper.main.makeReference(Child.userInfo,
                                                                     uid,
                                                                     IncrementableUserProperty.messagesReceived.rawValue)
        messagesReceivedHandle = messagesReceivedRef?.observe(.value) { [weak userStatsManager] data in
            userStatsManager?.messagesReceivedCount = data.asNumberLabel
        }

        messagesSentRef = try? FirebaseHelper.main.makeReference(Child.userInfo,
                                                                 uid,
                                                                 IncrementableUserProperty.messagesSent.rawValue)
        messagesSentHandle = messagesSentRef?.observe(.value) { [weak userStatsManager] data in
            userStatsManager?.messagesSentCount = data.asNumberLabel
        }

        proxiesInteractedWithRef = try? FirebaseHelper.main.makeReference(Child.userInfo,
                                                                          uid,
                                                                          IncrementableUserProperty.proxiesInteractedWith.rawValue)
        proxiesInteractedWithHandle = proxiesInteractedWithRef?.observe(.value) { [weak userStatsManager] data in
            userStatsManager?.proxiesInteractedWithCount = data.asNumberLabel
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

private extension DataSnapshot {
    var asNumberLabel: String {
        if let number = self.value as? UInt {
            return number.asStringWithCommas
        } else {
            return "-"
        }
    }
}

private extension NumberFormatter {
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}

private extension UInt {
    var asStringWithCommas: String {
        var num = Double(self)
        num = fabs(num)
        guard let string = NumberFormatter.decimal.string(from: NSNumber(integerLiteral: Int(num))) else {
            return "-"
        }
        return string
    }
}
