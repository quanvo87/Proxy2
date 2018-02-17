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
        switch self {
        case .blankMessage:
            return "Cannot send blank message"
        case .inputTooLong:
            return "Too many characters."
        case .missingCredentials:
            return "Invalid email/password."
        case .receiverDeletedProxy:
            return "The receiver no longer exists."
        case .receiverMissing:
            return "Pick a receiver for the message."
        case .receiverNotFound:
            return "Receiver not found."
        case .senderMissing:
            return "Pick a sender for the message."
        case .tooManyProxies:
            return "You have too many proxies."
        case .unknown:
            return "Unknown error occurred."
        }
    }
}
