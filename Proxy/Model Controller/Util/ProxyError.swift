enum ProxyError: Error {
    case blankCredentials
    case facebookLoginFail
    case inputTooLong
    case proxyLimitReached
    case receiverDeletedProxy
    case unknown

    var localizedDescription: String {
        switch self {
        case .blankCredentials:
            return "Please enter a valid email and password."
        case .facebookLoginFail:
            return "Please check your Facebook username and password."
        case .inputTooLong:
            return "Input too long. Please try something shorter."
        case .proxyLimitReached:
            return "The maximum allowed proxies is \(Setting.maxProxyCount). Try deleting some and try again!"
        case .receiverDeletedProxy:
            return "The receiver for this conversation has deleted their Proxy."
        case .unknown:
            return "An unknown error occurred. Please try again."
        }
    }

    init(_ error: ProxyError) {
        self = error
    }
}

extension Error {
    var description: String {
        if let proxyError = self as? ProxyError {
            return proxyError.localizedDescription
        }
        return self.localizedDescription
    }
}
