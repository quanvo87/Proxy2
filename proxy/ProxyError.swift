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
    case failedToCreateProxy

    var localizedDescription: String {
        switch self {
        case .blankCredentials: return "Please enter a valid email and password."
        case .facebookLoginFail: return "Please check your Facebook username and password."
        default: return ""
        }
    }

    init(_ error: ProxyError) {
        self = error
    }
}
