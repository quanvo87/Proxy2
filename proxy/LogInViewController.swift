//
//  LogInViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FacebookLogin

class LogInViewController: UIViewController {
    
    let ref = FIRDatabase.database().reference()
    var bottomConstraintConstant: CGFloat = 0.0
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        setUpTextField()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LogInViewController.keyboardWillShow), name:UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LogInViewController.keyboardWillHide), name:UIKeyboardWillHideNotification, object: self.view.window)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func setUpUI() {
        bottomConstraint.constant = view.frame.size.height / 3
        bottomConstraintConstant = bottomConstraint.constant
    }
    
    @IBAction func tapLogInButton(sender: AnyObject) {
        guard
            let email = emailTextField.text?.lowercaseString,
            let password = passwordTextField.text
            where email != "" && password != "" else {
                showAlert("Missing Fields", message: "Please enter an email and password.")
                return
        }
        FIRAuth.auth()?.signInWithEmail(email, password: password) { user, error in
            if let error = error {
                self.showAlert("Error Logging In", message: error.localizedDescription)
                return
            }
            self.showHomeScreen()
        }
    }
    
    @IBAction func tapCreateNewAccountButton(sender: AnyObject) {
        guard
            let email = emailTextField.text?.lowercaseString,
            let password = passwordTextField.text
            where email != "" && password != "" else {
                showAlert("Invalid Email/Password", message: "Please enter a valid email and password.")
                return
        }
        FIRAuth.auth()?.createUserWithEmail(email, password: password) { user, error in
            if let error = error {
                self.showAlert("Error Creating Account", message: error.localizedDescription)
                return
            }
            let changeRequest = user!.profileChangeRequest()
            changeRequest.displayName = user!.email!
            changeRequest.commitChangesWithCompletion() { error in
                if let error = error {
                    self.showAlert("Error Setting Display Name For User", message: error.localizedDescription)
                    return
                }
                let id = user!.uid
                self.ref.child("users").child(id).setValue(["username": user!.displayName!])
                self.setIcons(id)
                self.showHomeScreen()
            }
        }
    }
    
    @IBAction func tapFacebookButton(sender: AnyObject) {
        let loginManager = LoginManager()
        loginManager.logIn([ .PublicProfile ], viewController: self) { loginResult in
            switch loginResult {
            case .Failed:
                self.showAlert("Error Logging In With Facebook", message: "Please check your Facebook credentials or try again another time.")
            case .Cancelled:
                break
            case .Success:
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                FIRAuth.auth()?.signInWithCredential(credential) { user, error in
                    if let error = error {
                        self.showAlert("Error Logging In With Facebook", message: error.localizedDescription)
                        return
                    }
                    let id = user?.uid
                    self.ref.child("users").queryEqualToValue(id).observeSingleEventOfType(.Value, withBlock: { snapshot in
                        if !snapshot.hasChildren() {
                            self.ref.child("users").child(id!).setValue(["username": user!.displayName!])
                            self.setIcons(id!)
                        }
                    })
                    self.showHomeScreen()
                }
            }
        }
    }
    
    // Give user access to the default icons
    func setIcons(id: String) {
        let icons = [
            "/users/\(id)/icons/Aquarium-40": true,
            "/users/\(id)/icons/Astronaut Helmet-40": true,
            "/users/\(id)/icons/Babys Room-40": true,
            "/users/\(id)/icons/Badminton-40": true,
            "/users/\(id)/icons/Banana Split-40": true,
            "/users/\(id)/icons/Banana-40": true,
            "/users/\(id)/icons/Beer-40": true,
            "/users/\(id)/icons/Bird-40": true,
            "/users/\(id)/icons/Carrot-40": true,
            "/users/\(id)/icons/Cat Profile-40": true,
            "/users/\(id)/icons/Cat-40": true,
            "/users/\(id)/icons/Cheese-40": true,
            "/users/\(id)/icons/Cherry-40": true,
            "/users/\(id)/icons/Chili Pepper-40": true,
            "/users/\(id)/icons/Cinnamon Roll-40": true,
            "/users/\(id)/icons/Coconut Cocktail-40": true,
            "/users/\(id)/icons/Coffee Pot-40": true,
            "/users/\(id)/icons/Cookies-40": true,
            "/users/\(id)/icons/Corgi-40": true,
            "/users/\(id)/icons/Crab-40": true,
            "/users/\(id)/icons/Crystal-40": true,
            "/users/\(id)/icons/Dog-40": true,
            "/users/\(id)/icons/Dolphin-40": true,
            "/users/\(id)/icons/Doughnut-40": true,
            "/users/\(id)/icons/Duck-40": true,
            "/users/\(id)/icons/Eggplant-40": true,
            "/users/\(id)/icons/Einstein-40": true,
            "/users/\(id)/icons/Elephant-40": true,
            "/users/\(id)/icons/Flying Stork With Bundle-40": true,
            "/users/\(id)/icons/Gold Pot-40": true,
            "/users/\(id)/icons/Gorilla-40": true,
            "/users/\(id)/icons/Grapes-40": true,
            "/users/\(id)/icons/Grill-40": true,
            "/users/\(id)/icons/Hamburger-40": true,
            "/users/\(id)/icons/Hazelnut-40": true,
            "/users/\(id)/icons/Heart Balloon-40": true,
            "/users/\(id)/icons/Hornet Hive-40": true,
            "/users/\(id)/icons/Horse-40": true,
            "/users/\(id)/icons/Ice Cream Cone-40": true,
            "/users/\(id)/icons/Kangaroo-40": true,
            "/users/\(id)/icons/Kiwi-40": true,
            "/users/\(id)/icons/Pancake-40": true,
            "/users/\(id)/icons/Panda-40": true,
            "/users/\(id)/icons/Pig With Lipstick-40": true,
            "/users/\(id)/icons/Pineapple-40": true,
            "/users/\(id)/icons/Pizza-40": true,
            "/users/\(id)/icons/Pokeball-40": true,
            "/users/\(id)/icons/Pokemon-40": true,
            "/users/\(id)/icons/Prawn-40": true,
            "/users/\(id)/icons/Puffin Bird-40": true,
            "/users/\(id)/icons/Rainbow-40": true,
            "/users/\(id)/icons/Rhinoceros-40": true,
            "/users/\(id)/icons/Rice Bowl-40": true,
            "/users/\(id)/icons/Running Rabbit-40": true,
            "/users/\(id)/icons/Seahorse-40": true,
            "/users/\(id)/icons/Shark-40": true,
            "/users/\(id)/icons/Starfish-40": true,
            "/users/\(id)/icons/Strawberry-40": true,
            "/users/\(id)/icons/Super Mario-40": true,
            "/users/\(id)/icons/Taco-40": true,
            "/users/\(id)/icons/Targaryen House-40": true,
            "/users/\(id)/icons/Thanksgiving-40": true,
            "/users/\(id)/icons/Tomato-40": true,
            "/users/\(id)/icons/Turtle-40": true,
            "/users/\(id)/icons/Unicorn-40": true,
            "/users/\(id)/icons/US Airborne-40": true,
            "/users/\(id)/icons/Watermelon-40": true]
        self.ref.updateChildValues(icons)
    }
    
    // MARK: - Text field
    
    func setUpTextField() {
        emailTextField.clearButtonMode = .WhileEditing
        passwordTextField.clearButtonMode = .WhileEditing
        passwordTextField.secureTextEntry = true
    }
    
    // MARK: - Keyboard
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height
        })
    }
    
    func keyboardWillHide(sender: NSNotification) {
        bottomConstraint.constant = bottomConstraintConstant
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // MARK: - Navigation
    
    func showHomeScreen() {
        let tabBarController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.Identifiers.TabBarController) as! UITabBarController
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = tabBarController
    }
}