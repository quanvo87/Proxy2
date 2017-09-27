import UIKit

protocol AuthManaging: class {
    func logIn()
}

extension AuthManaging {
    func logOut() {
        guard
            let delegate = UIApplication.shared.delegate as? AppDelegate,
            let selfController = self as? UIViewController,
            let loginController = selfController.storyboard?.instantiateViewController(withIdentifier: Identifier.loginViewController) as? LoginViewController else {
                return
        }
        delegate.window?.rootViewController = loginController
    }
}
