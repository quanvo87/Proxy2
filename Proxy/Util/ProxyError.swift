enum ProxyError: Error {
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
        case .inputTooLong:
            return ("Input too long", "Please try something shorter.")
        case .invalidData:
            return ("Invalid Data", "Invalid data read in database.")
        case .missingCredentials:
            return ("Missing email/password", "Please make sure to enter an email and password.")
        case .receiverDeletedProxy:
            return ("Receiver deleted", "They can no longer be messaged.")
        case .receiverMissing:
            return ("Missing recipient", "Please select a recipient and try again.")
        case .receiverNotFound:
            return ("Receveiver not found", "Unable to find the specified recipient.")
        case .senderMissing:
            return ("Missing sender", "Please select one of your Proxies to send from.")
        case .tooManyProxies:
            return ("Too many Proxies", "You have too many Proxies. Please delete some and try again.")
        case .unknown:
            return ("😢", "Unknown error occurred.")
        }
    }

    var localizedDescription: String {
        return alertFields.description
    }
}
