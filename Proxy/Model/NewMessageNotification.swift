struct NewMessageNotification {
    let parentConvoKey: String
    let text: String

    init(_ userInfo: [AnyHashable: Any]) throws {
        guard let aps = userInfo["aps"] as? [AnyHashable: String],
            let text = aps["alert"],
            let parentConvoKey = userInfo["gcm.notification.parentConvoKey"] as? String else {
                throw ProxyError.unknown
        }
        self.parentConvoKey = parentConvoKey
        self.text = text
    }
}
