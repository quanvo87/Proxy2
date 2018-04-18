import FacebookLogin
import FirebaseAuth
import WQNetworkActivityIndicator

protocol LoginManaging {
    typealias Callback = (Error?) -> Void
    func emailLogIn(email: String, password: String, completion: @escaping Callback)
    func emailSignUp(email: String, password: String, completion: @escaping Callback)
    func facebookLogIn(completion: @escaping Callback)
    func sendPasswordReset(_ email: String, completion: @escaping Callback)
    func logOut()
}

class LoginManager: LoginManaging {
    private lazy var facebookLoginManager = FacebookLogin.LoginManager()
    private weak var facebookButton: Button?
    private weak var logInButton: Button?
    private weak var signUpButton: Button?

    init(facebookButton: Button? = nil,
         logInButton: Button? = nil,
         signUpButton: Button? = nil) {
        self.facebookButton = facebookButton
        self.logInButton = logInButton
        self.signUpButton = signUpButton
    }

    func emailLogIn(email: String, password: String, completion: @escaping Callback) {
        logInButton?.showActivityIndicator()
        WQNetworkActivityIndicator.shared.show()
        Shared.auth.signIn(withEmail: email, password: password) { [weak self] _, error in
            self?.logInButton?.hideActivityIndicator()
            WQNetworkActivityIndicator.shared.hide()
            if let error = error {
                StatusBar.showErrorBanner(subtitle: error.localizedDescription)
            } else {
                Haptic.playSuccess()
                Sound.soundsPlayer.playSuccess()
                StatusBar.showSuccessStatusBarBanner("Log in successful. Welcome! 🎉")
            }
        }
    }

    func emailSignUp(email: String, password: String, completion: @escaping Callback) {
        signUpButton?.showActivityIndicator()
        WQNetworkActivityIndicator.shared.show()
        Shared.auth.createUser(withEmail: email, password: password) { [weak self] _, error in
            self?.signUpButton?.hideActivityIndicator()
            WQNetworkActivityIndicator.shared.hide()
            if let error = error {
                StatusBar.showErrorBanner(subtitle: error.localizedDescription)
            } else {
                Haptic.playSuccess()
                Sound.soundsPlayer.playSuccess()
                StatusBar.showSuccessStatusBarBanner("Sign up successful. Welcome! 🎉")
            }
        }
    }

    func facebookLogIn(completion: @escaping Callback) {
        facebookButton?.showActivityIndicator()
        WQNetworkActivityIndicator.shared.show()
        facebookLoginManager.logIn(readPermissions: [.publicProfile]) { [weak self] result in
            self?.firebaseFacebookLogIn(facebookLoginResult: result) { firebaseFacebookLoginResult in
                WQNetworkActivityIndicator.shared.hide()
                switch firebaseFacebookLoginResult {
                case .success:
                    Haptic.playSuccess()
                    Sound.soundsPlayer.playSuccess()
                    StatusBar.showSuccessStatusBarBanner("Log in successful. Welcome! 🎉")
                case .failure(let error):
                    StatusBar.showErrorBanner(subtitle: error.localizedDescription)
                    self?.facebookButton?.hideActivityIndicator()
                case .cancelled:
                    self?.facebookButton?.hideActivityIndicator()
                }
            }
        }
    }

    private func firebaseFacebookLogIn(facebookLoginResult: LoginResult,
                                       completion: @escaping (FirebaseFacebookLoginResult) -> Void) {
        switch facebookLoginResult {
        case .success(_, _, let token):
            let credential = FacebookAuthProvider.credential(withAccessToken: token.authenticationToken)
            Shared.auth.signIn(with: credential) { _, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success)
                }
            }
        case .failed(let error):
            completion(.failure(error))
        case .cancelled:
            completion(.cancelled)
        }
    }

    func sendPasswordReset(_ email: String, completion: @escaping Callback) {
        WQNetworkActivityIndicator.shared.show()
        Shared.auth.sendPasswordReset(withEmail: email) { (error) in
            WQNetworkActivityIndicator.shared.hide()
            if let error = error {
                StatusBar.showErrorBanner(subtitle: error.localizedDescription)
            } else {
                Haptic.playSuccess()
                Sound.soundsPlayer.playSuccess()
                StatusBar.showSuccessBanner(
                    title: "Password reset email sent!",
                    subtitle: "Check your email to reset your password 📧."
                )
            }
        }
    }

    func logOut() {
        do {
            try Shared.auth.signOut()
        } catch {
            StatusBar.showErrorBanner(subtitle: error.localizedDescription)
        }
    }
}

private extension LoginManager {
    enum FirebaseFacebookLoginResult {
        case success
        case failure(Error)
        case cancelled
    }
}
