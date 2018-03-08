struct NewMessageNotification {
    let messageText: String
    let parentConvoKey: String
    let senderDisplayName: String

    // todo: won't be needed once i make notification send whole convo
    init(_ userInfo: [AnyHashable: Any]) throws {
        guard let messageText = userInfo["gcm.notification.messageText"] as? String,
            let parentConvoKey = userInfo["gcm.notification.parentConvoKey"] as? String,
            let senderDisplayName = userInfo["gcm.notification.senderDisplayName"] as? String else {
                throw ProxyError.unknown
        }
        self.messageText = messageText
        self.parentConvoKey = parentConvoKey
        self.senderDisplayName = senderDisplayName
    }
}
