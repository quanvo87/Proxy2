//
//  AuthManager.swift
//  proxy
//
//  Created by Quan Vo on 6/8/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseAuth

class AuthManager {
    private weak var delegate: AuthManagerDelegate?
    private var handle: AuthStateDidChangeListenerHandle?

    init(_ delegate: AuthManagerDelegate) {
        self.delegate = delegate
        observe()
    }

    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func observe() {
        handle = Auth.auth().addStateDidChangeListener { (_, user) in
            if let user = user {
                UserManager.shared.uid = user.uid
                API.sharedInstance.uid = user.uid   // TODO: - remove
                self.delegate?.logIn()
                return
            }
            self.delegate?.logOut()
        }
    }
}

protocol AuthManagerDelegate: class {
    func logIn()
    func logOut()
}
