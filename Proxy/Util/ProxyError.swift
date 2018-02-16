enum ProxyError: Error {
    case blankMessage
    case inputTooLong
    case invalidData
    case missingCredentials
    case receiverDeletedProxy
    case receiverMissing
    case receiverNotFound
    case senderMissing
    case tooManyProxies
    case unknown

    var alertFields: (title: String, description: String) {
        switch self {
        case .blankMessage:
            return ("Enter a message", "Cannot send blank message.")
        case .inputTooLong:
            return ("Input too long", "Please try something shorter.")
        case .invalidData:
            return ("Invalid Data", "Invalid data read in database.")
        case .missingCredentials:
            return ("Missing email/password", "Please enter an email and password.")
        case .receiverDeletedProxy:
            return ("Receiver deleted", "They can no longer be messaged.")
        case .receiverMissing:
            return ("Pick a recipient", "Who do you want to send the message to?")
        case .receiverNotFound:
            return ("Receveiver not found", "Please try again.")
        case .senderMissing:
            return ("Pick a sender", "Who do you want to send from?")
        case .tooManyProxies:
            return ("Too many Proxies", "You have too many Proxies. Please delete some and try again.")
        case .unknown:
            return ("😵 Error", "An unknown error occurred.")
        }
    }

    var localizedDescription: String {
        return alertFields.description
    }
}
