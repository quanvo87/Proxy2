import UIKit

protocol AuthManaging: class {
    func logIn()
}

extension AuthManaging {
    func logOut() {}
}
