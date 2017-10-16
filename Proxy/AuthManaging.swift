import UIKit

protocol AuthManaging: class {
    func logIn()
}

extension AuthManaging {
    func logOut() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard
            let delegate = UIApplication.shared.delegate as? AppDelegate,
            let loginController = storyboard.instantiateViewController(withIdentifier: Identifier.loginViewController) as? LoginViewController else {
                return
        }
        delegate.window?.rootViewController = loginController
    }
}
