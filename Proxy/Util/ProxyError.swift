import Foundation

enum ProxyError: LocalizedError {
    case alreadyChattingWithUser
    case blankMessage
    case inputTooLong
    case missingCredentials
    case receiverDeletedProxy
    case receiverIsBlocking
    case receiverMissing
    case receiverNotFound
    case senderMissing
    case tooManyProxies
    case unknown

    var errorDescription: String? {
        switch self {
        case .alreadyChattingWithUser:
            return "You are already chatting with this user with another Proxy."
        case .blankMessage:
            return "Cannot send blank message."
        case .inputTooLong:
            return "Too many characters."
        case .missingCredentials:
            return "Invalid email/password."
        case .receiverDeletedProxy:
            return "The receiver no longer exists."
        case .receiverIsBlocking:
            return "The receiver is blocking messages at this time."
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
