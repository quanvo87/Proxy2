import FirebaseAuth
import UIKit

protocol AuthManaging: class {
    func logIn(_ user: User)
    func logOut()
}
