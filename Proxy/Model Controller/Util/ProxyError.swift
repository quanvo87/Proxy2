enum ProxyError: Error {
    case blankCredentials
    case facebookLoginFail
    case inputTooLong
    case receiverDeletedProxy
    case tooManyProxies
    case unknown

    var alertFields: (title: String, description: String) {
        switch self {
        case .blankCredentials:
            return ("Invalid email/password", "Please enter a valid email and password.")
        case .facebookLoginFail:
            return ("Facebook login failed", "Please try again.")
        case .inputTooLong:
            return ("Input too long", "Please try something shorter.")
        case .receiverDeletedProxy:
            return ("Receiver no longer exists", "You can no longer message this Proxy.")
        case .tooManyProxies:
            return ("Too many Proxies", "You have too many Proxies. Please delete some and try again.")
        case .unknown:
            return ("😢", "An unknown error occurred.")
        }
    }

    init(_ error: ProxyError) {
        self = error
    }
}
