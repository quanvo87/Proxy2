//
//  LogInManager.swift
//  proxy
//
//  Created by Quan Vo on 6/5/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FacebookLogin

// TODO: - icons
struct LogInManager {}

extension LogInManager {
    static func emailLogIn(email: String?, password: String?, completion: @escaping (Error?) -> Void) {
        guard
            let email = email, email != "",
            let password = password, password != "" else {
                completion(ProxyError("Please enter a valid email and password."))
                return
        }
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            changeDisplayName(user: user, email: email, completion: {
                completion(error)
            })
        }
    }

    static func emailSignUp(email: String?, password: String?, completion: @escaping (Error?) -> Void) {
        guard
            let email = email, email != "",
            let password = password, password != "" else {
                completion(ProxyError("Please enter a valid email and password."))
                return
        }
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            changeDisplayName(user: user, email: email, completion: {
                completion(error)
            })
        }
    }

    private static func changeDisplayName(user: User?, email: String, completion: () -> Void) {
        if let user = user, user.displayName != email {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = email
            changeRequest.commitChanges()
            completion()
            return
        }
        completion()
    }
}

extension LogInManager {
    static func facebookLogIn(viewController: UIViewController, completion: @escaping (Error?) -> Void) {
        let loginManager = LoginManager()
        loginManager.logIn([.publicProfile], viewController: viewController) { (loginResult) in
            switch loginResult {
            case .success:
                let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                Auth.auth().signIn(with: credential) { (_, error) in
                    completion(error)
                }
            default:
                completion(ProxyError("Username/password may be incorrect. Please try again."))
            }
        }
    }
}
