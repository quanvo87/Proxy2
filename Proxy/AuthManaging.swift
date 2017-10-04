import UIKit

protocol AuthManaging: class {
    var storyboard: UIStoryboard? { get }
    func logIn()
}

extension AuthManaging {
    func logOut() {
        guard
            let delegate = UIApplication.shared.delegate as? AppDelegate,
            let loginController = storyboard?.instantiateViewController(withIdentifier: Identifier.loginViewController) as? LoginViewController else {
                return
        }
        delegate.window?.rootViewController = loginController
    }
}
