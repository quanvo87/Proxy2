enum ProxyError: Error {
    case blankCredentials
    case facebookLoginFail
    case proxyLimitReached
    case unknown

    var localizedDescription: String {
        switch self {
        case .blankCredentials: return "Please enter a valid email and password."
        case .facebookLoginFail: return "Please check your Facebook username and password."
        case .proxyLimitReached: return "The maximum amount of proxies is \(Settings.MaxAllowedProxies). Try deleting some and try again!"
        case .unknown: return "An unknown error occurred. Please try again."
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
