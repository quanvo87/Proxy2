//
//  ProxyError.swift
//  proxy
//
//  Created by Quan Vo on 6/7/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

enum ProxyError: Error {
    case blankCredentials
    case facebookLoginFail
    case proxyLimitReached
    case proxyNotFound
    case unknown

    var localizedDescription: String {
        switch self {
        case .blankCredentials: return "Please enter a valid email and password."
        case .facebookLoginFail: return "Please check your Facebook username and password."
        case .proxyLimitReached: return "The maximum amount of proxies is 50. Try deleting some and try again!"
        case .proxyNotFound: return "Could not find that proxy. The user may have deleted it."
        case .unknown: return "An unknown error occurred. Please try again."
        }
    }

    init(_ error: ProxyError) {
        self = error
    }
}
