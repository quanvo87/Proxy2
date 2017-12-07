import FirebaseAuth

protocol AuthManaging: class {
    func logIn(_ user: User)
    func logOut()
}
