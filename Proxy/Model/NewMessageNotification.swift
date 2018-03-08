struct NewMessageNotification {
    let parentConvoKey: String
    let text: String

    init(_ userInfo: [AnyHashable: Any]) throws {
        guard let parentConvoKey = userInfo["gcm.notification.parentConvoKey"] as? String,
            let aps = userInfo["aps"] as? [AnyHashable: String],
            let text = aps["alert"] else {
                throw ProxyError.unknown
        }
        self.parentConvoKey = parentConvoKey
        self.text = text
    }
}
