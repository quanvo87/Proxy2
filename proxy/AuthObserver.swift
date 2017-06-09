//
//  AuthManager.swift
//  proxy
//
//  Created by Quan Vo on 6/8/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseAuth

class AuthObserver {
    private var handle: AuthStateDidChangeListenerHandle?

    init() {}

    func observe(_ delegate: AuthObserverDelegate) {
        handle = Auth.auth().addStateDidChangeListener { [weak delegate = delegate] (_, user) in
            if let user = user {
                UserManager.shared.uid = user.uid
                API.sharedInstance.uid = user.uid   // TODO: - remove
                delegate?.logIn()
                return
            }
            UserManager.shared.uid = ""
            delegate?.logOut()
        }
    }

    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

protocol AuthObserverDelegate: class {
    func logIn()
    func logOut()
}
