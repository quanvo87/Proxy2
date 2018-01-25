enum ProxyError: Error {
    case inputTooLong
    case missingCredentials
    case receiverDeletedProxy
    case receiverMissing
    case senderMissing
    case tooManyProxies
    case unknown

    var alertFields: (title: String, description: String) {
        switch self {
        case .inputTooLong:
            return ("Input too long", "Please try something shorter.")
        case .missingCredentials:
            return ("Missing email/password", "Please make sure to enter an email and password.")
        case .receiverDeletedProxy:
            return ("Receiver deleted", "You cannot message them anymore.")
        case .receiverMissing:
            return ("Missing recipient", "Please select a recipient and try again.")
        case .senderMissing:
            return ("Missing sender", "Please select one of your Proxies to send from.")
        case .tooManyProxies:
            return ("Too many Proxies", "You have too many Proxies. Please delete some and try again.")
        case .unknown:
            return ("😢", "Unknown error occurred.")
        }
    }

    init(_ error: ProxyError) {
        self = error
    }
}
