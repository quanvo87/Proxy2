enum ProxyError: Error {
    case blankMessage
    case inputTooLong
    case missingCredentials
    case receiverDeletedProxy
    case receiverMissing
    case receiverNotFound
    case senderMissing
    case tooManyProxies
    case unknown

    var description: String {
        var _description: String
        switch self {
        case .blankMessage:
            _description = "Cannot send blank message"
        case .inputTooLong:
            _description = "Too many characters."
        case .missingCredentials:
            _description = "Invalid email/password."
        case .receiverDeletedProxy:
            _description = "This receiver no longer exists."
        case .receiverMissing:
            _description = "Pick a receiver for the message."
        case .receiverNotFound:
            _description = "Receiver not found."
        case .senderMissing:
            _description = "Pick a sender for the message."
        case .tooManyProxies:
            _description = "You have too many proxies."
        case .unknown:
            _description = "Unknown error occurred."
        }
        return "⚠️ " + _description
    }
}
